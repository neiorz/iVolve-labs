@Library('my-shared-lib') _

pipeline {
    agent { label 'agent-1' }

    environment {
        IMAGE_NAME = 'nourz1/demo-app'
    }

    stages {
        stage('1. Build App') {
            steps {
                buildApp()
            }
        }
        stage('2. Build Image') {
            steps {
                buildImage(env.IMAGE_NAME, env.BUILD_NUMBER)
            }
        }
        stage('3. Deploy on K8s') {
            steps {
                deployOnK8s(env.IMAGE_NAME, env.BUILD_NUMBER)
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
