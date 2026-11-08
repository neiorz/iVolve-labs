def call(String imageName, String imageTag, String deploymentFile = 'k8s/deployment.yaml', String branch = 'lab23') {
    echo "Updating image in ${deploymentFile}"
    sh "sed -i 's|image:.*|image: ${imageName}:${imageTag}|g' ${deploymentFile}"

    echo "Pushing the updated manifest to GitHub (branch ${branch})"
    withCredentials([usernamePassword(credentialsId: 'github-credentials',
                                      usernameVariable: 'GIT_USER',
                                      passwordVariable: 'GIT_PASS')]) {
        sh """
            git config user.email 'jenkins@ivolve.com'
            git config user.name 'Jenkins CI'
            git add ${deploymentFile}
            git commit -m 'Update image tag to ${imageTag}' || true
            REPO=\$(git config --get remote.origin.url | sed 's|https://||')
            git push https://\${GIT_USER}:\${GIT_PASS}@\$REPO HEAD:${branch}
        """
    }
    echo "Argo CD will detect the change and sync the cluster"
}
