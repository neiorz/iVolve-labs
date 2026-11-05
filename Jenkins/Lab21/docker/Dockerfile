# Jenkins image for Lab 21.
#
# The stock jenkins/jenkins image has no Maven, no Docker CLI, no kubectl and
# no Trivy, which are exactly the tools the pipeline needs. This image adds
# them and bakes the Kubernetes manifests under /opt/lab21/manifests, so a
# job created with "Pipeline script" only needs the Jenkinsfile itself.
#
# Built by setup.sh. The build context is the Lab21 directory (not this
# folder), because the Dockerfile copies ../k8s into the image:
#
#   docker build -f docker/Dockerfile -t jenkins-lab21:latest .

FROM jenkins/jenkins:lts-jdk17

# Pin the tools that are downloaded from the internet. Bump the versions here
# when a newer release is wanted; the build stays reproducible.
ARG MAVEN_VERSION=3.9.9
ARG TRIVY_VERSION=0.76.1
ARG KUBERNETES_MINOR=v1.37

USER root

# The Docker CLI and kubectl come from their apt repositories: the packages
# are much smaller than the static binaries, and apt retries slow downloads.
# Maven comes from its own tarball below, because Debian's maven package would
# pull a second full JDK even though the Jenkins image already ships JDK 17.
RUN export DEBIAN_FRONTEND=noninteractive \
 && install -d /etc/apt/keyrings \
 && curl -fsSL --retry 5 --retry-all-errors \
      https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list \
 && curl -fsSL --retry 5 --retry-all-errors \
      "https://pkgs.k8s.io/core:/stable:/${KUBERNETES_MINOR}/deb/Release.key" \
      -o /etc/apt/keyrings/kubernetes.asc \
 && echo "deb [signed-by=/etc/apt/keyrings/kubernetes.asc] https://pkgs.k8s.io/core:/stable:/${KUBERNETES_MINOR}/deb/ /" > /etc/apt/sources.list.d/kubernetes.list \
 && apt-get -o Acquire::Retries=5 update \
 && apt-get -o Acquire::Retries=5 install -y --no-install-recommends \
      docker-ce-cli \
      kubectl \
 && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    curl -fsSL --retry 10 --retry-all-errors --retry-delay 5 \
      "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
      | tar -xz -C /opt; \
    ln -s "/opt/apache-maven-${MAVEN_VERSION}/bin/mvn" /usr/local/bin/mvn

# Trivy ships amd64 as "64bit" and arm64 as "ARM64".
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) trivy_arch=64bit ;; \
      arm64) trivy_arch=ARM64 ;; \
      *) echo "unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    curl -fsSL --retry 10 --retry-all-errors --retry-delay 5 \
      "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-${trivy_arch}.tar.gz" \
      | tar -xz -C /usr/local/bin trivy

# The Deployment, Service and Namespace the last pipeline stage applies.
COPY k8s/ /opt/lab21/manifests
RUN chown -R jenkins:jenkins /opt/lab21

USER jenkins

RUN mvn -version \
 && kubectl version --client \
 && trivy --version \
 && docker --version
