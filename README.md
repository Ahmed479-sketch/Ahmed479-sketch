# Daily Diary CRUD Application

A complete cloud-native daily diary application demonstrating the full deployment pipeline from local development to Azure Kubernetes Service (AKS).

## 🚀 Features

- **Daily Diary CRUD Operations**: Create, Read, Update, Delete diary entries
- **Monthly View**: Filter entries by month
- **Mood Tracking**: Track daily moods with emojis
- **Responsive Design**: Works on desktop and mobile devices
- **Cloud-Ready**: Containerized and ready for Kubernetes deployment

## 🛠️ Technology Stack

- **Frontend**: HTML5, CSS3, Vanilla JavaScript
- **Backend**: Node.js, Express.js
- **Database**: MongoDB
- **Containerization**: Docker
- **Orchestration**: Kubernetes
- **Cloud Platform**: Azure AKS

## 📋 Project Structure

```
daily-diary-app/
├── public/
│   ├── index.html          # Frontend HTML
│   ├── style.css           # Styling
│   └── script.js           # Frontend JavaScript
├── k8s/
│   ├── mongodb-deployment.yaml    # MongoDB Kubernetes deployment
│   └── app-deployment.yaml        # App Kubernetes deployment
├── server.js               # Backend Express server
├── package.json           # Node.js dependencies
├── Dockerfile            # Docker container configuration
├── docker-compose.yml    # Local development setup
└── README.md            # This file
```

## 🔧 Section 1: Local Development & Dockerization

### Prerequisites
- Node.js 18+ installed
- Docker installed
- Docker Hub account

### 1. Run Locally (2 marks)

```bash
# Install dependencies
npm install

# Start MongoDB (using Docker)
docker run -d --name mongodb -p 27017:27017 mongo:5.0

# Start the application
npm start
```

Visit `http://localhost:3000` to access the application.

### 2. Create Docker Image (3 marks)

```bash
# Build Docker image
docker build -t daily-diary-app .

# Verify image was created
docker images | grep daily-diary-app
```

### 3. Run Docker Container (3 marks)

```bash
# Run with Docker Compose (includes MongoDB)
docker-compose up -d

# Or run individual containers
docker run -d --name mongodb -p 27017:27017 mongo:5.0
docker run -d --name diary-app -p 3000:3000 --link mongodb:mongodb \
  -e MONGODB_URI=mongodb://mongodb:27017/dailydiary daily-diary-app
```

### 4. Push to Docker Hub (2 marks)

```bash
# Tag the image
docker tag daily-diary-app your-dockerhub-username/daily-diary-app:latest

# Login to Docker Hub
docker login

# Push the image
docker push your-dockerhub-username/daily-diary-app:latest
```

## ☁️ Section 2: Azure Kubernetes Deployment

### 🌐 Azure Cloud Shell Deployment (Recommended)

**Quick Start:**
```bash
# In Azure Cloud Shell (https://shell.azure.com)
chmod +x cloudshell-deploy.sh
./cloudshell-deploy.sh
```

### Manual Deployment Steps

### 1. Create Azure Kubernetes Cluster (3 marks)

```bash
# In Azure Cloud Shell - no az login needed
# Create resource group
az group create --name diary-app-rg --location eastus

# Create AKS cluster (optimized for Cloud Shell)
az aks create \
  --resource-group diary-app-rg \
  --name diary-app-cluster \
  --node-count 2 \
  --node-vm-size Standard_B2s \
  --enable-addons monitoring \
  --generate-ssh-keys

# Get credentials
az aks get-credentials --resource-group diary-app-rg --name diary-app-cluster
```

### 2. Deploy to AKS (4 marks)

```bash
# Update the image name in k8s/app-deployment.yaml with your Docker Hub username

# Deploy MongoDB
kubectl apply -f k8s/mongodb-deployment.yaml

# Deploy the application
kubectl apply -f k8s/app-deployment.yaml

# Check deployment status
kubectl get deployments
kubectl get pods
kubectl get services
```

### 3. Expose Application (3 marks)

```bash
# Get external IP (may take a few minutes)
kubectl get service diary-app-service --watch

# Once EXTERNAL-IP is assigned, access your app at:
# http://<EXTERNAL-IP>
```

## 💻 Section 3: GitHub Repository

### 1. Initialize Git Repository (1 mark)

```bash
git init
```

### 2. Add Files and Commit (2 marks)

```bash
# Add all files
git add .

# Initial commit
git commit -m "Initial commit: Daily Diary CRUD application"

# Create GitHub repository and add remote
git remote add origin https://github.com/your-username/daily-diary-app.git

# Push to GitHub
git push -u origin main
```

### 3. Git Commands Usage (2 marks)

```bash
# Make changes and commit
git add .
git commit -m "Update: Added new feature"
git push origin main

# Pull latest changes
git pull origin main

# Create and switch to new branch
git checkout -b feature/new-feature

# Merge branch
git checkout main
git merge feature/new-feature
```

## 🔗 Deployment Links

- **GitHub Repository**: `https://github.com/your-username/daily-diary-app`
- **Docker Hub Image**: `https://hub.docker.com/r/your-username/daily-diary-app`
- **Azure App URL**: `http://<your-aks-external-ip>`

## 📸 Screenshots Required

1. Local application running on `localhost:3000`
2. Docker image build process
3. Docker container running
4. Docker Hub repository with pushed image
5. Azure AKS cluster creation
6. Kubernetes pods and services running
7. Application accessible via Azure public IP
8. GitHub repository with all files

## 🔍 API Endpoints

- `GET /api/entries` - Get all diary entries
- `GET /api/entries/:year/:month` - Get entries by month
- `POST /api/entries` - Create new entry
- `PUT /api/entries/:id` - Update entry
- `DELETE /api/entries/:id` - Delete entry
- `GET /health` - Health check endpoint

## 🛡️ Security Features

- Non-root user in Docker container
- Resource limits in Kubernetes
- Health checks and probes
- Input validation and sanitization

## 📝 Notes

- Replace `your-dockerhub-username` with your actual Docker Hub username
- Update MongoDB credentials in production
- Configure persistent storage for production MongoDB
- Set up proper monitoring and logging
- Implement HTTPS in production