ARG REPO_BUILD_TAG
ARG ROCKY_VERSION="9"
ARG GOLANG_VERSION="1.24.13"
ARG XERCES_C_DOWNLOAD_URL="https://archive.apache.org/dist/xerces/c/3/sources"
ARG XERCES_C_VERSION="3.3.0"
ARG CBDB_DOWNLOAD_URL="https://github.com/apache/cloudberry"
ARG CBDB_VERSION="2.1.0-incubating"
ARG PXF_DOWNLOAD_URL="https://github.com/apache/cloudberry-pxf"
ARG PXF_VERSION="2.1.0-incubating"
ARG CBDB_BACKUP_DOWNLOAD_URL="https://github.com/apache/cloudberry-backup"
ARG CBDB_BACKUP_VERSION="6b40b13354e7ee2ff8f75262892d2f3d6004604e"
ARG WALG_DOWNLOAD_URL="https://github.com/wal-g/wal-g"
# Wait new releases for cloudberry to update to latest go version.
ARG WALG_VERSION="4b33c88939ce0cc23acc5f89dcf5e427c50923d9"
ARG GOSU_VERSION="1.19"

FROM rockylinux/rockylinux:${ROCKY_VERSION} AS builder

ARG XERCES_C_DOWNLOAD_URL
ARG XERCES_C_VERSION
ARG CBDB_DOWNLOAD_URL
ARG CBDB_VERSION

# Enable EPEL and CRB repositories
RUN dnf -y install \
        epel-release \
        dnf-plugins-core \
    && dnf config-manager --set-enabled crb \
    && dnf -y update \
    && dnf -y --allowerasing install \
        bison \
        cmake3 \
        curl \
        flex \
        git-core \
        gcc \
        gcc-c++ \
        iputils \
        binutils \
        krb5-server \
        krb5-workstation \
        bzip2-devel \
        libcurl-devel \
        libevent-devel \
        krb5-devel \
        pam-devel \
        perl-devel \
        perl-ExtUtils-Embed \
        perl-core \
        readline-devel \
        openssl-devel \
        libuv-devel \
        libxml2-devel \
        libyaml-devel \
        libzstd-devel \
        zlib-devel \
        openldap-devel \
        libuuid-devel \
        lz4-devel \
        protobuf-devel \
        liburing-devel \
        libssh2-devel \
        glibc-langpack-en \
        glibc-locale-source \
        net-tools \
        openssh-clients \
        openssh-server \
        openssl \
        python3 \
        python3-devel \
        python3-pip \
        python3-psutil \
        python3-psycopg2 \
        python3-setuptools \
        python3-pyyaml \
        pkg-config \
        sudo \
        java-11-openjdk-devel \
        wget \
        apr-devel \
        apr-util-devel \
        brotli-devel \
        libsodium-devel \
        sqlite-devel \
    && dnf clean all \
    && rm -rf /var/cache/dnf \
    && echo -e "/usr/local/lib\n/usr/local/lib64\n" >> /etc/ld.so.conf.d/local.conf \
    && ldconfig

# xerces-c (build from source — not available in Rocky repos)
RUN wget ${XERCES_C_DOWNLOAD_URL}/xerces-c-${XERCES_C_VERSION}.tar.gz -O /tmp/xerces-c-${XERCES_C_VERSION}.tar.gz \
    && mkdir -p /tmp/xerces-c \
    && tar -xzf /tmp/xerces-c-${XERCES_C_VERSION}.tar.gz --strip-components=1 -C /tmp/xerces-c \
    && cd /tmp/xerces-c \
    && ./configure --prefix=/usr/local/xerces-c \
    && make -j2 \
    && make install \
    && ldconfig \
    && rm -rf \
        /tmp/xerces-c \
        /tmp/xerces-c-${XERCES_C_VERSION}.tar.gz

# cloudberry
RUN git clone --recurse-submodules --depth 1 --branch ${CBDB_VERSION} ${CBDB_DOWNLOAD_URL} /tmp/cloudberry \
    && cd /tmp/cloudberry \
    && mkdir -p /usr/local/cloudberry-db/lib \
    && cp /usr/local/xerces-c/lib/libxerces-c*.so* /usr/local/cloudberry-db/lib/ \
    && ldconfig \
    && export LD_LIBRARY_PATH=/usr/local/cloudberry-db/lib:${LD_LIBRARY_PATH} \
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
        --with-includes=/usr/local/xerces-c/include \
        --with-libraries=/usr/local/cloudberry-db/lib \
    && make -j2 \
    && make install \
    && make -C contrib install \
    # && make -C gpcontrib/diskquota install \
    && rm -rf /tmp/cloudberry

# Install PyGreSQL (not available in EPEL for Rocky 9)
RUN PATH=${PATH}:/usr/local/cloudberry-db/bin pip3 install --no-cache-dir PyGreSQL

FROM builder AS go_builder
ARG GOLANG_VERSION
ARG CBDB_BACKUP_DOWNLOAD_URL
ARG CBDB_BACKUP_VERSION
ARG PXF_DOWNLOAD_URL
ARG PXF_VERSION
ARG WALG_DOWNLOAD_URL
ARG WALG_VERSION

