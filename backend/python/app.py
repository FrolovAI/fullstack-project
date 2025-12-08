from fastapi import FastAPI, HTTPException
import mysql.connector
from mysql.connector import Error
import os
import time
import logging

# Настройка логирования
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Python Users Service", version="1.0.0")

def get_db_connection():
    """Подключение к базе данных"""
    try:
        conn = mysql.connector.connect(
            host=os.getenv("DB_HOST", "mysql"),
            user=os.getenv("DB_USER", "app_user"),
            password=os.getenv("DB_PASSWORD", "secure_password"),
            database=os.getenv("DB_NAME", "users_db"),
            port=int(os.getenv("DB_PORT", "3306")),
            auth_plugin='mysql_native_password'  # Явно указываем плагин аутентификации
        )
        return conn
    except Error as e:
        logger.error(f"Database connection error: {e}")
        raise

@app.on_event("startup")
def startup_event():
    """Инициализация при запуске"""
    logger.info("Starting Python Users Service...")
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Создаем таблицу если не существует
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                email VARCHAR(100) UNIQUE NOT NULL,
                age INT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        conn.commit()
        cursor.close()
        conn.close()
        
        logger.info("Database initialized successfully")
        
    except Exception as e:
        logger.error(f"Startup error: {e}")

@app.get("/")
def read_root():
    return {
        "service": "Python Users Service", 
        "status": "running",
        "version": "1.0.0",
        "endpoints": ["/health", "/users", "/debug"]
    }

@app.get("/health")
def health_check():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Простой тестовый запрос
        cursor.execute("SELECT 1")
        result = cursor.fetchone()
        
        # Проверяем таблицу users
        cursor.execute("SHOW TABLES LIKE 'users'")
        has_users = cursor.fetchone() is not None
        
        cursor.close()
        conn.close()
        
        return {
            "status": "healthy",
            "database": "connected",
            "test_query": "success",
            "has_users_table": has_users,
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S")
        }
        
    except Exception as e:
        return {
            "status": "unhealthy",
            "database": "disconnected",
            "error": str(e),
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S")
        }

@app.get("/debug")
def debug():
    """Отладочная информация"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("SELECT DATABASE() as db, USER() as user, VERSION() as version")
        info = cursor.fetchone()
        
        cursor.execute("SHOW TABLES")
        tables = [list(row.values())[0] for row in cursor.fetchall()]
        
        cursor.close()
        conn.close()
        
        return {
            "status": "success",
            "connection": info,
            "tables": tables,
            "env": {
                "DB_HOST": os.getenv("DB_HOST", "not set"),
                "DB_USER": os.getenv("DB_USER", "not set"),
                "DB_NAME": os.getenv("DB_NAME", "not set")
            }
        }
        
    except Exception as e:
        return {
            "status": "error",
            "message": str(e)
        }

@app.get("/users")
def get_users():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("SELECT id, name, email, age, created_at FROM users ORDER BY id")
        users = cursor.fetchall()
        
        cursor.close()
        conn.close()
        
        return {
            "users": users,
            "count": len(users),
            "status": "success"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@app.post("/users")
def create_user(name: str, email: str, age: int = None):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute(
            "INSERT INTO users (name, email, age) VALUES (%s, %s, %s)",
            (name, email, age)
        )
        conn.commit()
        user_id = cursor.lastrowid
        
        cursor.close()
        conn.close()
        
        return {
            "message": "User created successfully",
            "id": user_id,
            "name": name,
            "email": email,
            "age": age
        }
        
    except mysql.connector.IntegrityError:
        raise HTTPException(status_code=400, detail="Email already exists")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
