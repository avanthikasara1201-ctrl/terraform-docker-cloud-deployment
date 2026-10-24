pipeline {
    agent any

    stages {
        stage('Checkout Source') {
            steps {
                checkout scm
            }
        }

        stage('Check Docker') {
            steps {
                sh 'docker --version'
            }
        }

        stage('Build Website Image') {
            steps {
                sh 'docker build -t my-cloud-website:${BUILD_NUMBER} .'
            }
        }

        stage('Verify Image') {
            steps {
                sh 'docker image inspect my-cloud-website:${BUILD_NUMBER}'
            }
        }
    }
}
