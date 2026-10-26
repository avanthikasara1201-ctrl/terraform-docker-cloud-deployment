
pipeline {
    agent any

    environment {
        AWS_REGION = 'us-west-1'
        ECR_REGISTRY = '075810104101.dkr.ecr.us-west-1.amazonaws.com'
        ECR_REPOSITORY = 'my-cloud-website'
        EC2_INSTANCE_ID = 'i-01789d5a178b689bc'
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

                        export AWS_DEFAULT_REGION="$AWS_REGION"

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

        stage('Deploy to EC2 using SSM') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-ecr-credentials',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    script {
                        def commands = [
                            'set -e',
                            'aws ecr get-login-password --region us-west-1 | docker login --username AWS --password-stdin 075810104101.dkr.ecr.us-west-1.amazonaws.com',
                            'docker pull 075810104101.dkr.ecr.us-west-1.amazonaws.com/my-cloud-website:latest',
                            'docker rm -f myterraform-web my-cloud-website || true',
                            'docker run -d --name myterraform-web --restart unless-stopped -p 80:80 075810104101.dkr.ecr.us-west-1.amazonaws.com/my-cloud-website:latest'
                        ]

                        def parameters = groovy.json.JsonOutput.toJson([
                            commands: commands
                        ])

                        withEnv(["SSM_PARAMETERS=${parameters}"]) {
                            sh '''
                                set -eu
                                export AWS_DEFAULT_REGION="$AWS_REGION"

                                COMMAND_ID=$(aws ssm send-command \
                                    --region "$AWS_REGION" \
                                    --instance-ids i-0eb49e386966afd20
                                    --document-name "AWS-RunShellScript" \
                                    --comment "Deploy website from Jenkins build ${BUILD_NUMBER}" \
                                    --parameters "$SSM_PARAMETERS" \
                                    --query 'Command.CommandId' \
                                    --output text)

                                echo "SSM command ID: $COMMAND_ID"

                                aws ssm wait command-executed \
                                    --region "$AWS_REGION" \
                                    --command-id "$COMMAND_ID" \
                                    --instance-id "$EC2_INSTANCE_ID"

                                aws ssm get-command-invocation \
                                    --region "$AWS_REGION" \
                                    --command-id "$COMMAND_ID" \
                                    --instance-id "$EC2_INSTANCE_ID" \
                                    --query 'StandardOutputContent' \
                                    --output text
                            '''
                        }
                    }
                }
            }
        }
    }
}
