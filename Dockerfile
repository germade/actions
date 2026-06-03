FROM ubuntu:24.04

ARG ACT_VERSION=0.2.82
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        docker.io \
        git \
    && rm -rf /var/lib/apt/lists/* \
    && case "$TARGETARCH" in \
        amd64) act_arch='x86_64' ;; \
        arm64) act_arch='arm64' ;; \
        *) echo "Unsupported TARGETARCH: $TARGETARCH" >&2; exit 1 ;; \
      esac \
    && curl -fsSL "https://github.com/nektos/act/releases/download/v${ACT_VERSION}/act_Linux_${act_arch}.tar.gz" \
      | tar -xz -C /usr/local/bin act \
    && act --version \
    && docker --version

# Usage:
#   docker build -t germade-actions-tests .
#   docker run --rm \
#     -v /var/run/docker.sock:/var/run/docker.sock \
#     -v "$PWD":"$PWD" \
#     -w "$PWD" \
#     germade-actions-tests
#
# The repository mount should keep the host path unchanged because act asks the
# Docker daemon to bind-mount the workspace into job containers.

ENTRYPOINT ["act"]
CMD ["workflow_dispatch", "-W", ".github/workflows/test-actions.yml", "-P", "ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest"]