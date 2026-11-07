def call(String imageName, String imageTag) {
    echo "Building Docker image ${imageName}:${imageTag}"
    sh "docker build -t ${imageName}:${imageTag} ."

    echo "Scanning image with Trivy"
    sh "trivy image --exit-code 0 --severity HIGH,CRITICAL ${imageName}:${imageTag}"

    echo "Pushing image to Docker Hub"
    withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials',
                                      usernameVariable: 'DOCKER_USER',
                                      passwordVariable: 'DOCKER_PASS')]) {
        sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
        sh "docker push ${imageName}:${imageTag}"
    }

    echo "Deleting local image"
    sh "docker rmi ${imageName}:${imageTag}"
}
