ARG REPO_BUILD_TAG
ARG UBUNTU_VERSION="22.04"
ARG GOLANG_VERSION="1.24.11"
ARG CBDB_DOWNLOAD_URL="https://github.com/apache/cloudberry"
ARG CBDB_VERSION="2.1.0-incubating-rc2"
ARG PXF_DOWNLOAD_URL="https://github.com/apache/cloudberry-pxf"
ARG PXF_VERSION="2.1.0-incubating-rc2"
ARG CBDB_BACKUP_DOWNLOAD_URL="https://github.com/apache/cloudberry-backup"
ARG CBDB_BACKUP_VERSION="ff44dc65e1f19bd08e819d6a5770434e1bf418f1"
ARG WALG_DOWNLOAD_URL="https://github.com/wal-g/wal-g"
# Wait new WAL-G release
ARG WALG_VERSION="4b33c88939ce0cc23acc5f89dcf5e427c50923d9"

FROM ubuntu:${UBUNTU_VERSION} AS builder

ARG CBDB_DOWNLOAD_URL
ARG CBDB_VERSION

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        bison \
        cmake \
        curl \
        flex \
        gcc \
        g++ \
        git \
        inetutils-ping \
        binutils \
        krb5-kdc \
        krb5-admin-server \
        libapr1-dev \
        libaprutil1-dev \
        libbz2-dev \
        libcurl4-gnutls-dev \
        libevent-dev \
        libkrb5-dev \
        libpam-dev \
        libperl-dev \
        libreadline-dev \
        libssl-dev \
        libuv1-dev \
        libxml2-dev \
        libyaml-dev \
        libzstd-dev \
        zlib1g-dev \
        libldap-dev \
        libossp-uuid-dev \
        liblz4-dev \
        libprotobuf-dev \
        protobuf-compiler \
        liburing-dev \
        libxerces-c-dev \
        locales \
        net-tools \
        openssh-client \
        openssh-server \
        openssl \
        python3 \
        python3-dev \
        python3-pip \
        python3-psutil \
        python3-pygresql \
        python3-psycopg2 \
        python3-setuptools \
        python3-yaml \
        pkg-config \
        sudo \
        openjdk-11-jdk \
        libbrotli-dev \
        libsodium-dev \
        libsqlite3-dev \
        wget \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && echo -e "/usr/local/lib\n/usr/local/lib64\n" >> /etc/ld.so.conf.d/local.conf \
    && ldconfig

# cloudberry
RUN git clone --recurse-submodules --depth 1 --branch ${CBDB_VERSION} ${CBDB_DOWNLOAD_URL} /tmp/cloudberry \
    && cd /tmp/cloudberry \
    && ./configure --prefix=/usr/local/cloudberry-db \
        --disable-external-fts \
        --enable-gpcloud \
        --enable-ic-proxy \
        --enable-mapreduce \
        --enable-orafce \
        --enable-orca \
        --enable-pax \
        --disable-pxf \
        --with-gssapi \
        --with-ldap \
        --with-libxml \
        --with-lz4 \
        --with-pam \
        --with-perl \
        --with-python \
        --with-pythonsrc-ext \
        --with-ssl=openssl \
        --with-uuid=e2fs \
        --enable-gpfdist \
    && make -j2 \
    && make install \
    && make -C contrib install \
    # && make -C gpcontrib/diskquota install \
    && rm -rf /tmp/cloudberry

FROM builder AS go_builder
ARG GOLANG_VERSION
ARG CBDB_BACKUP_DOWNLOAD_URL
ARG CBDB_BACKUP_VERSION
ARG PXF_DOWNLOAD_URL
ARG PXF_VERSION
ARG WALG_DOWNLOAD_URL
ARG WALG_VERSION

RUN mkdir -p /opt/go \
    && wget https://go.dev/dl/go${GOLANG_VERSION}.linux-$(dpkg --print-architecture).tar.gz \
    && tar -xvf go${GOLANG_VERSION}.linux-$(dpkg --print-architecture).tar.gz -C /usr/local

ENV PATH="$PATH:/usr/local/go/bin"
ENV GOPATH=/opt/go

# cloudberry-backup (gpbackup, gprestore, gpbackup_helper, gpbackup_s3_plugin)
RUN git clone ${CBDB_BACKUP_DOWNLOAD_URL} /tmp/cloudberry-backup \
    && cd /tmp/cloudberry-backup \
    && git checkout ${CBDB_BACKUP_VERSION} \
    && make depend \
    && make build GIT_VERSION=${CBDB_BACKUP_VERSION} \
    && rm -rf /tmp/cloudberry-backup

# wal-g
# Don't use USE_LZO=1, there is no need to build with WAL-E compatibility
# See https://github.com/wal-g/wal-g/issues/1412#issuecomment-1401890162
RUN git clone ${WALG_DOWNLOAD_URL} /tmp/wal-g \
    && cd /tmp/wal-g \
    && git checkout ${WALG_VERSION} \
    && USE_BROTLI=1 \
       USE_LIBSODIUM=1 \
       make deps \
    && USE_BROTLI=1 \
       USE_LIBSODIUM=1 \
       make gp_build

# cloudberry-pxf
# Build pxf without tests
# Components: external-table, fdw, cli, servers
ENV PATH="/usr/local/cloudberry-db/bin:${PATH}"

