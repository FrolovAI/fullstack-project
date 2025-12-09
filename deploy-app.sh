#!/bin/bash

echo "🔧 Deploying application to Kubernetes..."

# Check if kubectl is configured
if ! kubectl cluster-info > /dev/null 2>&1; then
    echo "❌ Kubernetes cluster not found. Setting up Kind..."
    
    # Install Kind if not exists
    if ! command -v kind &> /dev/null; then
        echo "Installing Kind..."
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    fi
    
    # Create cluster
    kind create cluster --name app-cluster
fi

echo "✅ Cluster is ready"
kubectl get nodes

# Build Docker image
echo "Building Docker image..."
docker build -t fullstack-app:latest .

# Load image to Kind if using Kind
if kubectl config current-context | grep -q "kind"; then
    echo "Loading image to Kind cluster..."
    kind load docker-image fullstack-app:latest --name app-cluster
fi

# Create deployment
echo "Creating deployment..."
cat > deployment.yaml << 'DEPLOYMENT'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fullstack-app
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
DEPLOYMENT

# Create service
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
  type: ClusterIP
SERVICE

# Apply manifests
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Check deployment
echo "Checking deployment..."
kubectl get deployments
kubectl get pods
kubectl get services

# Wait for pods to be ready
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=fullstack-app --timeout=60s

echo "✅ Application deployed successfully!"
echo ""
echo "To access your application:"
echo "1. kubectl port-forward svc/fullstack-app-service 8080:80"
echo "2. Open http://localhost:8080"
