#!/bin/bash

# Azure Cloud Shell Commands for AKS Deployment
# Run these commands one by one in Azure Cloud Shell

# Set variables
RESOURCE_GROUP="diary-app-rg"
CLUSTER_NAME="diary-app-cluster"
LOCATION="eastus"

# Create AKS cluster (this will work in Cloud Shell)
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --node-count 2 \
  --node-vm-size Standard_B2s \
  --generate-ssh-keys

# Get credentials
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME

# Create MongoDB deployment file
cat > mongodb-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb-deployment
  labels:
    app: mongodb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
      - name: mongodb
        image: mongo:5.0
        ports:
        - containerPort: 27017
        env:
        - name: MONGO_INITDB_ROOT_USERNAME
          value: "admin"
        - name: MONGO_INITDB_ROOT_PASSWORD
          value: "password123"
        - name: MONGO_INITDB_DATABASE
          value: "dailydiary"
        volumeMounts:
        - name: mongodb-storage
          mountPath: /data/db
      volumes:
      - name: mongodb-storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: mongodb-service
spec:
  selector:
    app: mongodb
  ports:
  - protocol: TCP
    port: 27017
    targetPort: 27017
  type: ClusterIP
EOF

# Create app deployment file
cat > app-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: diary-app-deployment
  labels:
    app: diary-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: diary-app
  template:
    metadata:
      labels:
        app: diary-app
    spec:
      containers:
      - name: diary-app
        image: ahmed22976/daily-diary-app:latest
        ports:
        - containerPort: 3000
        env:
        - name: PORT
          value: "3000"
        - name: MONGODB_URI
          value: "mongodb://admin:password123@mongodb-service:27017/dailydiary?authSource=admin"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: diary-app-service
spec:
  selector:
    app: diary-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
  type: LoadBalancer
EOF

# Deploy MongoDB
kubectl apply -f mongodb-deployment.yaml

# Wait for MongoDB to be ready
kubectl wait --for=condition=available --timeout=300s deployment/mongodb-deployment

# Deploy the app
kubectl apply -f app-deployment.yaml

# Check status
kubectl get pods
kubectl get services

# Get external IP
echo "Waiting for external IP..."
kubectl get service diary-app-service --watch