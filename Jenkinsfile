
pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-west-1'
        AWS_ACCOUNT_ID = '075810104101'
        ECR_REPOSITORY = 'my-cloud-website'
        EC2_INSTANCE_ID = 'i-0eb49e386966afd20'
        IMAGE_URI = '075810104101.dkr.ecr.us-west-1.amazonaws.com/my-cloud-website'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    set -e
                    echo "Building Docker image..."
                    docker build -t my-cloud-website:${BUILD_NUMBER} .
                    docker tag my-cloud-website:${BUILD_NUMBER} ${IMAGE_URI}:${BUILD_NUMBER}
                    docker tag my-cloud-website:${BUILD_NUMBER} ${IMAGE_URI}:latest
                '''
            }
        }

        stage('Verify Docker Image') {
            steps {
                sh '''
                    set -e
                    echo "Verifying Docker image..."
                    docker image inspect ${IMAGE_URI}:${BUILD_NUMBER}
                '''
            }
        }

        stage('Push Image to Amazon ECR') {
            steps {
                sh '''
                    set -e

                    echo "Logging in to Amazon ECR..."
                    aws ecr get-login-password --region "$AWS_DEFAULT_REGION" \
                      | docker login \
                        --username AWS \
                        --password-stdin \
                        "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"

                    echo "Pushing versioned image..."
                    docker push "${IMAGE_URI}:${BUILD_NUMBER}"

                    echo "Pushing latest image..."
                    docker push "${IMAGE_URI}:latest"
                '''
            }
        }

        stage('Deploy to EC2 using SSM') {
            steps {
                sh '''
                    set -eu

                    echo "Sending deployment command to EC2..."

                    COMMAND_ID=$(aws ssm send-command \
                        --region "$AWS_DEFAULT_REGION" \
                        --instance-ids "$EC2_INSTANCE_ID" \
                        --document-name "AWS-RunShellScript" \
                        --comment "Deploy website from Jenkins build $BUILD_NUMBER" \
                        --parameters "commands=[
                          \\"set -e\\",
                          \\"aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $IMAGE_URI\\",
                          \\"docker pull $IMAGE_URI:latest\\",
                          \\"docker rm -f myterraform-web || true\\",
                          \\"docker run -d --name myterraform-web --restart unless-stopped -p 80:80 $IMAGE_URI:latest\\"
                        ]" \
                        --query 'Command.CommandId' \
                        --output text)

                    echo "SSM Command ID: $COMMAND_ID"
                    echo "Waiting for deployment..."

                    ATTEMPT=0

                    while [ "$ATTEMPT" -lt 30 ]; do
                        STATUS=$(aws ssm get-command-invocation \
                            --region "$AWS_DEFAULT_REGION" \
                            --command-id "$COMMAND_ID" \
                            --instance-id "$EC2_INSTANCE_ID" \
                            --query 'Status' \
                            --output text 2>/dev/null || true)

                        echo "Deployment status: $STATUS"

                        case "$STATUS" in
                            Success)
                                echo "Deployment completed successfully!"
                                exit 0
                                ;;
                            Failed|Cancelled|TimedOut)
                                echo "Deployment failed. Fetching details..."
                                aws ssm get-command-invocation \
                                    --region "$AWS_DEFAULT_REGION" \
                                    --command-id "$COMMAND_ID" \
                                    --instance-id "$EC2_INSTANCE_ID" \
                                    --output json || true
                                exit 1
                                ;;
                        esac

                        ATTEMPT=$((ATTEMPT + 1))
                        sleep 5
                    done

                    echo "Timed out waiting for deployment."
                    exit 1
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully. Check the website in your browser.'
        }

        failure {
            echo 'Pipeline failed. Check Console Output for the failing stage.'
        }

        always {
            echo 'Jenkins pipeline execution finished.'
        }
    }
}
