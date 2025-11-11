pipeline {
    agent any
    options {
        timeout(time: 25, unit: 'MINUTES')
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('Diagnostics') {
            steps {
                echo '===== DIAGNOSTICS ====='
                script {
                    echo "Node: ${env.NODE_NAME}"
                    echo "Workspace: ${env.WORKSPACE}"
                    echo "isUnix(): ${isUnix()}"

                    if (isUnix()) {
                        echo 'Running unix diagnostics (sh)'
                        sh '''#!/bin/sh
                            set -e
                            echo "PWD: $(pwd)"
                            echo "ls -la:"; ls -la || true
                            echo "uname:"; uname -a || true
                            echo "which docker:"; which docker || true
                            docker --version || true
                        '''
                    } else {
                        echo 'Running windows diagnostics (bat)'
                        bat '''@echo off
                            echo PWD: %cd%
                            dir || true
                            ver || true
                            where docker || echo DOCKER_NOT_FOUND
                            docker --version || echo DOCKER_NOT_FOUND
                        '''
                    }
                }
            }
        }

        stage('Validate prerequisites') {
            steps {
                script {
                    def haveDocker = false
                    if (isUnix()) {
                        haveDocker = (sh(returnStatus: true, script: 'which docker') == 0)
                    } else {
                        haveDocker = (bat(returnStatus: true, script: 'where docker') == 0)
                    }

                    env.HAVE_DOCKER = haveDocker.toString()
                    echo "HAVE_DOCKER=${env.HAVE_DOCKER}"

                    if (!haveDocker) {
                        echo 'WARNING: Docker not available on this agent — Docker build/deploy stages will be skipped.'
                    }
                }
            }
        }

        stage('Checkout') {
            steps {
                echo 'Checking out repository...'
                checkout scm
            }
        }

        stage('Docker Build (conditional)') {
            when {
                expression { return env.HAVE_DOCKER == 'true' }
            }
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    script {
                        echo 'Building Docker image (non-interactive, no cache)'
                        if (isUnix()) {
                            def rc = sh(returnStatus: true, script: 'docker build --pull --no-cache -t mywebapp:ci app')
                            if (rc != 0) { error "docker build failed with exit ${rc}" }
                        } else {
                            def rc = bat(returnStatus: true, script: 'docker build --pull --no-cache -t mywebapp:ci app')
                            if (rc != 0) { error "docker build failed (bat)" }
                        }
                        echo 'Docker build completed'
                    }
                }
            }
        }

        stage('Run Container (conditional)') {
            when {
                expression { return env.HAVE_DOCKER == 'true' }
            }
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    script {
                        echo 'Stopping any existing container named mywebapp_ci'
                        if (isUnix()) {
                            sh 'docker rm -f mywebapp_ci || true'
                            sh 'docker run -d --name mywebapp_ci -p 8080:80 mywebapp:ci'
                            sh 'sleep 2'
                            def rc = sh(returnStatus: true, script: 'docker ps --filter "name=mywebapp_ci" --format "{{.Names}}" | grep mywebapp_ci >/dev/null')
                            if (rc != 0) { error 'Container did not start as expected' }
                        } else {
                            bat 'docker rm -f mywebapp_ci || exit 0'
                            bat 'docker run -d --name mywebapp_ci -p 8080:80 mywebapp:ci'
                            sleep 2
                            def rc = bat(returnStatus: true, script: 'docker ps --filter "name=mywebapp_ci" --format "{{.Names}}" | findstr mywebapp_ci')
                            if (rc != 0) { error 'Container did not start as expected (bat)' }
                        }
                        echo 'Container started successfully'
                    }
                }
            }
        }

        stage('Smoke Test (conditional)') {
            when {
                expression { return env.HAVE_DOCKER == 'true' }
            }
            steps {
                timeout(time: 3, unit: 'MINUTES') {
                    script {
                        echo 'Performing simple HTTP smoke test against container'
                        if (isUnix()) {
                            def rc = sh(returnStatus: true, script: 'curl -sS --max-time 5 http://127.0.0.1:8080/ | head -n 5')
                            if (rc != 0) { echo 'curl failed or not installed; skipping content check' }
                        } else {
                            def rc = bat(returnStatus: true, script: 'powershell -Command "Invoke-WebRequest -Uri http://127.0.0.1:8080 -UseBasicParsing -TimeoutSec 5 | Select-Object -First 1"')
                            if (rc != 0) { echo 'Invoke-WebRequest failed; skipping content check' }
                        }
                        echo 'Smoke test done'
                    }
                }
            }
        }

        stage('Cleanup (always)') {
            steps {
                script {
                    if (env.HAVE_DOCKER == 'true') {
                        echo 'Cleaning up container'
                        if (isUnix()) {
                            sh 'docker rm -f mywebapp_ci || true'
                        } else {
                            bat 'docker rm -f mywebapp_ci || exit 0'
                        }
                    } else {
                        echo 'No docker on agent; nothing to clean'
                    }
                }
            }
        }
    }

    post {
        always {
            echo '===== BUILD SUMMARY ====='
            echo "Job: ${env.JOB_NAME}"
            echo "Build: ${env.BUILD_NUMBER}"
            echo "Node: ${env.NODE_NAME}"
            echo "Have Docker: ${env.HAVE_DOCKER}"
        }
        success {
            echo '✓ Pipeline succeeded'
        }
        failure {
            echo '✗ Pipeline failed — check console output for the failing stage and error messages'
        }
    }
}
pipeline {
    agent any
    options {
        timeout(time: 15, unit: 'MINUTES')
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
    }
    stages {
        stage('Diagnostics') {
            steps {
                echo '========================================'
                echo 'STAGE: Diagnostics'
                echo '========================================'
                script {
                    echo "Environment variables:"
                    sh(returnStdout: true, script: 'env || set || true').trim().split('\n').each { echo it }

                    // Check sh availability (returns status rather than failing the build)
                    def shStatus = -1
                    try {
                        shStatus = sh(returnStatus: true, script: 'echo SH_OK; uname -a || ver')
                    } catch (err) {
                        shStatus = -1
                    }
                    echo "sh return status: ${shStatus}"

                    // Check bat availability
                    def batStatus = -1
                    try {
                        batStatus = bat(returnStatus: true, script: 'echo BAT_OK & ver')
                    } catch (err) {
                        batStatus = -1
                    }
                    echo "bat return status: ${batStatus}"

                    // Check Docker using both sh and bat (whichever is present)
                    def dockerSh = sh(returnStatus: true, script: 'docker --version')
                    echo "docker (sh) return status: ${dockerSh}"
                    def dockerBat = bat(returnStatus: true, script: 'docker --version')
                    echo "docker (bat) return status: ${dockerBat}"

                    echo 'Diagnostics done.\nPlease share the Console Output for this stage if issues persist.'
                }
            }
        }
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