RUN git clone ${PXF_DOWNLOAD_URL} /tmp/cloudberry-pxf \
    && cd /tmp/cloudberry-pxf \
    && git checkout ${PXF_VERSION} \
    && PXF_HOME=/usr/local/pxf \
       make -j2 -C external-table install \
    && PXF_HOME=/usr/local/pxf \
       make -j2 -C fdw install \
    && PXF_HOME=/usr/local/pxf \
       make -j2 -C cli install \
    && PXF_HOME=/usr/local/pxf \
       make -j2 -C server install-server \
    && rm -rf /tmp/cloudberry-pxf

FROM ubuntu:${UBUNTU_VERSION} AS final

ARG REPO_BUILD_TAG
ARG CBDB_VERSION

ENV TZ="Etc/UTC" \
    CLOUDBERRY_USER="gpadmin" \
    CLOUDBERRY_UID=1001 \
    CLOUDBERRY_GROUP="gpadmin" \
    CLOUDBERRY_GID=1001 \
    CLOUDBERRY_DEPLOYMENT="singlenode" \
    CLOUDBERRY_DATA_DIRECTORY="/data" \
    CLOUDBERRY_SEG_PREFIX="gpseg" \
    CLOUDBERRY_DATABASE_NAME="demo" \
    CLOUDBERRY_DISKQUOTA_ENABLE="false" \
    CLOUDBERRY_PXF_ENABLE="false" \
    CLOUDBERRY_WALG_ENABLE="false"

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        libbz2-1.0 \
        libcurl3-gnutls \
        libcurl4 \
        libevent-2.1-7 \
        libkrb5-3 \
        libpam0g \
        libreadline8 \
        libssl3 \
        libuv1 \
        libxml2 \
        libyaml-0-2 \
        libzstd1 \
        zlib1g \
        libldap-2.5-0 \
        liblz4-1 \
        libprotobuf23 \
        liburing2 \
        libxerces-c3.2 \
        inetutils-ping \
        krb5-kdc \
        krb5-admin-server \
        uuid-runtime \
        openssh-client \
        openssh-server \
        openssl \
        binutils \
        perl \
        rsync \
        curl \
        sed \
        tar \
        zip \
        net-tools \
        less \
        locales \
        iproute2 \
        python3 \
        python3-psutil \
        python3-pygresql \
        python3-psycopg2 \
        python3-setuptools \
        python3-yaml \
        gosu \
        ca-certificates \
        tzdata \
        openjdk-11-jre \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid ${CLOUDBERRY_GID} ${CLOUDBERRY_GROUP} \
    && useradd --shell /bin/bash --uid ${CLOUDBERRY_UID} --gid ${CLOUDBERRY_GID} -m ${CLOUDBERRY_USER} \
    && locale-gen en_US.UTF-8 \
    && mkdir -m 700 -p /home/${CLOUDBERRY_USER}/.ssh \
    && ssh-keygen -f /home/${CLOUDBERRY_USER}/.ssh/id_rsa -t rsa -N "" \
    && echo "HostKeyAlgorithms +ssh-rsa" >> /etc/ssh/sshd_config \
    && echo "PubkeyAcceptedKeyTypes +ssh-rsa" >> /etc/ssh/sshd_config \
    && echo "${CLOUDBERRY_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && echo "source /usr/local/cloudberry-db/cloudberry-env.sh" > /home/${CLOUDBERRY_USER}/.bashrc \
    && ARCH=$(dpkg --print-architecture) \
    && case "${ARCH}" in \
        arm64) echo "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64" >> /home/${CLOUDBERRY_USER}/.bashrc ;; \
        amd64) echo "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64" >> /home/${CLOUDBERRY_USER}/.bashrc ;; \
        *) echo >&2 "error: unknown/unsupported architecture '${ARCH}'"; exit 1 ;; \
    esac \
    && echo 'export PATH="/usr/local/pxf/bin:${PATH}"' >> /home/${CLOUDBERRY_USER}/.bashrc \
    && echo "export PXF_BASE=${CLOUDBERRY_DATA_DIRECTORY}/pxf" >> /home/${CLOUDBERRY_USER}/.bashrc \
    && mkdir -p ${CLOUDBERRY_DATA_DIRECTORY} \
                ${CLOUDBERRY_DATA_DIRECTORY}/pxf \
                /docker-entrypoint-initdb.d \
    && chown -R ${CLOUDBERRY_USER}:${CLOUDBERRY_GROUP} \
        /home/${CLOUDBERRY_USER}/ \
        ${CLOUDBERRY_DATA_DIRECTORY} \
        /docker-entrypoint-initdb.d \
    && unlink /etc/localtime \
    && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo "${TZ}" > /etc/timezone

COPY --from=go_builder /usr/local/cloudberry-db /usr/local/cloudberry-db
COPY --from=go_builder \
    /opt/go/bin/gpbackup \
    /opt/go/bin/gprestore \
    /opt/go/bin/gpbackup_helper \
    /usr/local/cloudberry-db/bin/
COPY --from=go_builder /opt/go/bin/gpbackup_s3_plugin /usr/local/cloudberry-db/bin/gpbackup_s3_plugin
COPY --from=go_builder /usr/local/pxf /usr/local/pxf
COPY --from=go_builder /tmp/wal-g/main/gp/wal-g /usr/local/cloudberry-db/bin/wal-g
COPY --chmod=755 docker/files/entrypoint.sh /entrypoint.sh
COPY --chmod=755 docker/files/start_cbdb.sh /start_cbdb.sh

LABEL \
    org.opencontainers.image.version="${REPO_BUILD_TAG}" \
    org.opencontainers.image.source="https://github.com/woblerr/docker-cloudberry"

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/start_cbdb.sh"]
