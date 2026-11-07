def call(String imageName, String imageTag, String deploymentFile = 'deployment.yaml') {
    echo "Updating image in ${deploymentFile}"
    sh "sed -i 's|image:.*|image: ${imageName}:${imageTag}|g' ${deploymentFile}"

    echo "Deploying to Kubernetes cluster"
    sh "kubectl apply -f ${deploymentFile}"
}
