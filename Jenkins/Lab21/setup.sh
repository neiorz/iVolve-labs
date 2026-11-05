#!/usr/bin/env bash
# Lab 21 - prepares Jenkins for the pipeline lab.
#
# What it does:
#   1. builds a Jenkins image with maven, docker CLI, kubectl, trivy and the
#      Kubernetes manifests baked in (/opt/lab21/manifests)
#   2. replaces the "jenkins" container, keeping the jenkins_home volume, so
#      the users and roles from lab 20 are still there
#   3. exposes it on http://localhost:8081 and lets it use the host docker
#   4. installs the pipeline, credentials and git plugins
#   5. copies a flattened kubeconfig into the container for the deploy stage
#
# Run from anywhere:  bash Jenkins/Lab21/setup.sh
set -euo pipefail

NAME=jenkins
IMAGE=jenkins-lab21:latest
PORT=8081
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

say() { printf '\n==> %s\n' "$1"; }

# ---------------------------------------------------------------- docker ----
command -v docker >/dev/null 2>&1 || {
  echo "Docker is not installed." >&2
  exit 1
}

if docker info >/dev/null 2>&1; then
  DOCKER=(docker)
elif sudo docker info >/dev/null 2>&1; then
  DOCKER=(sudo docker)
else
  echo "The Docker daemon is not reachable. Start it and retry." >&2
  exit 1
fi
docker_cmd() { "${DOCKER[@]}" "$@"; }

[ "$(uname -s)" = "Linux" ] || {
  echo "This script uses --network host, which is Linux only." >&2
  exit 1
}

if ss -ltn "( sport = :$PORT )" 2>/dev/null | grep -q LISTEN; then
  if ! docker_cmd ps --format '{{.Names}}' | grep -qx "$NAME"; then
    echo "Port $PORT is already in use by another process." >&2
    exit 1
  fi
fi

# ----------------------------------------------------------------- image ----
# The context is the Lab21 folder, not docker/, because the Dockerfile copies
# k8s/ into /opt/lab21/manifests.
say "building the Jenkins image (first run takes a few minutes)"
docker_cmd build -f "$ROOT/docker/Dockerfile" -t "$IMAGE" "$ROOT"

# --------------------------------------------------------------- replace ----
say "replacing the $NAME container (the jenkins_home volume is kept)"
docker_cmd rm -f "$NAME" >/dev/null 2>&1 || true

SOCK=/var/run/docker.sock
[ -S "$SOCK" ] || {
  echo "$SOCK was not found. Is Docker running with the default socket?" >&2
  exit 1
}

docker_cmd run -d --name "$NAME" \
  --network host \
  -v jenkins_home:/var/jenkins_home \
  -v "$SOCK:$SOCK" \
  --group-add "$(stat -c '%g' "$SOCK")" \
  -e JENKINS_OPTS="--httpPort=$PORT" \
  --restart unless-stopped \
  "$IMAGE" >/dev/null

wait_http() {
  for _ in $(seq 1 90); do
    if curl -s -o /dev/null -w '%{http_code}' "http://localhost:$PORT/login" 2>/dev/null | grep -q '^200$'; then
      return 0
    fi
    sleep 4
  done
  return 1
}

say "waiting for Jenkins on http://localhost:$PORT"
wait_http || { echo "Jenkins did not start. Check: docker logs $NAME" >&2; exit 1; }

# --------------------------------------------------------------- plugins ----
say "installing the pipeline and credentials plugins"
docker_cmd exec "$NAME" jenkins-plugin-cli --plugins \
  workflow-aggregator credentials-binding git role-strategy

say "restarting Jenkins"
docker_cmd restart "$NAME" >/dev/null
wait_http || { echo "Jenkins did not come back after the restart" >&2; exit 1; }

# ------------------------------------------------------------- kubeconfig ----
HOST_HOME=$HOME
if [ -n "${SUDO_USER:-}" ]; then
  HOST_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
fi

if [ -f "$HOST_HOME/.kube/config" ] && command -v kubectl >/dev/null 2>&1; then
  say "copying a self-contained kubeconfig into the container"
  # --flatten embeds the client certificate and key, so the minikube files
  # under ~/.minikube do not have to exist inside the container as well.
  tmp_kube=$(mktemp)
  kubectl config view --flatten --minify >"$tmp_kube"

  docker_cmd exec -u root "$NAME" mkdir -p /var/jenkins_home/.kube
  docker_cmd cp "$tmp_kube" "$NAME:/var/jenkins_home/.kube/config"
  docker_cmd exec -u root "$NAME" chown -R jenkins:jenkins /var/jenkins_home/.kube
  docker_cmd exec -u root "$NAME" chmod 600 /var/jenkins_home/.kube/config
  rm -f "$tmp_kube"
elif [ -f "$HOST_HOME/.kube/config" ]; then
  say "copying the kubeconfig into the container (kubectl not found, not flattened)"
  docker_cmd exec "$NAME" mkdir -p /var/jenkins_home/.kube
  docker_cmd cp "$HOST_HOME/.kube/config" "$NAME:/var/jenkins_home/.kube/config"
  docker_cmd exec -u root "$NAME" chown -R jenkins:jenkins /var/jenkins_home/.kube
else
  echo
  echo "No $HOST_HOME/.kube/config found, so the deploy stage has no cluster yet."
  echo "Install a single-node k3s and re-run this script, or copy a kubeconfig in:"
  echo
  echo "  curl -sfL https://get.k3s.io | sh -"
  echo "  mkdir -p ~/.kube"
  echo "  sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config"
  echo "  sudo chown \$USER ~/.kube/config"
fi

# ------------------------------------------------------------------ trivy ----
# The first scan otherwise downloads a 132 MB database with a five-minute
# timeout. Doing it here, with a long timeout, keeps that out of the build.
say "prewarming the Trivy vulnerability database (132 MB, skipped when cached)"
if ! docker_cmd exec "$NAME" trivy image --download-db-only --timeout 60m; then
  echo "warning: the Trivy database download failed; the first scan will retry it"
fi
docker_cmd exec "$NAME" trivy image --download-java-db-only --timeout 60m || true

# ------------------------------------------------------------------ check ----
say "checking the tools inside the container"
docker_cmd exec "$NAME" docker version --format 'docker server: {{.Server.Version}}'
docker_cmd exec "$NAME" mvn -version | awk 'NR==1'
docker_cmd exec "$NAME" kubectl version --client | awk 'NR==1'
docker_cmd exec "$NAME" trivy --version | awk 'NR==1'
if docker_cmd exec "$NAME" test -d /opt/lab21/manifests; then
  echo "manifests: /opt/lab21/manifests"
fi

if docker_cmd exec "$NAME" kubectl cluster-info >/dev/null 2>&1; then
  docker_cmd exec "$NAME" kubectl get nodes
else
  echo
  echo "kubectl inside the container cannot reach a cluster yet."
  echo "For minikube, start it and re-run this script:  minikube start"
fi

cat <<INFO

Jenkins is ready at http://localhost:$PORT

Still to do by hand:
  1. Manage Jenkins -> Credentials -> System -> Global credentials
     -> Add Credentials -> Username with password
        Username : your Docker Hub account
        Password : a Docker Hub access token
        ID       : dockerhub
  2. New Item -> Pipeline -> name it demoapp-pipeline
     -> Pipeline script -> paste Jenkins/Lab21/Jenkinsfile -> Save
  3. Open the job and press "Build Now".

If the Docker Hub repository is public, the imagePullSecrets entry in
k8s/deployment.yaml is simply unused; it does not break the deployment.

INFO
