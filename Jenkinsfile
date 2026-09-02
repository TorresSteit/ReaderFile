pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'docker build -t file_analyzer .'
            }
        }
        stage('Test') {
            steps {
                sh 'docker run --rm file_analyzer --version'
            }
        }
        stage('Push') {
            steps {
                sh 'docker push your-registry/file_analyzer:latest'
            }
        }
    }
}