RUN mkdir -p /opt/go \
    && arch="$(uname -m)" \
    && case "${arch}" in \
        aarch64) dpkgArch='arm64' ;; \
        x86_64) dpkgArch='amd64' ;; \
        *) echo >&2 "error: unknown/unsupported architecture '${arch}'"; exit 1 ;; \
    esac \
    && wget https://go.dev/dl/go${GOLANG_VERSION}.linux-${dpkgArch}.tar.gz \
    && tar -xvf go${GOLANG_VERSION}.linux-${dpkgArch}.tar.gz -C /usr/local

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

FROM rockylinux/rockylinux:${ROCKY_VERSION} AS final

ARG REPO_BUILD_TAG
ARG CBDB_VERSION
ARG GOSU_VERSION

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

RUN dnf -y update \
    && dnf -y --allowerasing install \
        bzip2-libs \
        libcurl \
        libevent \
        krb5-libs \
        pam \
        readline \
        openssl-libs \
        libuv \
        libxml2 \
        libyaml \
        libzstd \
        zlib \
        openldap \
        lz4-libs \
        protobuf \
        liburing \
        iputils \
        krb5-server \
        krb5-workstation \
        libuuid \
        openssh-clients \
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
        glibc-langpack-en \
        glibc-locale-source \
        iproute \
        python3 \
        python3-pip \
        python3-psutil \
        python3-psycopg2 \
        python3-setuptools \
        python3-pyyaml \
        sudo \
        wget \
        hostname \
        ca-certificates \
        tzdata \
        java-11-openjdk-headless

# Grab gosu for easy step-down from root
# https://github.com/tianon/gosu/releases
# https://github.com/tianon/gosu/blob/master/INSTALL.md
RUN arch="$(uname -m)" \
    && case "${arch}" in \
            aarch64) dpkgArch='arm64' ;; \
            x86_64) dpkgArch='amd64' ;; \
            *) echo >&2 "error: unknown/unsupported architecture '${arch}'"; exit 1 ;; \
        esac \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-${dpkgArch}" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-${dpkgArch}.asc" \
    # Verify the signature
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    # Verify that the binary works
    && gosu --version \
    && gosu nobody true

RUN groupadd --gid ${CLOUDBERRY_GID} ${CLOUDBERRY_GROUP} \
    && useradd --shell /bin/bash --uid ${CLOUDBERRY_UID} --gid ${CLOUDBERRY_GID} -m ${CLOUDBERRY_USER} \
    && localedef -i en_US -f UTF-8 en_US.UTF-8 \
    && mkdir -m 700 -p /home/${CLOUDBERRY_USER}/.ssh \
    && ssh-keygen -f /home/${CLOUDBERRY_USER}/.ssh/id_rsa -t rsa -N "" \
    && echo "HostKeyAlgorithms +ssh-rsa" >> /etc/ssh/sshd_config \
    && echo "PubkeyAcceptedKeyTypes +ssh-rsa" >> /etc/ssh/sshd_config \
    && echo "${CLOUDBERRY_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && echo "source /usr/local/cloudberry-db/cloudberry-env.sh" > /home/${CLOUDBERRY_USER}/.bashrc \
    && echo "export JAVA_HOME=/usr/lib/jvm/jre-11-openjdk" >> /home/${CLOUDBERRY_USER}/.bashrc \
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

COPY --chown=${CLOUDBERRY_USER}:${CLOUDBERRY_GROUP} --from=go_builder /usr/local/cloudberry-db /usr/local/cloudberry-db
# Copy xerces-c shared libs from builder (built from source on Rocky)
COPY --chown=${CLOUDBERRY_USER}:${CLOUDBERRY_GROUP} --from=builder \
    /usr/local/xerces-c/lib/libxerces-c.so \
    /usr/local/xerces-c/lib/libxerces-c-3.3.so \
    /usr/local/cloudberry-db/lib/

# Install PyGreSQL (not available in EPEL for Rocky 9)
RUN dnf -y install gcc python3-devel \
    && PATH=${PATH}:/usr/local/cloudberry-db/bin pip3 install --no-cache-dir PyGreSQL \
    && dnf -y remove gcc python3-devel \
    && dnf clean all \
    && rm -rf /var/cache/dnf

COPY --chown=${CLOUDBERRY_USER}:${CLOUDBERRY_GROUP} --from=go_builder \
    /opt/go/bin/gpbackup \
    /opt/go/bin/gprestore \
    /opt/go/bin/gpbackup_helper \
    /opt/go/bin/gpbackup_s3_plugin \
    /opt/go/bin/gpbackman \
    /usr/local/cloudberry-db/bin/
COPY --chown=${CLOUDBERRY_USER}:${CLOUDBERRY_GROUP} --from=go_builder /usr/local/pxf /usr/local/pxf
COPY --chown=${CLOUDBERRY_USER}:${CLOUDBERRY_GROUP} --from=go_builder /tmp/wal-g/main/gp/wal-g /usr/local/cloudberry-db/bin/wal-g
COPY --chmod=755 docker/files/entrypoint.sh /entrypoint.sh
COPY --chmod=755 docker/files/start_cbdb.sh /start_cbdb.sh

LABEL \
    org.opencontainers.image.version="${REPO_BUILD_TAG}" \
    org.opencontainers.image.source="https://github.com/woblerr/docker-cloudberry"

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/start_cbdb.sh"]
