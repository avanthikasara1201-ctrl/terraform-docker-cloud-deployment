
pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-west-1'
        AWS_ACCOUNT_ID     = '075810104101'
        ECR_REPOSITORY     = 'my-cloud-website'
        IMAGE_NAME         = 'my-cloud-website'
        EC2_INSTANCE_ID    = 'i-0eb49e386966afd20'
        AWS_CREDENTIALS_ID = 'aws-credentials'
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
                    set -eu
                    docker --version
                    aws --version
                '''
            }
        }

        stage('Build Website Image') {
            steps {
                sh '''
                    set -eu
                    docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} .
                '''
            }
        }

        stage('Verify Image') {
            steps {
                sh '''
                    set -eu
                    docker image inspect ${IMAGE_NAME}:${BUILD_NUMBER}
                '''
            }
        }

        stage('Push Image to Amazon ECR') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: "${AWS_CREDENTIALS_ID}"]
                ]) {
                    sh '''
                        set -eu

                        ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"

                        aws sts get-caller-identity

                        aws ecr get-login-password --region "${AWS_DEFAULT_REGION}" \
                          | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

                        docker tag "${IMAGE_NAME}:${BUILD_NUMBER}" \
                          "${ECR_REGISTRY}/${ECR_REPOSITORY}:${BUILD_NUMBER}"

                        docker push "${ECR_REGISTRY}/${ECR_REPOSITORY}:${BUILD_NUMBER}"

                        docker tag "${IMAGE_NAME}:${BUILD_NUMBER}" \
                          "${ECR_REGISTRY}/${ECR_REPOSITORY}:latest"

                        docker push "${ECR_REGISTRY}/${ECR_REPOSITORY}:latest"

                        docker logout "${ECR_REGISTRY}"
                    '''
                }
            }
        }

        stage('Deploy to EC2 using SSM') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: "${AWS_CREDENTIALS_ID}"]
                ]) {
                    sh '''
                        set -eu

                        ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"

                        COMMAND_ID=$(aws ssm send-command \
                          --region "${AWS_DEFAULT_REGION}" \
                          --instance-ids "${EC2_INSTANCE_ID}" \
                          --document-name "AWS-RunShellScript" \
                          --comment "Deploy website from Jenkins build ${BUILD_NUMBER}" \
                          --parameters "commands=[
                            \\"set -e\\",
                            \\"aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}\\",
                            \\"docker pull ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest\\",
                            \\"docker rm -f myterraform-web my-cloud-website || true\\",
                            \\"docker run -d --name myterraform-web --restart unless-stopped -p 80:80 ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest\\"
                          ]" \
                          --query 'Command.CommandId' \
                          --output text)

                        echo "SSM command ID: ${COMMAND_ID}"

                        aws ssm wait command-executed \
                          --region "${AWS_DEFAULT_REGION}" \
                          --command-id "${COMMAND_ID}" \
                          --instance-id "${EC2_INSTANCE_ID}"

                        aws ssm get-command-invocation \
                          --region "${AWS_DEFAULT_REGION}" \
                          --command-id "${COMMAND_ID}" \
                          --instance-id "${EC2_INSTANCE_ID}" \
                          --query 'StandardOutputContent' \
                          --output text

                        echo "Deployment completed successfully."
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'CI/CD pipeline completed successfully!'
        }

        failure {
            echo 'Pipeline failed. Check the Console Output for the failing stage.'
        }
    }
}
