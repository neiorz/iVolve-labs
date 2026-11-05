# Lab 21: Jenkins Pipeline for Application Deployment

This lab turns the manual release of a Spring Boot application into one Jenkins pipeline: clone the code, build it, containerize it, scan the image, push it to Docker Hub, clean up, update the deployment manifest and deploy to Kubernetes.

Everything in this report was verified end to end. The Jenkins job is **`DemoApp`** at `http://localhost:8081`, and **build #12 finished green** (all stages, `Finished: SUCCESS`, total **1 min 44 sec**). Every step below is backed by a screenshot from the real run.

![Lab 21 instructions: build a pipeline that automates build, image, scan, push, delete, update and deploy, plus post actions](images/lab21-instrctions.png)

The assignment asks to clone the application from `https://github.com/Ibrahim-Adel15/DemoApp.git` and automate seven processes plus pipeline post actions. We used our own fork, [`neiorz/DemoApp`](https://github.com/neiorz/DemoApp), so the pipeline could live in the repository as a `Jenkinsfile`. The application is the same Spring Boot service: it answers **`Hello from Dockerized Spring Boot!`** on port 8080.

## The pipeline at a glance

The job pulls the `Jenkinsfile` from `neiorz/DemoApp` (branch `main`) and runs these stages:

| # | Stage | What it does | Time (build #12) |
|---|-------|--------------|------------------|
| — | `Checkout SCM` | Checks out `main` at revision `1c5409a` | 0.85 s |
| 1 | `1. Build Maven App` | `mvn clean package` | 6 s |
| 2 | `2. Build Docker Image` | `docker build -t nourz1/demo-app:12 .` | 7 s |
| 3 | `3. Scan Docker Image` | Trivy scan for `HIGH,CRITICAL` vulnerabilities | 22 s |
| 4 | `4. Push to DockerHub` | `docker login` + `docker push nourz1/demo-app:12` | 1 m 2 s |
| 5 | `5. Delete Image Locally` | `docker rmi nourz1/demo-app:12` | 0.89 s |
| 6 | `6. Update Deployment File` | Rewrites the `image:` tag in `deployment.yaml` and commits it locally | 1 s |
| 7 | `7. Deploy to Kubernetes` | `kubectl apply -f deployment.yaml` | 0.57 s |
| — | `Post Actions` | `always` / `success` / `failure` messages | 0.1 s |

The image tag is the build number, so build #12 produces **`nourz1/demo-app:12`**.

## Folder contents

| File | Purpose |
|------|---------|
| `Jenkinsfile` | The pipeline that actually ran as build #12 (7 stages + post actions) |
| `Jenkinsfile.8-stage-reference` | An earlier 8-stage variant, kept for reference; it was **not** used for build #12 |
| `setup.sh` | Prepares the Jenkins container (image, plugins, kubeconfig, Trivy cache) |
| `docker/Dockerfile` | Builds the `jenkins-lab21` image with Maven, Docker CLI, kubectl and Trivy |
| `k8s/deployment-demo-app.yaml` | The manifest build #12 actually applied (copy from the DemoApp repository) |
| `k8s/deployment.yaml`, `k8s/namespace.yaml`, `k8s/service.yaml` | Manifests for the 8-stage reference variant |
| `images/` | All screenshots embedded in this report |

---

## Step 1: Prepare Jenkins

```bash
bash Jenkins/Lab21/setup.sh
```

The script does the heavy lifting:

1. Builds the `jenkins-lab21:latest` image from `docker/Dockerfile` — it contains **Maven 3.9.9, Docker CLI, kubectl, Trivy** and the Kubernetes manifests.
2. Replaces the `jenkins` container but **keeps the `jenkins_home` volume**, so the users and roles from the previous lab survive.
3. Runs it on `http://localhost:8081` with `--network host` and mounts the host's `/var/run/docker.sock` (plus the socket's group id), which is what lets the pipeline run `docker build` and `docker push` directly on the host Docker.
4. Installs the `workflow-aggregator`, `credentials-binding`, `git` and `role-strategy` plugins.
5. Copies a **flattened** kubeconfig into `/var/jenkins_home/.kube/config`, so `kubectl` inside the container has the client certificates embedded (no `~/.minikube` files needed).
6. **Prewarms the Trivy vulnerability database** (about 1.6 GB with the Java database) with a 60-minute timeout, so the first scan does not fail downloading it inside the build.
7. Prints the installed tool versions and the cluster nodes.

