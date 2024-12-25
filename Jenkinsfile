pipeline {
  agent none
  stages {
    stage('Back-end') {
      agent {
        docker { image 'python:3.9-slim' }
      }
      steps {
        sh 'python --version'
      }
    }
  
  }
}
