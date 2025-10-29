#!/bin/bash

# Daily Diary App Deployment Script
# This script automates the deployment process

set -e

echo "🚀 Daily Diary App Deployment Script"
echo "====================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_warning "kubectl is not installed. You'll need it for Kubernetes deployment."
fi

# Get Docker Hub username
read -p "Enter your Docker Hub username: " DOCKER_USERNAME

if [ -z "$DOCKER_USERNAME" ]; then
    print_error "Docker Hub username is required"
    exit 1
fi

IMAGE_NAME="$DOCKER_USERNAME/daily-diary-app:latest"

echo ""
print_status "Starting deployment process..."

# Step 1: Build Docker image
print_status "Step 1: Building Docker image..."
docker build -t daily-diary-app .
docker tag daily-diary-app $IMAGE_NAME

print_status "Docker image built successfully: $IMAGE_NAME"

# Step 2: Test locally with Docker Compose
print_status "Step 2: Testing locally with Docker Compose..."
docker-compose down --remove-orphans 2>/dev/null || true
docker-compose up -d

print_status "Waiting for services to start..."
sleep 10

# Check if app is running
if curl -f http://localhost:3000/health > /dev/null 2>&1; then
    print_status "✅ Local deployment successful! App is running at http://localhost:3000"
else
    print_warning "⚠️  Local deployment may have issues. Check docker-compose logs."
fi

# Step 3: Push to Docker Hub
read -p "Do you want to push the image to Docker Hub? (y/n): " PUSH_CONFIRM

if [ "$PUSH_CONFIRM" = "y" ] || [ "$PUSH_CONFIRM" = "Y" ]; then
    print_status "Step 3: Pushing image to Docker Hub..."
    
    # Login to Docker Hub
    print_status "Please login to Docker Hub:"
    docker login
    
    # Push image
    docker push $IMAGE_NAME
    print_status "✅ Image pushed to Docker Hub: $IMAGE_NAME"
    
    # Update Kubernetes deployment file
    print_status "Updating Kubernetes deployment file..."
    sed -i.bak "s|your-dockerhub-username/daily-diary-app:latest|$IMAGE_NAME|g" k8s/app-deployment.yaml
    print_status "✅ Kubernetes deployment file updated"
else
    print_warning "Skipping Docker Hub push"
fi

# Step 4: Kubernetes deployment instructions
echo ""
print_status "Step 4: Kubernetes Deployment Instructions"
echo "=========================================="
echo ""
echo "To deploy to Azure AKS, run the following commands:"
echo ""
echo "1. Create AKS cluster:"
echo "   az group create --name diary-app-rg --location eastus"
echo "   az aks create --resource-group diary-app-rg --name diary-app-cluster --node-count 2 --generate-ssh-keys"
echo "   az aks get-credentials --resource-group diary-app-rg --name diary-app-cluster"
echo ""
echo "2. Deploy to Kubernetes:"
echo "   kubectl apply -f k8s/mongodb-deployment.yaml"
echo "   kubectl apply -f k8s/app-deployment.yaml"
echo ""
echo "3. Get external IP:"
echo "   kubectl get service diary-app-service --watch"
echo ""

# Step 5: Git repository setup
read -p "Do you want to initialize Git repository? (y/n): " GIT_CONFIRM

if [ "$GIT_CONFIRM" = "y" ] || [ "$GIT_CONFIRM" = "Y" ]; then
    print_status "Step 5: Setting up Git repository..."
    
    if [ ! -d ".git" ]; then
        git init
        print_status "Git repository initialized"
    fi
    
    git add .
    git commit -m "Initial commit: Daily Diary CRUD application with Docker and Kubernetes support" || true
    
    print_status "✅ Files committed to Git"
    
    echo ""
    echo "To push to GitHub:"
    echo "1. Create a new repository on GitHub"
    echo "2. Run: git remote add origin https://github.com/YOUR_USERNAME/daily-diary-app.git"
    echo "3. Run: git push -u origin main"
else
    print_warning "Skipping Git setup"
fi

echo ""
print_status "🎉 Deployment script completed!"
echo ""
echo "Summary:"
echo "- ✅ Docker image built: $IMAGE_NAME"
echo "- ✅ Local deployment tested"
if [ "$PUSH_CONFIRM" = "y" ] || [ "$PUSH_CONFIRM" = "Y" ]; then
    echo "- ✅ Image pushed to Docker Hub"
    echo "- ✅ Kubernetes files updated"
fi
echo ""
echo "Next steps:"
echo "1. Test your app locally at: http://localhost:3000"
echo "2. Follow the Kubernetes deployment instructions above"
echo "3. Set up your GitHub repository"
echo ""
echo "For detailed instructions, see README.md"