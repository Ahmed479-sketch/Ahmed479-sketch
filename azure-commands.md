# Azure Cloud Shell Commands Reference

## 🚀 Quick Deployment Commands

### 1. Initial Setup
```bash
# Navigate to your project directory
cd daily-diary-app

# Make deployment script executable
chmod +x cloudshell-deploy.sh

# Run the automated deployment
./cloudshell-deploy.sh
```

### 2. Manual Step-by-Step Commands

#### Create Azure Resources
```bash
# Set variables
RESOURCE_GROUP="diary-app-rg"
CLUSTER_NAME="diary-app-cluster"
LOCATION="eastus"
DOCKER_USERNAME="your-dockerhub-username"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create AKS cluster
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --node-count 2 \
  --node-vm-size Standard_B2s \
  --enable-addons monitoring \
  --generate-ssh-keys

# Get credentials
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
```

#### Build and Push Docker Image
```bash
# Build image
docker build -t $DOCKER_USERNAME/daily-diary-app:latest .

# Login to Docker Hub
docker login

# Push image
docker push $DOCKER_USERNAME/daily-diary-app:latest
```

#### Deploy to Kubernetes
```bash
# Update deployment file
sed -i "s|your-dockerhub-username|$DOCKER_USERNAME|g" k8s/app-deployment.yaml

# Deploy MongoDB
kubectl apply -f k8s/mongodb-deployment.yaml

# Deploy application
kubectl apply -f k8s/app-deployment.yaml

# Get external IP
kubectl get service diary-app-service --watch
```

### 3. Monitoring Commands
```bash
# Check all resources
kubectl get all

# Check pod status
kubectl get pods -o wide

# View application logs
kubectl logs -l app=diary-app --tail=50

# View MongoDB logs
kubectl logs -l app=mongodb --tail=50

# Describe service for troubleshooting
kubectl describe service diary-app-service
```

### 4. Scaling Commands
```bash
# Scale application
kubectl scale deployment diary-app-deployment --replicas=3

# Check horizontal pod autoscaler (if configured)
kubectl get hpa
```

### 5. Cleanup Commands
```bash
# Delete Kubernetes resources
kubectl delete -f k8s/

# Delete entire resource group (includes AKS cluster)
az group delete --name $RESOURCE_GROUP --yes --no-wait

# Or delete just the AKS cluster
az aks delete --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --yes --no-wait
```

## 🔧 Troubleshooting Commands

### Check Cluster Status
```bash
# Get cluster info
kubectl cluster-info

# Get node status
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system
```

### Debug Application Issues
```bash
# Get detailed pod information
kubectl describe pod <pod-name>

# Execute commands in pod
kubectl exec -it <pod-name> -- /bin/sh

# Port forward for local testing
kubectl port-forward service/diary-app-service 8080:80
```

### Check Azure Resources
```bash
# List all resource groups
az group list --output table

# List AKS clusters
az aks list --output table

# Get AKS cluster details
az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
```

## 📊 Cost Management
```bash
# Check current costs
az consumption usage list --output table

# Set up budget alerts (optional)
az consumption budget create \
  --resource-group $RESOURCE_GROUP \
  --budget-name "diary-app-budget" \
  --amount 50 \
  --time-grain Monthly
```

## 🔐 Security Commands
```bash
# Enable RBAC (if not enabled during creation)
az aks update --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --enable-rbac

# Get cluster credentials with admin access
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --admin

# Check cluster security configuration
az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query "securityProfile"
```