The first run downloads the tools and the Trivy database, so it takes a few minutes; afterwards everything is cached in the `jenkins_home` volume.

## Step 2: Add the Docker Hub credential

In Jenkins: **Manage Jenkins → Credentials → System → Global credentials → Add Credentials → Username with password**.

- **Username:** `nourz1` (the Docker Hub account)
- **Password:** a Docker Hub access token
- **ID:** `docker-hub-credentials`

![Global credentials page showing the docker-hub-credentials entry for user nourz1 with the password masked](images/lab21-credentials.png)

The ID must be exactly `docker-hub-credentials`, because the Jenkinsfile says `DOCKERHUB_CREDENTIALS = credentials('docker-hub-credentials')`. Jenkins then exports `DOCKERHUB_CREDENTIALS_USR` and `DOCKERHUB_CREDENTIALS_PSW` and masks the password in the console log.

## Step 3: Create the Jenkins job

1. **New Item → Pipeline**, name it **`DemoApp`**.
2. Under **Build Triggers**, the job can be started manually with **Build Now**.
3. Under **Pipeline**, choose **Pipeline script from SCM**:
   - **SCM:** Git → `https://github.com/neiorz/DemoApp.git`
   - **Branches to build:** `*/main`
   - **Script Path:** `Jenkinsfile`
   - **Lightweight checkout:** enabled (Jenkins fetches only the `Jenkinsfile`)
4. **Save**.

![DemoApp job configuration page with Pipeline script from SCM pointing at the DemoApp repository](images/lab21-job-config.png)

## Step 4: The Jenkinsfile

This is the complete pipeline that ran as build #12 (also stored in this folder as `Jenkinsfile`):

```groovy
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
```

## Step 5: Run the build

Open the job and press **Build Now**. Build **#12** started on **Nov 5, 2026** at revision `1c5409a` of `neiorz/DemoApp` (branch `main`) and finished green in **1 min 44 sec**.

![Build number 12 summary page, green check, repository neiorz/DemoApp, ref main, task 1 min 44 sec](images/lab21-build-summary.png)

The stage view shows every stage green:

![Stage view of build 12 with Checkout SCM, all seven stages and Post Actions green](images/lab21-stage-view.png)

---

## Step 6: What each stage did

### Checkout SCM (0.85 s)

Jenkins obtained the `Jenkinsfile` from the repository and checked out `main` at revision `1c5409a` — *"Merge branch 'main' of github.com:neiorz/DemoApp"*.

![Checkout SCM stage panel showing Check out from version control, 0.85 seconds](images/lab21-SCM.png)

### 1. Build Maven App (6 s)

Runs `mvn clean package`. Maven compiles the single source file, packages `demo-0.0.1-SNAPSHOT.jar` and reports **`BUILD SUCCESS`** in 3.8 s.

![Stage 1 Build Maven App panel showing the mvn clean package step, 6 seconds](images/lab21-mvn.png)

![Console output of stage 1: mvn clean package ending with BUILD SUCCESS and the packaged jar](images/lab21-05-build-maven.png)

### 2. Build Docker Image (7 s)

Runs `docker build -t nourz1/demo-app:12 .`. The Dockerfile copies the jar into `maven:sapmachine`, sets `WORKDIR /app`, `CMD java -jar` and `EXPOSE 8080`. Result: **`Successfully built f19bcfd7510`** / **`Successfully tagged nourz1/demo-app:12`**.

![Stage 2 Build Docker Image panel showing the docker build steps, 7 seconds](images/lab21-build-docker-image.png)

![Console output of stage 2: docker build -t nourz1/demo-app:12, successfully built f19bcfd7510, successfully tagged nourz1/demo-app:12](images/lab21-06-docker-build.png)

### 3. Scan Docker Image (22 s)

