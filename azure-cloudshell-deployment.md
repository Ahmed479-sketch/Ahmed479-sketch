# Azure Cloud Shell Deployment Guide

## 🌐 Deploy Daily Diary App to Azure AKS using Cloud Shell

This guide walks you through deploying the Daily Diary application to Azure Kubernetes Service (AKS) using Azure Cloud Shell.

## 📋 Prerequisites

1. Azure subscription with sufficient credits
2. Docker Hub account
3. Access to Azure Cloud Shell (https://shell.azure.com)

## 🚀 Step-by-Step Deployment

### Step 1: Access Azure Cloud Shell

1. Go to https://portal.azure.com
2. Click on the Cloud Shell icon (>_) in the top navigation
3. Choose **Bash** when prompted
4. Wait for Cloud Shell to initialize

### Step 2: Clone and Prepare the Application

```bash
# Clone your repository (replace with your GitHub repo URL)
git clone https://github.com/YOUR_USERNAME/daily-diary-app.git
cd daily-diary-app

# Or upload files directly to Cloud Shell
# You can drag and drop files into Cloud Shell interface
```

### Step 3: Build and Push Docker Image

```bash
# Login to Docker Hub
docker login

# Build the Docker image
docker build -t YOUR_DOCKERHUB_USERNAME/daily-diary-app:latest .

# Push to Docker Hub
docker push YOUR_DOCKERHUB_USERNAME/daily-diary-app:latest
```

### Step 4: Create Azure Resources

```bash
# Set variables (replace with your values)
RESOURCE_GROUP="diary-app-rg"
CLUSTER_NAME="diary-app-cluster"
LOCATION="eastus"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create AKS cluster (this takes 5-10 minutes)
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --node-count 2 \
  --node-vm-size Standard_B2s \
  --enable-addons monitoring \
  --generate-ssh-keys \
  --network-plugin azure

# Get AKS credentials
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
```

### Step 5: Update Kubernetes Manifests

```bash
# Update the Docker image name in the deployment file
sed -i "s|your-dockerhub-username/daily-diary-app:latest|YOUR_DOCKERHUB_USERNAME/daily-diary-app:latest|g" k8s/app-deployment.yaml

# Verify the change
cat k8s/app-deployment.yaml | grep image:
```

### Step 6: Deploy to Kubernetes

```bash
# Deploy MongoDB first
kubectl apply -f k8s/mongodb-deployment.yaml

# Wait for MongoDB to be ready
kubectl wait --for=condition=available --timeout=300s deployment/mongodb-deployment

# Deploy the application
kubectl apply -f k8s/app-deployment.yaml

# Check deployment status
kubectl get deployments
kubectl get pods
kubectl get services
```

### Step 7: Get External IP and Access Application

```bash
# Get the external IP (may take a few minutes)
kubectl get service diary-app-service --watch

# Once EXTERNAL-IP is assigned, you can access your app
# Press Ctrl+C to stop watching

# Get the final external IP
EXTERNAL_IP=$(kubectl get service diary-app-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Your application is available at: http://$EXTERNAL_IP"
```

## 🔍 Monitoring and Troubleshooting

### Check Application Status
```bash
# View all resources
kubectl get all

# Check pod logs
kubectl logs -l app=diary-app

# Check MongoDB logs
kubectl logs -l app=mongodb

# Describe services for troubleshooting
kubectl describe service diary-app-service
```

### Scale the Application
```bash
# Scale up the application
kubectl scale deployment diary-app-deployment --replicas=3

# Check scaling status
kubectl get pods -l app=diary-app
```

## 🧹 Cleanup Resources

```bash
# Delete Kubernetes resources
kubectl delete -f k8s/

# Delete AKS cluster and resource group
az group delete --name $RESOURCE_GROUP --yes --no-wait
```

## 📊 Cost Optimization Tips

1. Use **Standard_B2s** VM size for development (included above)
2. Set node count to 2 for basic testing
3. Delete resources when not in use
4. Monitor costs in Azure Cost Management

## 🔐 Security Best Practices

1. Use Azure Key Vault for secrets in production
2. Enable RBAC on AKS cluster
3. Use private container registry for production
4. Implement network policies

## 📝 Expected Outputs

After successful deployment, you should see:
- AKS cluster running with 2 nodes
- MongoDB and App pods in Running state
- LoadBalancer service with external IP
- Application accessible via browser

## 🎯 Submission Requirements

Document these for your assignment:
- **GitHub Repository**: Your repo URL
- **Docker Hub Image**: `https://hub.docker.com/r/YOUR_USERNAME/daily-diary-app`
- **Azure App URL**: `http://YOUR_EXTERNAL_IP`
- Screenshots of each deployment step