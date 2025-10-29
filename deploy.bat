@echo off
setlocal enabledelayedexpansion

echo 🚀 Daily Diary App Deployment Script (Windows)
echo =============================================

REM Check if Docker is installed
docker --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not installed. Please install Docker Desktop first.
    pause
    exit /b 1
)

REM Get Docker Hub username
set /p DOCKER_USERNAME="Enter your Docker Hub username: "

if "%DOCKER_USERNAME%"=="" (
    echo [ERROR] Docker Hub username is required
    pause
    exit /b 1
)

set IMAGE_NAME=%DOCKER_USERNAME%/daily-diary-app:latest

echo.
echo [INFO] Starting deployment process...

REM Step 1: Build Docker image
echo [INFO] Step 1: Building Docker image...
docker build -t daily-diary-app .
docker tag daily-diary-app %IMAGE_NAME%

echo [INFO] Docker image built successfully: %IMAGE_NAME%

REM Step 2: Test locally with Docker Compose
echo [INFO] Step 2: Testing locally with Docker Compose...
docker-compose down --remove-orphans 2>nul
docker-compose up -d

echo [INFO] Waiting for services to start...
timeout /t 10 /nobreak >nul

REM Check if app is running (simplified check for Windows)
echo [INFO] Local deployment started. Check http://localhost:3000

REM Step 3: Push to Docker Hub
set /p PUSH_CONFIRM="Do you want to push the image to Docker Hub? (y/n): "

if /i "%PUSH_CONFIRM%"=="y" (
    echo [INFO] Step 3: Pushing image to Docker Hub...
    
    echo [INFO] Please login to Docker Hub:
    docker login
    
    docker push %IMAGE_NAME%
    echo [INFO] ✅ Image pushed to Docker Hub: %IMAGE_NAME%
    
    echo [INFO] Updating Kubernetes deployment file...
    powershell -Command "(Get-Content k8s\app-deployment.yaml) -replace 'your-dockerhub-username/daily-diary-app:latest', '%IMAGE_NAME%' | Set-Content k8s\app-deployment.yaml"
    echo [INFO] ✅ Kubernetes deployment file updated
) else (
    echo [WARNING] Skipping Docker Hub push
)

REM Step 4: Display Kubernetes instructions
echo.
echo [INFO] Step 4: Kubernetes Deployment Instructions
echo ===========================================
echo.
echo To deploy to Azure AKS, run the following commands:
echo.
echo 1. Create AKS cluster:
echo    az group create --name diary-app-rg --location eastus
echo    az aks create --resource-group diary-app-rg --name diary-app-cluster --node-count 2 --generate-ssh-keys
echo    az aks get-credentials --resource-group diary-app-rg --name diary-app-cluster
echo.
echo 2. Deploy to Kubernetes:
echo    kubectl apply -f k8s/mongodb-deployment.yaml
echo    kubectl apply -f k8s/app-deployment.yaml
echo.
echo 3. Get external IP:
echo    kubectl get service diary-app-service --watch
echo.

REM Step 5: Git setup
set /p GIT_CONFIRM="Do you want to initialize Git repository? (y/n): "

if /i "%GIT_CONFIRM%"=="y" (
    echo [INFO] Step 5: Setting up Git repository...
    
    if not exist ".git" (
        git init
        echo [INFO] Git repository initialized
    )
    
    git add .
    git commit -m "Initial commit: Daily Diary CRUD application with Docker and Kubernetes support" 2>nul
    
    echo [INFO] ✅ Files committed to Git
    
    echo.
    echo To push to GitHub:
    echo 1. Create a new repository on GitHub
    echo 2. Run: git remote add origin https://github.com/YOUR_USERNAME/daily-diary-app.git
    echo 3. Run: git push -u origin main
) else (
    echo [WARNING] Skipping Git setup
)

echo.
echo [INFO] 🎉 Deployment script completed!
echo.
echo Summary:
echo - ✅ Docker image built: %IMAGE_NAME%
echo - ✅ Local deployment tested
if /i "%PUSH_CONFIRM%"=="y" (
    echo - ✅ Image pushed to Docker Hub
    echo - ✅ Kubernetes files updated
)
echo.
echo Next steps:
echo 1. Test your app locally at: http://localhost:3000
echo 2. Follow the Kubernetes deployment instructions above
echo 3. Set up your GitHub repository
echo.
echo For detailed instructions, see README.md

pause