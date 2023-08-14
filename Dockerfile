# syntax=docker/dockerfile:1.4
FROM golang:1.21-bullseye AS golang-builder

ARG PACKAGE=wait-for-port
ARG TARGET_DIR=common
# renovate: datasource=github-releases depName=bitnami/wait-for-port extractVersion=^v(?<version>\d+\.\d+.\d+)
ARG BUILD_VERSION=1.0.6
ARG REF=v${BUILD_VERSION}
ARG CGO_ENABLED=0

RUN --mount=type=cache,target=/root/.cache/go-build <<EOT /bin/bash
    set -ex
    apt-get update && apt-get install -y --no-install-recommends git binutils

    rm -rf ${PACKAGE} || true
    mkdir -p ${PACKAGE}
    git clone -b "${REF}" https://github.com/bitnami/wait-for-port.git ${PACKAGE}

    pushd ${PACKAGE}
    go mod download
    go build -v -ldflags '-d -s -w' .
    mkdir -p /opt/bitnami/${TARGET_DIR}/licenses
    mkdir -p /opt/bitnami/${TARGET_DIR}/bin
    cp -f LICENSE.md /opt/bitnami/${TARGET_DIR}/licenses/${PACKAGE}-${BUILD_VERSION}.md
    cp -f ${PACKAGE} /opt/bitnami/${TARGET_DIR}/bin/${PACKAGE}
    popd

    strip --strip-all /opt/bitnami/common/bin/* || true
EOT

FROM bitnami/minideb:bullseye as stage-0

COPY --link --from=golang-builder /opt/bitnami /opt/bitnami
ENTRYPOINT ["/opt/bitnami/common/bin/wait-for-port"]