Runs `trivy image --exit-code 0 --severity HIGH,CRITICAL nourz1/demo-app:12`. The report summary:

- Ubuntu 24.04 base image: **0** vulnerabilities
- `demo-0.0.1-SNAPSHOT.jar` and libraries: **46**
- **Total: 47 (HIGH: 38, CRITICAL: 9)**

Because of `--exit-code 0` the scan reports but does not block the pipeline — a real policy gate would use `--exit-code 1`.

![Stage 3 Scan Docker Image panel showing the trivy image command, 22 seconds](images/lab21-scan-docker-image.png)

![Console output of stage 3: Trivy report summary table with the HIGH and CRITICAL totals](images/lab21-07-trivy.png)

### 4. Push to DockerHub (1 m 2 s)

Logs in with the stored credential (`echo $DOCKERHUB_CREDENTIALS_PSW | docker login ... --password-stdin`, the password is masked in the log) and pushes `nourz1/demo-app:12`:

```
12: digest: sha256:f19bcfd27510d07b2cbbe7da55fd0773148f64b08e83de9d82404d73d4edc00e size: 2056
```

![Stage 4 Push to DockerHub panel showing docker login and docker push nourz1/demo-app:12](images/lab21-pipline-done.png)

![Console output of stage 4: the pushed digest sha256 f19bcfd27510 and the start of stage 5](images/lab21-08-push.png)

### 5. Delete Image Locally (0.89 s)

`docker rmi nourz1/demo-app:12` removes the image from the Jenkins machine — the cluster pulls from Docker Hub, so keeping it locally would only waste disk and hide a broken push.

![Stage 5 Delete Image Locally panel showing docker rmi and the deleted layer ids](images/lab21-delete-i.png)

![Console output of stage 5: Untagged nourz1/demo-app:12 and the deleted sha256 layers](images/lab21-09-image-deleted.png)

### 6. Update Deployment File (1 s)

Rewrites the image line of `deployment.yaml` so the manifest points at this build's tag, then commits it in the workspace:

```
+ sed -i s|image:.*|image: nourz1/demo-app:12|g deployment.yaml
[detached HEAD 74004e6] Update image tag to 12
 1 file changed, 1 insertion(+), 1 deletion(-)
```

The commit stays local to the Jenkins workspace (the checkout is detached and no push credentials are configured) — the cluster does not need it, it only needs the applied file.

![Console output of stage 6: sed rewriting the image tag and the local git commit Update image tag to 12](images/lab21-10-manifest-update.png)

### 7. Deploy to Kubernetes (0.57 s)

```
+ kubectl apply -f deployment.yaml
deployment.apps/demo-app-deployment created
```

The `demo-app-deployment` (2 replicas, image `nourz1/demo-app:12`) is created in the `default` namespace.

![Stage 7 Deploy to Kubernetes panel showing kubectl apply and deployment created](images/lab21-deplo-to-kubernates.png)

![Console output of stage 7: kubectl apply -f deployment.yaml, deployment.apps/demo-app-deployment created](images/lab21-11-deploy.png)

---

## Step 7: Post actions

All three post actions run at the end:

