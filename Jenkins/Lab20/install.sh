#!/usr/bin/env bash
# Lab 20 - Jenkins for the role-based authorization lab.
#
# Runs Jenkins as a Docker container on http://localhost:8080 with the
# role-strategy plugin already installed. Nothing is installed on the host
# except the container image and a named volume.
#
#   bash install.sh              reuse the existing jenkins_home volume
#   bash install.sh --fresh      wipe the volume and start from the wizard
#
# Environment overrides:
#   JENKINS_PORT=8081 bash install.sh
#   JENKINS_NAME=jenkins2 bash install.sh
set -euo pipefail

NAME=${JENKINS_NAME:-jenkins}
PORT=${JENKINS_PORT:-8080}
AGENT_PORT=${JENKINS_AGENT_PORT:-50000}
IMAGE=${JENKINS_IMAGE:-jenkins/jenkins:lts-jdk17}
VOLUME=${JENKINS_VOLUME:-jenkins_home}
FRESH=${1:-}

# ---------------------------------------------------------------- docker ----
if ! command -v docker >/dev/null 2>&1; then
  cat <<MSG
Docker was not found on this machine.

Install Docker Engine first:

  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "\$USER" && newgrp docker

or install Docker Desktop, then run this script again.
MSG
  exit 1
fi

if docker info >/dev/null 2>&1; then
  DOCKER=(docker)
elif sudo docker info >/dev/null 2>&1; then
  DOCKER=(sudo docker)
else
  echo "Docker is installed but the daemon is not reachable. Start it and retry." >&2
  exit 1
fi

docker_cmd() { "${DOCKER[@]}" "$@"; }

# ------------------------------------------------------------------ port ----
if command -v ss >/dev/null 2>&1 && ss -ltn "( sport = :$PORT )" 2>/dev/null | grep -q LISTEN; then
  echo "Port $PORT is already in use. Retry with: JENKINS_PORT=8081 bash $0" >&2
  exit 1
fi

# ----------------------------------------------------------------- reset ----
if [ "$FRESH" = "--fresh" ]; then
  echo "==> removing the old container and volume"
  docker_cmd rm -f "$NAME" >/dev/null 2>&1 || true
  docker_cmd volume rm "$VOLUME" >/dev/null 2>&1 || true
fi

docker_cmd rm -f "$NAME" >/dev/null 2>&1 || true

# ------------------------------------------------------------------ run -----
echo "==> starting $NAME on port $PORT"
docker_cmd run -d --name "$NAME" \
  -p "$PORT:8080" \
  -p "$AGENT_PORT:50000" \
  -v "$VOLUME:/var/jenkins_home" \
  --restart unless-stopped \
  "$IMAGE" >/dev/null

wait_http() {
  local tries=${1:-90}
  for _ in $(seq 1 "$tries"); do
    if curl -s -o /dev/null -w '%{http_code}' "http://localhost:$PORT/login" 2>/dev/null | grep -q '^200$'; then
      return 0
    fi
    sleep 4
  done
  return 1
}

echo "==> waiting for the web interface (first start takes 1-2 minutes)"
wait_http || { echo "Jenkins did not come up; check: docker logs $NAME" >&2; exit 1; }

# ---------------------------------------------------------------- plugin ----
echo "==> installing the role-strategy plugin"
docker_cmd exec "$NAME" jenkins-plugin-cli --plugins role-strategy

echo "==> restarting jenkins"
docker_cmd restart "$NAME" >/dev/null
wait_http || { echo "Jenkins did not come back after the restart" >&2; exit 1; }

# ----------------------------------------------------------------- info -----
cat <<INFO

Jenkins is ready.

  URL          : http://localhost:$PORT
  Container    : $NAME
  Volume       : $VOLUME  (/var/jenkins_home)
  Plugin       : role-strategy
  Host installs: none

INFO

if docker_cmd exec "$NAME" test -f /var/jenkins_home/secrets/initialAdminPassword; then
  echo "  Initial admin password:"
  docker_cmd exec "$NAME" cat /var/jenkins_home/secrets/initialAdminPassword
else
  echo "  The initial setup is already done, log in with the admin account"
  echo "  you created earlier (or rerun with --fresh to start over)."
fi

cat <<INFO

Lab credentials used in the screenshots:

  admin   / AdminPass123
  user1   / User1Pass123   (admin role)
  user2   / User2Pass123   (read-only role)

Resource footprint: about 500 MB RAM idle, roughly 1.5 GB during the
initial plugin installation. Nothing is installed on the host.

Stop it with:     docker stop $NAME
Remove it fully:  docker rm -f $NAME && docker volume rm $VOLUME

INFO
