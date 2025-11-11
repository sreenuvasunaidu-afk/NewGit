pipeline {
    agent any
    options {
        timeout(time: 15, unit: 'MINUTES')
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
    }
    stages {
        stage('Checkout') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    echo '========================================'
                    echo 'STAGE: Checkout'
                    echo '========================================'
                    echo 'Checking out code from repository...'
                    checkout scm
                    echo '✓ Checkout completed successfully'
                }
            }
        }
        stage('Validate & Build') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    echo '========================================'
                    echo 'STAGE: Validate & Build'
                    echo '========================================'
                    sh '''
                        set -e
                        echo "Current directory: $(pwd)"
                        echo "Directory contents:"
                        ls -la
                        
                        echo ""
                        echo "Validating required files..."
                        if [ -f "app/Dockerfile" ]; then
                            echo "✓ Dockerfile found"
                        else
                            echo "✗ ERROR: Dockerfile not found in app/"
                            exit 1
                        fi
                        
                        if [ -f "app/index.html" ]; then
                            echo "✓ index.html found"
                        else
                            echo "✗ ERROR: index.html not found in app/"
                            exit 1
                        fi
                        
                        echo ""
                        echo "Building Docker image..."
                        docker --version
                        cd app
                        docker build -t mywebapp:latest .
                        echo "✓ Docker image built successfully"
                        
                        echo ""
                        echo "Verifying Docker image..."
                        docker images | grep mywebapp
                        echo "✓ Docker image verification passed"
                    '''
                }
            }
        }
        stage('Deploy') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    echo '========================================'
                    echo 'STAGE: Deploy'
                    echo '========================================'
                    sh '''
                        set -e
                        echo "Stopping any previous containers..."
                        docker stop mywebapp || true
                        docker rm mywebapp || true
                        
                        echo ""
                        echo "Deploying Docker container..."
                        docker run -d --name mywebapp -p 8080:80 mywebapp:latest
                        
                        echo ""
                        echo "Verifying container is running..."
                        docker ps | grep mywebapp
                        echo "✓ Container is running successfully"
                        
                        echo ""
                        echo "Container logs:"
                        docker logs mywebapp || true
                    '''
                }
            }
        }
    }
    post {
        always {
            echo "========== Pipeline Execution Summary =========="
            echo "Job Name: ${JOB_NAME}"
            echo "Build Number: ${BUILD_NUMBER}"
            echo "Build URL: ${BUILD_URL}"
        }
        success {
            echo '✓ Pipeline completed successfully!'
        }
        failure {
            echo '✗ Pipeline failed!'
            echo "Failed stage information should be visible in the console output above"
        }
        unstable {
            echo '⚠ Pipeline is unstable!'
        }
        cleanup {
            echo 'Cleaning up workspace...'
            cleanWs()
        }
    }
}
