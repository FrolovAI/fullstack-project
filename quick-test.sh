#!/bin/bash
echo "🚀 QUICK SYSTEM TEST"
echo "==================="

# 1. Проверка контейнеров
echo "1. Containers:"
docker-compose ps --format "table {{.Name}}\t{{.Status}}"

# 2. Проверка Python
echo -e "\n2. Python Service:"
if curl -s -f http://localhost:8000/health > /dev/null; then
    echo "   ✅ Healthy"
    curl -s http://localhost:8000/health | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(f'   Status: {data.get(\"status\", \"N/A\")}')
    print(f'   DB: {data.get(\"database\", \"N/A\")}')
except:
    pass
" 2>/dev/null
else
    echo "   ❌ Not responding"
fi

# 3. Проверка Java
echo -e "\n3. Java Service:"
if curl -s -f http://localhost:8080/ > /dev/null; then
    echo "   ✅ Running"
    curl -s http://localhost:8080/ | head -1
else
    echo "   ❌ Not responding"
fi

# 4. Проверка Frontend
echo -e "\n4. Frontend:"
if curl -s -f http://localhost/ > /dev/null; then
    echo "   ✅ Accessible"
    echo "   👉 Open: http://localhost"
else
    echo "   ❌ Not accessible"
fi

# 5. Проверка MySQL
echo -e "\n5. MySQL:"
if docker-compose exec mysql mysql -u root -prootpassword -e "SELECT 1" > /dev/null 2>&1; then
    echo "   ✅ Running"
    echo "   Port: 3306 (root/rootpassword)"
else
    echo "   ❌ Not accessible"
fi

echo -e "\n✅ Test completed!"
