#!/bin/bash

# Azure Cloud Shell Deployment Script for Daily Diary App
# Run this script in Azure Cloud Shell (Bash)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Main deployment function
main() {
    print_header "Daily Diary App - Azure AKS Deployment"
    
    # Check if we're in Azure Cloud Shell
    if [[ -z "$AZURE_HTTP_USER_AGENT" ]]; then
        print_warning "This script is optimized for Azure Cloud Shell"
        print_warning "Make sure you have Azure CLI and kubectl installed"
    fi
    
    # Get user inputs
    echo ""
    read -p "Enter your Docker Hub username: " DOCKER_USERNAME
    read -p "Enter your resource group name (default: diary-app-rg): " RESOURCE_GROUP
    read -p "Enter your AKS cluster name (default: diary-app-cluster): " CLUSTER_NAME
    read -p "Enter Azure region (default: eastus): " LOCATION
    
    # Set defaults
    RESOURCE_GROUP=${RESOURCE_GROUP:-diary-app-rg}
    CLUSTER_NAME=${CLUSTER_NAME:-diary-app-cluster}
    LOCATION=${LOCATION:-eastus}
    IMAGE_NAME="$DOCKER_USERNAME/daily-diary-app:latest"
    
    if [[ -z "$DOCKER_USERNAME" ]]; then
        print_error "Docker Hub username is required"
        exit 1
    fi
    
    print_status "Configuration:"
    echo "  - Docker Image: $IMAGE_NAME"
    echo "  - Resource Group: $RESOURCE_GROUP"
    echo "  - Cluster Name: $CLUSTER_NAME"
    echo "  - Location: $LOCATION"
    echo ""
    
    read -p "Continue with deployment? (y/n): " CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        print_warning "Deployment cancelled"
        exit 0
    fi
    
    # Step 1: Build and push Docker image
    print_header "Step 1: Building and Pushing Docker Image"
    
    if [[ ! -f "Dockerfile" ]]; then
        print_error "Dockerfile not found. Make sure you're in the project directory."
        exit 1
    fi
    
    print_status "Building Docker image..."
    docker build -t daily-diary-app .
    docker tag daily-diary-app $IMAGE_NAME
    
    print_status "Logging into Docker Hub..."
    docker login
    
    print_status "Pushing image to Docker Hub..."
    docker push $IMAGE_NAME
    
    print_status "✅ Docker image pushed successfully: $IMAGE_NAME"
    
    # Step 2: Create Azure resources
    print_header "Step 2: Creating Azure Resources"
    
    print_status "Creating resource group: $RESOURCE_GROUP"
    az group create --name $RESOURCE_GROUP --location $LOCATION
    
    print_status "Creating AKS cluster: $CLUSTER_NAME (this may take 5-10 minutes)"
    az aks create \
        --resource-group $RESOURCE_GROUP \
        --name $CLUSTER_NAME \
        --node-count 2 \
        --node-vm-size Standard_B2s \
        --enable-addons monitoring \
        --generate-ssh-keys \
        --network-plugin azure \
        --no-wait
    
    print_status "Waiting for AKS cluster to be ready..."
    az aks wait --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --created
    
    print_status "Getting AKS credentials..."
    az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing
    
    print_status "✅ AKS cluster created successfully"
    
    # Step 3: Update Kubernetes manifests
    print_header "Step 3: Updating Kubernetes Manifests"
    
    if [[ ! -d "k8s" ]]; then
        print_error "k8s directory not found. Make sure Kubernetes manifests exist."
        exit 1
    fi
    
    print_status "Updating Docker image name in deployment manifest..."
    sed -i "s|your-dockerhub-username/daily-diary-app:latest|$IMAGE_NAME|g" k8s/app-deployment.yaml
    
    print_status "✅ Kubernetes manifests updated"
    
    # Step 4: Deploy to Kubernetes
    print_header "Step 4: Deploying to Kubernetes"
    
    print_status "Deploying MongoDB..."
    kubectl apply -f k8s/mongodb-deployment.yaml
    
    print_status "Waiting for MongoDB to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/mongodb-deployment
    
    print_status "Deploying Daily Diary application..."
    kubectl apply -f k8s/app-deployment.yaml
    
    print_status "Waiting for application to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/diary-app-deployment
    
    print_status "✅ Application deployed successfully"
    
    # Step 5: Get external IP
    print_header "Step 5: Getting External IP"
    
    print_status "Waiting for LoadBalancer to assign external IP (this may take a few minutes)..."
    
    # Wait for external IP
    EXTERNAL_IP=""
    COUNTER=0
    MAX_ATTEMPTS=30
    
    while [[ -z "$EXTERNAL_IP" && $COUNTER -lt $MAX_ATTEMPTS ]]; do
        EXTERNAL_IP=$(kubectl get service diary-app-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        if [[ -z "$EXTERNAL_IP" ]]; then
            echo -n "."
            sleep 10
            ((COUNTER++))
        fi
    done
    
    echo ""
    
    if [[ -n "$EXTERNAL_IP" ]]; then
        print_status "✅ External IP assigned: $EXTERNAL_IP"
        print_status "🎉 Your application is available at: http://$EXTERNAL_IP"
    else
        print_warning "External IP not assigned yet. Check manually with:"
        print_warning "kubectl get service diary-app-service"
    fi
    
    # Step 6: Display summary
    print_header "Deployment Summary"
    
    echo "✅ Resource Group: $RESOURCE_GROUP"
    echo "✅ AKS Cluster: $CLUSTER_NAME"
    echo "✅ Docker Image: $IMAGE_NAME"
    if [[ -n "$EXTERNAL_IP" ]]; then
        echo "✅ Application URL: http://$EXTERNAL_IP"
    fi
    echo ""
    
    print_status "Useful commands:"
    echo "  - Check pods: kubectl get pods"
    echo "  - Check services: kubectl get services"
    echo "  - View logs: kubectl logs -l app=diary-app"
    echo "  - Scale app: kubectl scale deployment diary-app-deployment --replicas=3"
    echo ""
    
    print_status "To clean up resources later:"
    echo "  az group delete --name $RESOURCE_GROUP --yes --no-wait"
    echo ""
    
    print_status "🎉 Deployment completed successfully!"
}

# Run main function
main "$@"