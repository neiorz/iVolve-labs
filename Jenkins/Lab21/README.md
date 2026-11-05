# Lab 21: Jenkins Pipeline for Application Deployment

This lab turns the manual release of a small Spring Boot application into one Jenkins pipeline: clone, build, containerize, scan, push, clean up, update the manifests and deploy to Kubernetes. The application is [`Ibrahim-Adel15/DemoApp`](https://github.com/Ibrahim-Adel15/DemoApp), a Spring Boot service that answers `Hello from Dockerized Spring Boot!` on port 8080.

## Objective

Automate the following with a Jenkins Declarative Pipeline:

1. Clone the source code and Dockerfile.
2. Build the application.
3. Build the Docker image.
4. Scan the image.
5. Push the image to Docker Hub.
6. Delete the image locally.
7. Update the image tag in the deployment file.
8. Deploy to the Kubernetes cluster.

The pipeline also defines the `always`, `success` and `failure` post actions.

## Folder contents

| File | Purpose |
|------|---------|
| `Jenkinsfile` | The pipeline itself: eight stages plus the three post actions |
| `docker/Dockerfile` | Builds the Jenkins image used by this lab: Maven, Docker CLI, kubectl, Trivy and the manifests |
| `setup.sh` | Builds that image, reuses the Lab 20 volume, installs plugins and copies a kubeconfig |
| `k8s/namespace.yaml` | Creates the `ivolve` namespace |
| `k8s/deployment.yaml` | Two replicas of the application, with probes and resource limits |
| `k8s/service.yaml` | A `NodePort` service on port `30080` |

## Prerequisites

- Docker on a Linux host, and the `jenkins_home` volume from Lab 20 (the script keeps it, so the users and roles survive).
- A Kubernetes cluster, either minikube or k3s. For minikube, start it before running the setup: `minikube start`.
- A Docker Hub account and an access token. The repository can be public or private; the pipeline creates an image pull secret either way.
- Host tools used by `setup.sh`: `docker`, `kubectl` (to flatten the kubeconfig), `curl`.

## 1. Prepare Jenkins

```bash
bash Jenkins/Lab21/setup.sh
```

The script does six things:

1. Builds `jenkins-lab21:latest` from `docker/Dockerfile`. The build context is the `Lab21` folder, because the Dockerfile copies `k8s/` into `/opt/lab21/manifests`. That is what the "Update image" stage edits when the job contains only the Jenkinsfile.
2. Replaces the `jenkins` container but keeps the `jenkins_home` volume, so the Lab 20 accounts and roles are still there.
3. Starts it on `http://localhost:8081` with `--network host` and the host's `/var/run/docker.sock`, which is what lets the pipeline call `docker build` and `docker push` without a Docker-in-Docker daemon.
4. Installs `workflow-aggregator`, `credentials-binding`, `git` and `role-strategy`.
5. Copies a **flattened** kubeconfig to `/var/jenkins_home/.kube/config`. `kubectl config view --flatten` embeds the client certificate and key, so the files under `~/.minikube` do not have to exist inside the container too. Without flattening, the deploy stage fails with a certificate error.
6. Prewarms the Trivy vulnerability database in `/var/jenkins_home/.cache/trivy` with `--timeout 60m`. The first pipeline scan would otherwise download 132 MB with a five-minute timeout and fail on a slow connection.

The first build downloads the Docker CLI, Maven, Trivy and kubectl (roughly 150 MB), so it takes a few minutes on a normal connection and longer on a slow one. The Trivy database prewarm adds another 132 MB the first time; it is skipped afterwards because the cache lives in the `jenkins_home` volume. At the end the script prints the tool versions and the cluster nodes; if kubectl cannot reach a cluster, start minikube and run the script again.

## 2. Configure the job

1. `Manage Jenkins` -> `Credentials` -> `System` -> `Global credentials` -> `Add Credentials` -> `Username with password`.
   - Username: the Docker Hub account.
   - Password: a Docker Hub access token.
   - ID: `dockerhub`.

   The ID matters: `DOCKERHUB = credentials('dockerhub')` in the Jenkinsfile expects exactly that. It exports `DOCKERHUB_USR` and `DOCKERHUB_PSW`, and Jenkins masks the password in the log.
2. `New Item` -> `Pipeline` -> name it `demoapp-pipeline`.
3. Select `Pipeline script` and paste the content of `Jenkinsfile`, then `Save`.
4. `Build Now`.

Alternatively, if the Jenkinsfile is committed to a Git repository, choose `Pipeline script from SCM` and point it at the repository. With lightweight checkout enabled, Jenkins fetches only the Jenkinsfile, so the stage uses the manifests baked into the image. Disable lightweight checkout to use the `k8s` folder from that repository instead.

## 3. The stages

| # | Stage | What happens |
|---|-------|--------------|
| 1 | `Clone source code` | `git clone --depth 1` of the DemoApp repository into `demoapp/`. The job uses `skipDefaultCheckout(true)`, so this is the only checkout. |
| 2 | `Build app` | `mvn -B -ntp -DskipTests clean package`, then the existence of `target/demo-0.0.1-SNAPSHOT.jar` is checked and the jar is archived. |
| 3 | `Build Docker image` | Builds `${DOCKERHUB_USR}/demoapp:<build>-<short-sha>` with the Dockerfile from the repository. `--pull` refreshes the base image. |
| 4 | `Scan Docker image` | Runs Trivy for `HIGH,CRITICAL` vulnerabilities, ignoring unfixed ones, and writes `trivy-report.txt`. |
| 5 | `Push image to DockerHub` | `docker login` with the credential, `docker push`, then a `trap` guarantees `docker logout` even if the push fails. |
| 6 | `Delete image locally` | `docker rmi -f` and a dangling-image prune, then the pipeline fails on purpose if the image can still be inspected. |
| 7 | `Update image in deployment file` | Copies the manifests into the workspace and rewrites the single `image:` line with `sed -E`. It asserts that exactly one line now carries the new tag. |
| 8 | `Deploy to Kubernetes cluster` | Applies the namespace first, creates/updates the `dockerhub` pull secret, applies the rest, records a change cause, waits for `rollout status`, then smoke-tests the service through `kubectl port-forward`. |

The tag is `<BUILD_NUMBER>-<git sha>`, for example `12-4f2c1ab`. It is unique per build, which makes the rollout visible in `kubectl rollout history` and makes a rollback a matter of re-applying an older tag. `latest` is never pushed.

The Trivy stage uses `--exit-code 0`: the scan is reported and archived, but known vulnerabilities in the Maven base image do not block the deployment. Changing it to `--exit-code 1` turns the stage into a policy gate; that is a better default for a real project, but it would make this lab fail on the base image's CVE list.

## 4. Post actions

| Action | Behaviour |
|--------|-----------|
| `always` | Logs out of Docker Hub, archives `trivy-report.txt` (with `allowEmptyArchive` so an early failure is fine) and prints the build result. |
| `success` | Prints the image reference, the node IP with the NodePort URL, and the pod list. |
| `failure` | Prints the local images, the pods, the deployment description and the last 20 events, which is usually enough to see whether the failure was a pull error, a crash loop or a rollout timeout. |

## 5. The Kubernetes manifests

- `namespace.yaml` creates `ivolve`.
- `deployment.yaml` runs two replicas with a `RollingUpdate` strategy (`maxUnavailable: 0`), TCP readiness and liveness probes, CPU/memory requests and limits, and `imagePullSecrets: dockerhub`.
- `service.yaml` exposes port 8080 as NodePort `30080`.

The deployment carries a control-plane toleration so it also schedules on a single-node kubeadm cluster whose control plane still has the `NoSchedule` taint.

The `image:` line starts as `DOCKERHUB_USER/demoapp:latest`; the pipeline replaces it. The namespace is applied separately because `kubectl apply -f manifests/` visits `deployment.yaml` before `namespace.yaml` alphabetically and would fail on a fresh cluster.

## 6. Verify

```bash
# the pipeline result (the instance keeps the Lab 20 security realm, so use
# an account and an API token, or read the result from the build page)
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  http://localhost:8081/job/demoapp-pipeline/lastBuild/api/json | jq '.result'

# what the cluster runs
kubectl -n ivolve get deployment demoapp -o wide
kubectl -n ivolve get pods -o wide
kubectl -n ivolve rollout history deployment/demoapp

# the application (minikube)
minikube service demoapp -n ivolve --url
curl "$(minikube service demoapp -n ivolve --url)/"
```

With k3s, the node IP is the machine's IP and the URL is `http://<node-ip>:30080/`. Both should answer `Hello from Dockerized Spring Boot!`.

## 7. Screenshots for the report

Take all screenshots from the same successful build so the build number, image
tag and pod names agree. Store them in `Jenkins/Lab21/images/` with these
names and embed each one in the section named in the last column.

| File | What to capture | README section |
|------|-----------------|----------------|
| `lab21-01-credentials.png` | `Manage Jenkins` -> `Credentials`, the `dockerhub` entry with the token hidden | 2 |
| `lab21-02-job-config.png` | The pipeline job configuration (script or SCM) | 2 |
| `lab21-03-stage-view.png` | The stage view with all eight stages green | 3 |
| `lab21-04-build-app.png` | Console: Maven `BUILD SUCCESS` and the produced jar | 3 |
| `lab21-05-docker-build.png` | Console: `docker build` and `docker image inspect` | 3 |
| `lab21-06-trivy.png` | Console: Trivy table for `HIGH,CRITICAL` | 3 |
| `lab21-07-dockerhub.png` | The Docker Hub repository page with the `<build>-<sha>` tag | 3 |
| `lab21-08-image-deleted.png` | Console: `image ... removed from the local daemon` | 3 |
| `lab21-09-manifest-update.png` | Console: the rewritten `image:` line | 3 |
| `lab21-10-kubectl.png` | `kubectl get deploy,pods,svc -o wide` with both pods ready | 3 and 5 |
| `lab21-11-app.png` | Browser at the NodePort URL showing `Hello from Dockerized Spring Boot!` | 6 |
| `lab21-12-post-actions.png` | Console end: the success message with the image and URL | 4 |
| `lab21-13-failure-post.png` | Optional: a failed build, to show the `failure` diagnostics | 4 |
| `lab21-14-rollout-history.png` | Optional: `kubectl rollout history deployment/demoapp` | 6 |

Tips:

- Crop to the relevant panel, but keep the build number and stage name visible.
- Hide the Docker Hub token; the account name is fine.
- For the Docker Hub screenshot, make sure the tag on the page is the exact tag from that build, not `latest`.
- Use the same browser window size and zoom for all screenshots.

## Problems and notes

- **The Jenkins container needs the Docker socket.** The stock container from Lab 20 mounts only `jenkins_home`, so `docker build` fails with `Cannot connect to the Docker daemon at unix:///var/run/docker.sock`. `setup.sh` starts the new container with `-v /var/run/docker.sock:/var/run/docker.sock` and `--group-add "$(stat -c '%g' /var/run/docker.sock)"`; the mount makes the socket exist and the group makes it writable by the `jenkins` user. Both are required.
- **The credential ID must match the Jenkinsfile.** This pipeline expects `dockerhub`. A job that was configured earlier against `DOCKERHUB_CREDENTIALS` has to either create the `dockerhub` credential or change the `credentials('dockerhub')` line; otherwise the pipeline fails before the first stage.
- **Maven is not installed from apt.** Debian's `maven` package depends on `default-jdk-headless`, which would pull a second JDK even though the Jenkins image already ships JDK 17. The Dockerfile installs Maven from its Apache tarball instead, which also pins the Maven version.
- **The Dockerfile needs the Lab21 folder as build context.** With `docker build docker/`, `COPY manifests` finds no such folder in the context. The context is the parent folder and the Dockerfile copies `k8s/` into the image.
- **A kubeconfig is not always self-contained.** minikube writes paths to `~/.minikube/profiles/.../client.crt` and `client.key`. Copying only `config` into the container therefore breaks TLS. `kubectl config view --flatten --minify` produces one file with the certificates embedded.
- **A NodePort is not reachable from every environment.** The smoke test uses `kubectl port-forward svc/demoapp` instead of calling `<node-ip>:30080`, so it works with minikube's container network as well as k3s.
- **The scan can be a gate or a report.** `--exit-code 0` keeps the lab reproducible; `--exit-code 1` is the stricter production choice. `--ignore-unfixed` avoids failing on vulnerabilities that have no patch yet.
- **Trivy needs a higher timeout than the default.** The first scan downloads a 132 MB vulnerability database and then analyzes a ~700 MB image; both steps exceed Trivy's default five-minute limit on a slow machine. The symptoms are `failed to download vulnerability DB: context deadline exceeded` or `walk dir error: context deadline exceeded`, and Trivy itself prints `Provide a higher timeout value`. The stage passes `--timeout 30m`, and the database is cached in `~/.cache/trivy` inside the `jenkins_home` volume (about 3 GB once the vulnerability and Java databases are unpacked), so only the first build pays the download. To prewarm it outside a build:
  ```bash
  docker exec jenkins trivy image --download-db-only --timeout 60m
  docker exec jenkins trivy image --download-java-db-only --timeout 60m
  ```
- **Credentials in commands.** `kubectl create secret docker-registry` passes the token on the command line. Inside a single-purpose Jenkins container that is acceptable, and Jenkins masks the value in the console log, but a production pipeline would build the secret from files and delete it afterwards.
- **Public versus private Docker Hub.** The pull secret is harmless for a public repository and required for a private one. It is refreshed on every build, so a rotated token does not leave the cluster with a stale secret.
- **Local image deletion is intentional.** Because the cluster pulls from Docker Hub, the Jenkins machine does not need to keep the image. Keeping it would also make a later `docker build` reuse a stale layer and hide a broken push.

## Cleanup

Remove the Kubernetes objects:

```bash
kubectl delete -f Jenkins/Lab21/k8s/ --ignore-not-found
```

Stop Jenkins:

```bash
docker stop jenkins
```

Remove Jenkins and its state (this also removes the Lab 20 users and roles):

```bash
docker rm -f jenkins
docker volume rm jenkins_home
```

Remove the locally built Jenkins image:

```bash
docker rmi jenkins-lab21:latest
```

## Summary

- `Jenkinsfile` implements the eight required steps as separate stages.
- The image is tagged with the build number and the commit SHA, scanned with Trivy, pushed to Docker Hub and removed from the Jenkins machine.
- The deployment manifest is updated in the workspace and applied to the `ivolve` namespace, with a rollout check and a smoke test.
- `always`, `success` and `failure` post actions handle cleanup, the final URL and diagnostics.
- `setup.sh` builds a Jenkins image with everything the pipeline needs and carries the kubeconfig and manifests into it.