- **`always`** → `Pipeline finished execution.`
- **`success`** → `Deployment Successful!`
- **`failure`** → `Pipeline Failed!` (not hit in build #12)

The console ends with **`Finished: SUCCESS`**.

![Console end showing Pipeline finished execution, Deployment Successful and Finished SUCCESS](images/lab21-12-post-actions.png)

---

## Step 8: Verify the result

**1. The cluster** — both replicas are up:

```bash
kubectl get pods
```

```
demo-app-deployment-75c5c664d4-hqxwj   1/1   Running   0   3m17s
demo-app-deployment-75c5c664d4-phr8d   1/1   Running   0   3m17s
```

![Terminal showing kubectl get pods with two demo-app-deployment pods Running 1/1](images/lab21-verfiy.png)

**2. Docker Hub** — the public repository [`nourz1/demo-app`](https://hub.docker.com/r/nourz1/demo-app) carries tag **`12`**, pushed by the pipeline:

- Digest: `f19bcfd7510` (linux/amd64, 212.71 MB compressed)
- Pull command: `docker pull nourz1/demo-app:12`

![Docker Hub tags page for nourz1/demo-app with tag 12 and the docker pull command](images/lab21-push-on-dockerhub.png)

![Docker Hub tag details: tag 12, digest f19bcfd7510, linux amd64, 212.71 MB](images/lab21-dockerhub-tags.png)

**3. The application** — forward the pod port and call it:

```bash
kubectl port-forward deploy/demo-app-deployment 18080:8080
curl http://127.0.0.1:18080/
```

```
Hello from Dockerized Spring Boot!
```

![Browser window with the text Hello from Dockerized Spring Boot](images/lab21-app-response.png)

---

## Problems we hit and how we fixed them

| Problem | Symptom | Fix |
|---------|---------|-----|
| Trivy could not download its database | `failed to download vulnerability DB: context deadline exceeded`, later `walk dir error: context deadline exceeded` | `setup.sh` prewarms the database (`--download-db-only --timeout 60m` plus the Java database) into the `jenkins_home` volume, and a long timeout avoids the default 5-minute limit |
| `docker build` failed inside Jenkins | `Cannot connect to the Docker daemon at unix:///var/run/docker.sock` | Start the container with `-v /var/run/docker.sock:/var/run/docker.sock` **and** `--group-add "$(stat -c '%g' /var/run/docker.sock)"` — the mount creates the socket, the group makes it writable by the `jenkins` user |
| Credential ID mismatch | Pipeline fails before the first stage with a credentials error | The ID must be exactly `docker-hub-credentials` to match `credentials('docker-hub-credentials')` |
| `kubectl` TLS errors inside the container | Certificate file not found (`~/.minikube/...`) | Copy a **flattened** kubeconfig: `kubectl config view --flatten --minify` embeds the client certificate and key |
| First scan is slow | Trivy prints `Provide a higher timeout value` | Prewarm the cache (done by `setup.sh`); only the first run pays the download |

## Known limitations

These were left as-is on purpose — build #12 was verified with the current behaviour:

1. **No Kubernetes Service.** The app is reached with `kubectl port-forward`; there is no ClusterIP/NodePort yet.
2. **`containerPort: 7070` in the manifest, but the app listens on 8080.** `containerPort` is only metadata, so the pod still works (the port-forward targets 8080), but the manifest should be corrected to `8080`.
3. **Stage 6's commit is never pushed** — it stays in the Jenkins workspace on a detached HEAD.
4. **The deploy stage does not wait for the rollout** (`kubectl rollout status` is missing), so `kubectl apply` returning does not yet guarantee the new pods are ready.
5. **The Trivy scan does not block** (`--exit-code 0`): 47 HIGH/CRITICAL findings were reported but allowed through. Use `--exit-code 1` to turn it into a gate.
6. **No `imagePullSecrets`** in the deployed manifest — fine while `nourz1/demo-app` stays public; a private repository would need one.
7. **The 8-stage variant was not run.** It is kept as `Jenkinsfile.8-stage-reference` for comparison; the live pipeline is the 7-stage `Jenkinsfile`.

## Cleanup

Remove the deployment:

```bash
kubectl delete deployment demo-app-deployment
```

Stop Jenkins:

```bash
docker stop jenkins
```

Remove Jenkins and its state (this also removes the previous lab's users and roles):

```bash
docker rm -f jenkins
docker volume rm jenkins_home
```

Remove the locally built Jenkins image:

```bash
docker rmi jenkins-lab21:latest
```

## Summary

- One declarative `Jenkinsfile` with **7 stages + checkout + post actions** automated the whole release of the DemoApp Spring Boot service.
- Build **#12** went from source to a running Kubernetes deployment in **1 min 44 sec**: Maven build → Docker image `nourz1/demo-app:12` → Trivy scan (47 findings reported) → push to Docker Hub → local cleanup → manifest update → `kubectl apply`.
- The result was verified three ways: two pods `Running`, Docker Hub tag `12`, and the application answering `Hello from Dockerized Spring Boot!`.
- `setup.sh` prepares everything the pipeline needs: tools in the `jenkins-lab21` image, the Docker socket, a flattened kubeconfig and a warm Trivy cache.
