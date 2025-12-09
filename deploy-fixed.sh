#!/bin/bash

set -e  # Останавливаться при ошибках

echo "🔧 Deploying application to Kubernetes..."

# Проверяем Dockerfile
if [ ! -f "Dockerfile" ]; then
    echo "⚠️ Dockerfile not found. Creating default..."
    cat > Dockerfile << 'DOCKERFILE'
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["node", "index.js"]
DOCKERFILE
fi

# Проверяем index.js
if [ ! -f "index.js" ]; then
    echo "⚠️ index.js not found. Creating default..."
    cat > index.js << 'JS'
const http = require('http');
const port = process.env.PORT || 3000;
const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ 
    message: 'Hello from Kubernetes!',
    timestamp: new Date().toISOString()
  }));
});
server.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
JS
fi

# Проверяем package.json
if [ ! -f "package.json" ]; then
    echo "⚠️ package.json not found. Creating default..."
    echo '{"name":"app","version":"1.0.0","dependencies":{"express":"^4.18.2"}}' > package.json
    npm install --package-lock-only
fi

# Проверка кластера
if ! kubectl cluster-info > /dev/null 2>&1; then
    echo "❌ Kubernetes cluster not found. Setting up Kind..."
    
    # Установка Kind
    if ! command -v kind &> /dev/null; then
        echo "Installing Kind..."
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    fi
    
    # Создание кластера
    kind create cluster --name app-cluster
    sleep 5  # Даем кластеру время для инициализации
fi

echo "✅ Cluster is ready"
kubectl get nodes

# Ждем пока нода будет Ready
echo "Waiting for node to be ready..."
kubectl wait --for=condition=Ready node --all --timeout=60s

# Сборка Docker образа
echo "Building Docker image..."
docker build -t fullstack-app:latest .

# Загрузка образа в Kind
echo "Loading image to Kind cluster..."
kind load docker-image fullstack-app:latest --name app-cluster

# Удаляем старый деплоймент если есть
kubectl delete deployment fullstack-app 2>/dev/null || true
kubectl delete service fullstack-app-service 2>/dev/null || true

# Создаем deployment
echo "Creating deployment..."
cat > deployment.yaml << 'DEPLOYMENT'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fullstack-app
  labels:
    app: fullstack-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: fullstack-app
  template:
    metadata:
      labels:
        app: fullstack-app
    spec:
      containers:
      - name: app
        image: fullstack-app:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        - name: PORT
          value: "3000"
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
        startupProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
          failureThreshold: 30
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
DEPLOYMENT

# Создаем service
cat > service.yaml << 'SERVICE'
apiVersion: v1
kind: Service
metadata:
  name: fullstack-app-service
spec:
  selector:
    app: fullstack-app
  ports:
  - port: 80
    targetPort: 3000
    protocol: TCP
  type: ClusterIP
SERVICE

# Применяем манифесты
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Проверяем
echo "Checking deployment..."
kubectl get deployments
kubectl get pods
kubectl get services

# Ждем когда поды будут готовы
echo "Waiting for pods to be ready..."
sleep 10  # Даем время для запуска

# Проверяем статус подов
MAX_RETRIES=30
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    READY_COUNT=$(kubectl get deployment fullstack-app -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    if [ "$READY_COUNT" = "2" ]; then
        echo "✅ All pods are ready!"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "Waiting for pods... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 2
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "⚠️ Pods taking too long to start. Checking status..."
    kubectl describe deployment fullstack-app
    kubectl get pods
    kubectl logs -l app=fullstack-app --tail=10
fi

echo ""
echo "🚀 Application deployed successfully!"
echo ""
echo "📡 Available commands:"
echo "   kubectl port-forward svc/fullstack-app-service 8080:80"
echo "   kubectl get pods"
echo "   kubectl logs -l app=fullstack-app"
echo ""
echo "🌐 To access the application:"
echo "   1. Run: kubectl port-forward svc/fullstack-app-service 8080:80"
echo "   2. Open: http://localhost:8080"
echo "   3. Or check health: http://localhost:8080/health"

# Автоматический port-forward в фоне
echo ""
read -p "Start port-forward now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Starting port-forward..."
    kubectl port-forward svc/fullstack-app-service 8080:80 &
    PF_PID=$!
    echo "Port-forward running with PID: $PF_PID"
    echo "To stop: kill $PF_PID"
    sleep 2
    echo "Testing connection..."
    curl -s http://localhost:8080/health | python3 -m json.tool || echo "Service not ready yet"
fi
