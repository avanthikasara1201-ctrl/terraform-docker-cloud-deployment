
pipeline {
    agent any

    environment {
        AWS_REGION = 'us-west-1'
        ECR_REGISTRY = '075810104101.dkr.ecr.us-west-1.amazonaws.com'
        ECR_REPOSITORY = 'my-cloud-website'
    }

    stages {
        stage('Checkout Source') {
            steps {
                checkout scm
            }
        }

        stage('Check Tools') {
            steps {
                sh '''
                    docker --version
                    aws --version
                '''
            }
        }

        stage('Build Website Image') {
            steps {
                sh '''
                    docker build -t my-cloud-website:${BUILD_NUMBER} .
                '''
            }
        }

        stage('Verify Image') {
            steps {
                sh '''
                    docker image inspect my-cloud-website:${BUILD_NUMBER}
                '''
            }
        }

        stage('Push Image to Amazon ECR') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-ecr-credentials',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                        set -eu

                        aws ecr get-login-password --region "$AWS_REGION" |
                            docker login --username AWS --password-stdin "$ECR_REGISTRY"

                        docker tag my-cloud-website:${BUILD_NUMBER} \
                            "$ECR_REGISTRY/$ECR_REPOSITORY:${BUILD_NUMBER}"

                        docker push "$ECR_REGISTRY/$ECR_REPOSITORY:${BUILD_NUMBER}"

                        docker tag my-cloud-website:${BUILD_NUMBER} \
                            "$ECR_REGISTRY/$ECR_REPOSITORY:latest"

                        docker push "$ECR_REGISTRY/$ECR_REPOSITORY:latest"

                        docker logout "$ECR_REGISTRY"
                    '''
                }
            }
        }
    }
}
