pipeline {
  agent any
  options {
    timeout(time: 5, unit: 'MINUTES')
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  stages {
    stage('Quick Diagnostics') {
      steps {
        echo '=== QUICK DIAGNOSTICS: This pipeline intentionally minimal to verify agent health ==='
        script {
          echo "Node: ${env.NODE_NAME}"
          echo "Workspace: ${env.WORKSPACE}"
          echo "isUnix(): ${isUnix()}"

          if (isUnix()) {
            // run very small, safe commands that should exist on any Unix-like agent
            sh 'echo PWD: $(pwd)'
            sh 'echo LISTING ROOT:; ls -la . || true'
            sh 'echo SHELL: $SHELL || true'
            sh 'echo DATE: $(date)'
          } else {
            bat 'echo PWD: %cd%'
            bat 'dir'
            bat 'ver'
            bat 'powershell -Command "Get-Date"'
          }

          echo 'Quick Diagnostics complete.'
        }
      }
    }

    stage('Sanity: Verify git checkout worked') {
      steps {
        echo 'Checking for repository files we expect...'
        script {
          def missing = []
          if (!fileExists('app/Dockerfile')) { missing << 'app/Dockerfile' }
          if (!fileExists('app/index.html')) { missing << 'app/index.html' }
          if (!fileExists('Ansible/playbook.yaml')) { missing << 'Ansible/playbook.yaml' }
          if (!fileExists('Terraform/Main.tf')) { missing << 'Terraform/Main.tf' }

          if (missing.size() > 0) {
            echo "Missing files: ${missing.join(', ')}"
            error 'Sanity check failed: required files missing in workspace'
          } else {
            echo 'Sanity check passed: required files present'
          }
        }
      }
    }

    stage('End') {
      steps {
        echo 'Minimal check finished — if this completes, agent basics are OK.'
      }
    }
  }

  post {
    always {
      echo "Job: ${env.JOB_NAME} #${env.BUILD_NUMBER} finished."
    }
  }
}
