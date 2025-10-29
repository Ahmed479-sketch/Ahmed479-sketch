# 🚀 Azure Cloud Shell Quick Start

## 📋 Prerequisites
- Azure subscription
- Docker Hub account
- GitHub repository with the Daily Diary app

## ⚡ 5-Minute Deployment

### Step 1: Open Azure Cloud Shell
1. Go to https://portal.azure.com
2. Click Cloud Shell icon (>_) in top bar
3. Choose **Bash**

### Step 2: Get Your Code
```bash
# Option A: Clone from GitHub
git clone https://github.com/YOUR_USERNAME/daily-diary-app.git
cd daily-diary-app

# Option B: Upload files directly
# Drag and drop your project files into Cloud Shell
```

### Step 3: Run Automated Deployment
```bash
# Make script executable
chmod +x cloudshell-deploy.sh

# Run deployment (will prompt for Docker Hub username)
./cloudshell-deploy.sh
```

### Step 4: Access Your App
The script will output your application URL:
```
🎉 Your application is available at: http://YOUR_EXTERNAL_IP
```

## 🔧 Manual Commands (Alternative)

```bash
# Set your Docker Hub username
DOCKER_USERNAME="your-username"

# Build and push image
docker build -t $DOCKER_USERNAME/daily-diary-app:latest .
docker login
docker push $DOCKER_USERNAME/daily-diary-app:latest

# Create Azure resources
az group create --name diary-app-rg --location eastus
az aks create --resource-group diary-app-rg --name diary-app-cluster --node-count 2 --node-vm-size Standard_B2s --generate-ssh-keys
az aks get-credentials --resource-group diary-app-rg --name diary-app-cluster

# Update and deploy
sed -i "s|your-dockerhub-username|$DOCKER_USERNAME|g" k8s/app-deployment.yaml
kubectl apply -f k8s/mongodb-deployment.yaml
kubectl apply -f k8s/app-deployment.yaml

# Get external IP
kubectl get service diary-app-service --watch
```

## 📊 Expected Timeline
- AKS cluster creation: 5-10 minutes
- Application deployment: 2-3 minutes
- LoadBalancer IP assignment: 2-5 minutes
- **Total: ~15 minutes**

## 🧹 Cleanup
```bash
# Delete everything
az group delete --name diary-app-rg --yes --no-wait
```

## 📝 For Your Assignment
Document these URLs:
- **GitHub**: `https://github.com/YOUR_USERNAME/daily-diary-app`
- **Docker Hub**: `https://hub.docker.com/r/YOUR_USERNAME/daily-diary-app`
- **Azure App**: `http://YOUR_EXTERNAL_IP`

## 🔍 Troubleshooting
```bash
# Check pod status
kubectl get pods

# View logs
kubectl logs -l app=diary-app

# Check services
kubectl get services
```