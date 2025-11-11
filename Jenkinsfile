pipeline {
    agent any
    options {
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from repository...'
                checkout scm
            }
        }
        stage('Terraform Apply') {
            steps {
                echo 'Starting Terraform Apply stage...'
                dir('Terraform') {
                    sh '''
                        set -e
                        echo "Running terraform init..."
                        terraform init
                        echo "Running terraform apply..."
                        terraform apply -auto-approve
                        echo "Terraform apply completed successfully"
                    '''
                }
            }
        }
        stage('Ansible Configure') {
            steps {
                echo 'Starting Ansible Configure stage...'
                dir('Ansible') {
                    sh '''
                        set -e
                        echo "Running ansible-playbook..."
                        ansible-playbook -i inventory.ini playbook.yaml
                        echo "Ansible playbook completed successfully"
                    '''
                }
            }
        }
        stage('Docker Deploy') {
            steps {
                echo 'Starting Docker Deploy stage...'
                dir('app') {
                    sh '''
                        set -e
                        echo "Building Docker image..."
                        docker build -t mywebapp .
                        echo "Running Docker container..."
                        docker run -d -p 80:80 mywebapp
                        echo "Docker deployment completed successfully"
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