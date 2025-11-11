pipeline {
    agent any
    options {
        timeout(time: 60, unit: 'MINUTES')
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
    }
    stages {
        stage('Checkout') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    echo 'Checking out code from repository...'
                    checkout scm
                }
            }
        }
        stage('Terraform Apply') {
            steps {
                timeout(time: 20, unit: 'MINUTES') {
                    echo 'Starting Terraform Apply stage...'
                    dir('Terraform') {
                        sh '''
                            set -e
                            echo "Running terraform init..."
                            terraform init -no-color
                            echo "Terraform init completed"
                            echo "Running terraform apply..."
                            terraform apply -auto-approve -no-color -input=false
                            echo "Terraform apply completed successfully"
                        '''
                    }
                }
            }
        }
        stage('Ansible Configure') {
            when {
                expression {
                    return fileExists('Ansible/playbook.yaml')
                }
            }
            steps {
                timeout(time: 20, unit: 'MINUTES') {
                    echo 'Starting Ansible Configure stage...'
                    dir('Ansible') {
                        sh '''
                            set -e
                            echo "Running ansible-playbook..."
                            ansible-playbook -i inventory.ini playbook.yaml -v
                            echo "Ansible playbook completed successfully"
                        '''
                    }
                }
            }
        }
        stage('Docker Deploy') {
            when {
                expression {
                    return fileExists('app/Dockerfile')
                }
            }
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    echo 'Starting Docker Deploy stage...'
                    dir('app') {
                        sh '''
                            set -e
                            echo "Building Docker image..."
                            docker build -t mywebapp .
                            echo "Docker image built successfully"
                            echo "Running Docker container..."
                            docker run -d -p 80:80 mywebapp || echo "Container already running or port in use"
                            echo "Docker deployment completed"
                        '''
                    }
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
