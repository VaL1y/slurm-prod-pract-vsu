# Multi-stage Dockerfile for Slurm runtime
# Stage 1: Build gosu from source with latest Go (avoids CVEs in pre-built binaries)
# Stage 2: Build RPMs using the builder image
# Stage 3: Install RPMs in a clean runtime image

ARG SLURM_VERSION
ARG GOSU_VERSION=1.19
ARG BUILDER_BASE=rockylinux/rockylinux:9
ARG RUNTIME_BASE=rockylinux/rockylinux:9

# ============================================================================
# Stage 1: Build gosu from source
# (pre-built binaries use an old Go version that triggers CVEs)
# https://github.com/tianon/gosu/issues/136
# ============================================================================
FROM golang:1.26-bookworm AS gosu-builder

ARG GOSU_VERSION
ARG TARGETOS
ARG TARGETARCH

RUN set -ex \
    && git clone --branch ${GOSU_VERSION} --depth 1 \
       https://github.com/tianon/gosu.git /go/src/github.com/tianon/gosu \
    && cd /go/src/github.com/tianon/gosu \
    && go mod download \
    && CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
       go build -v -trimpath -ldflags '-d -w' \
       -o /go/bin/gosu . \
    && chmod +x /go/bin/gosu

# ============================================================================
# Stage 2: Build RPMs
# ============================================================================
FROM ${BUILDER_BASE} AS builder

ARG SLURM_VERSION
ARG TARGETARCH

# Enable CRB and EPEL repositories for development packages
# Install RPM build tools and dependencies
RUN set -ex \
    && dnf makecache \
    && dnf -y install dnf-plugins-core epel-release \
    && dnf config-manager --set-enabled crb \
    && dnf makecache \
    && dnf -y install --nobest --exclude='*.i686' \
       autoconf \
       automake \
       bzip2 \
       freeipmi-devel \
       dbus-devel \
       gcc \
       gcc-c++ \
       git \
       gtk2-devel \
       hdf5-devel \
       http-parser-devel \
       hwloc-devel \
       json-c-devel \
       libcurl-devel \
       libyaml-devel \
       lua-devel \
       lz4-devel \
       make \
       man2html \
       mariadb-devel \
       munge \
       munge-devel \
       ncurses-devel \
       numactl-devel \
       openssl-devel \
       pam-devel \
       perl \
       python3.12 \
       python3.12-devel \
       readline-devel \
       rpm-build \
       rpmdevtools \
       rrdtool-devel \
       wget \
       libjwt \
       libjwt-devel \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# Setup RPM build environment
RUN rpmdev-setuptree

# Copy RPM macros
COPY rpmbuild/slurm.rpmmacros /root/.rpmmacros

# Download official Slurm release tarball and build RPMs with slurmrestd enabled
# Architecture mapping: Docker TARGETARCH (amd64, arm64) -> RPM arch (x86_64, aarch64)
RUN set -ex \
    && RPM_ARCH=$(case "${TARGETARCH}" in \
         amd64) echo "x86_64" ;; \
         arm64) echo "aarch64" ;; \
         *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
       esac) \
    && echo "Building Slurm RPMs for architecture: ${RPM_ARCH}" \
    && wget -O /root/rpmbuild/SOURCES/slurm-${SLURM_VERSION}.tar.bz2 \
       https://download.schedmd.com/slurm/slurm-${SLURM_VERSION}.tar.bz2 \
    && cd /root/rpmbuild/SOURCES \
    && rpmbuild -ta slurm-${SLURM_VERSION}.tar.bz2 \
    && ls -lh /root/rpmbuild/RPMS/${RPM_ARCH}/

# ============================================================================
# Stage 3: Runtime image
FROM ${RUNTIME_BASE}

LABEL org.opencontainers.image.source="https://github.com/VaL1y/slurm-prod-pract-vsu" \
      org.opencontainers.image.title="slurm-docker-cluster" \
      org.opencontainers.image.description="Slurm Docker cluster on Rocky Linux 9" \
      org.opencontainers.image.licenses="MIT"

ARG SLURM_VERSION
ARG TARGETARCH

# Enable CRB and EPEL repositories, then install runtime dependencies
RUN set -ex \
    && dnf -y update \
    && dnf -y install dnf-plugins-core epel-release \
    && dnf config-manager --set-enabled crb \
    && dnf makecache \
    && dnf -y install \
       bash-completion \
       bzip2 \
       bzip2-devel \
       file \
       gcc \
       gcc-c++ \
       gettext \
       git \
       hdf5 \
       http-parser \
       hwloc \
       json-c \
       jq \
       libaec \
       libyaml \
       lua \
       lua-posix \
       lua-filesystem \
       lz4 \
       make \
       mariadb \
       munge \
       numactl \
       patch \
       perl \
       procps-ng \
       psmisc \
       python3.12 \
       readline \
       tcl \
       vim-enhanced \
       wget \
       xz \
       libjwt \
    && dnf clean all \
    && rm -rf /var/cache/dnf \
    && alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 \
    && alternatives --set python3 /usr/bin/python3.12

# Install gosu
COPY --from=gosu-builder /go/bin/gosu /usr/local/bin/gosu
RUN gosu --version && gosu nobody true

COPY --from=builder /root/rpmbuild/RPMS/*/*.rpm /tmp/rpms/

# Install Slurm RPMs
RUN set -ex \
    && dnf -y install /tmp/rpms/slurm-[0-9]*.rpm \
       /tmp/rpms/slurm-slurmctld-*.rpm \
       /tmp/rpms/slurm-slurmd-*.rpm \
       /tmp/rpms/slurm-slurmdbd-*.rpm \
    && rm -rf /tmp/rpms \
    && dnf clean all

# Create users, generate munge key, and set up directories
RUN set -x \
    && groupadd -r --gid=990 slurm \
    && useradd -r -g slurm --uid=990 slurm \
    && chmod 0755 /etc \
    && /sbin/create-munge-key \
    && mkdir -m 0755 -p \
        /var/run/slurm \
        /var/spool/slurm \
        /var/lib/slurm \
        /var/log/slurm \
        /etc/slurm \
    && chown slurm:slurm \
        /var/run/slurm \
        /var/spool/slurm \
        /var/lib/slurm \
        /var/log/slurm \
        /etc/slurm

# Seed configuration volumes on first use.
COPY --chown=slurm:slurm config/slurm.conf /etc/slurm/slurm.conf
COPY --chown=slurm:slurm --chmod=0600 config/slurmdbd.conf /etc/slurm/slurmdbd.conf

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["slurmdbd"]
