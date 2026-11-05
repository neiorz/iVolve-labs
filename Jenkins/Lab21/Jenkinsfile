pipeline {
    agent any
    environment {
        DOCKERHUB_CREDENTIALS = credentials('docker-hub-credentials')
        IMAGE_NAME = 'nourz1/demo-app'
    }
    stages {
        stage('1. Build Maven App') {
            steps {
                sh "mvn clean package"
            }
        }
        stage('2. Build Docker Image') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} ."
            }
        }
        stage('3. Scan Docker Image') {
            steps {
                sh "trivy image --exit-code 0 --severity HIGH,CRITICAL ${IMAGE_NAME}:${BUILD_NUMBER}"
            }
        }
        stage('4. Push to DockerHub') {
            steps {
                sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
                sh "docker push ${IMAGE_NAME}:${BUILD_NUMBER}"
            }
        }
        stage('5. Delete Image Locally') {
            steps {
                sh "docker rmi ${IMAGE_NAME}:${BUILD_NUMBER}"
            }
        }
        stage('6. Update Deployment File') {
            steps {
                sh "sed -i 's|image:.*|image: ${IMAGE_NAME}:${BUILD_NUMBER}|g' deployment.yaml"
                sh "git config user.email 'jenkins@ivolve.com'"
                sh "git config user.name 'Jenkins CI'"
                sh "git add deployment.yaml"
                sh "git commit -m 'Update image tag to ${BUILD_NUMBER}' || true"
            }
        }
        stage('7. Deploy to Kubernetes') {
            steps {
                sh "kubectl apply -f deployment.yaml"
            }
        }
    }
    post {
        always {
            echo "Pipeline finished execution."
        }
        success {
            echo "Deployment Successful!"
        }
        failure {
            echo "Pipeline Failed!"
        }
    }
}

