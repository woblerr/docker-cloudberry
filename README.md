# docker-cloudberry

This project provides Docker images for running [Apache Cloudberry](https://cloudberry.apache.org/) in containers. It supports both single-node and multi-node deployments. The images can be used for development, testing, and learning purposes.

For Greenplum Database and its other forks (Greengage, WarehousePG, open-gpdb) Docker images, see the [docker-greenplum](https://github.com/woblerr/docker-greenplum) repository.

The Cloudberry in docker provides the following features:
- single-node deployment;
- coordinator and segments deployment;
- support for segment mirroring;
- standby coordinator support;
- diskquota (not available in 2.1.0-incubating, will be added in a future release);
- gpbackup/gprestore;
- gpbackup-s3-plugin;
- gpbackman;
- gpbackup_exporter;
- PXF (Platform Extension Framework);
- custom initialization scripts;
- WAL-G (physical backups);
- Yezzey with Yproxy for S3 offload (Cloudberry 2.2 only).


Environment variables supported by this image:

* `TZ` - container's time zone, default `Etc/UTC`;
* `CLOUDBERRY_USER` - non-root user name for execution of the command, default `gpadmin`;
* `CLOUDBERRY_UID` - UID of `${CLOUDBERRY_USER}` user, default `1001`;
* `CLOUDBERRY_GROUP` - group name of `${CLOUDBERRY_USER}` user, default `gpadmin`;
* `CLOUDBERRY_GID` - GID of `${CLOUDBERRY_USER}` user, default `1001`;
* `CLOUDBERRY_DEPLOYMENT` - Cloudberry deployment type, default `singlenode`, available values: `singlenode`, `master`, `segment`, `standby`;
* `CLOUDBERRY_DATA_DIRECTORY` - Cloudberry data directory location, default `/data`;
* `CLOUDBERRY_SEG_PREFIX` - Cloudberry segment prefix, default `gpseg`;
* `CLOUDBERRY_DATABASE_NAME` - Cloudberry database name, default `demo`, this database will be created during the initialization;
* `CLOUDBERRY_DISKQUOTA_ENABLE` - enable diskquota, default `false`. Note: diskquota extension is not available in 2.1.0-incubating, the setting will be silently skipped;
* `CLOUDBERRY_PXF_ENABLE` - enable PXF, default `false`;
* `CLOUDBERRY_WALG_ENABLE` - enable WAL-G, default `false`;
* `CLOUDBERRY_YEZZEY_ENABLE` - enable Yezzey and start Yproxy, default `false`; available only in Cloudberry 2.2, requires `/data/yproxy.yaml` on every coordinator and segment host, and must be enabled during the initial cluster initialization;
* `CLOUDBERRY_STANDBY_HOSTNAME` - standby coordinator hostname, used when `CLOUDBERRY_DEPLOYMENT=master` to add standby's SSH host key to `known_hosts` and initialize standby coordinator via `gpinitstandby`, optional;
* `CLOUDBERRY_COORDINATOR_HOSTNAME` - coordinator hostname, used when `CLOUDBERRY_DEPLOYMENT=standby` to add coordinator's SSH host key to `known_hosts`; required when `CLOUDBERRY_DEPLOYMENT=standby`;

Required environment variables:
* `CLOUDBERRY_PASSWORD` - password for `${CLOUDBERRY_USER}` user, **required**;

## Build matrix

The repository contains information for the last available versions. For specific version, you can build your own image using the [Build](#build) section.

| CBDB version | Ubuntu 22.04 | Ubuntu 24.04 | Rocky Linux 9 | Platform |
|---|---|---|---|---|
| 2.1.0-incubating | `2.1.0-incubating`, `2.1.0-incubating-ubuntu22.04` | — | `2.1.0-incubating-rockylinux9` | `linux/amd64`, `linux/arm64` |
| 2.2.0-incubating-rc1 | `2.2.0-incubating-rc1`, `2.2.0-incubating-rc1-ubuntu22.04` | `2.2.0-incubating-rc1-ubuntu24.04` | `2.2.0-incubating-rc1-rockylinux9` | `linux/amd64`, `linux/arm64` |

## Pull

Change `tag` to the version you need.

* Docker Hub:

```bash
docker pull woblerr/cloudberry:tag
```

* GitHub Registry:

```bash
docker pull ghcr.io/woblerr/cloudberry:tag
```

## Run

You will need to mount the necessary directories or files inside the container (or use this image to build your own on top of it).

### Simple

```bash
docker run -p 5432:5432 -e CLOUDBERRY_PASSWORD=gparray -d cloudberry:2.2.0-incubating-rc1
```

Connect to Cloudberry:

```bash
psql -h localhost -p 5432 -U gpadmin demo
```

### Docker Secrets

As an alternative to passing sensitive information via environment variables, `_FILE` may be appended to `CLOUDBERRY_PASSWORD` environment variable. In particular, this can be used to load passwords from Docker secrets stored in `/run/secrets/<secret_name>` files.

For example:
```bash
docker run -p 5432:5432 -e CLOUDBERRY_PASSWORD_FILE=/run/secrets/gpdb_password -d cloudberry:2.2.0-incubating-rc1
```

### Initialization Scripts

The image supports running custom initialization `*.sql` or `*.sh` scripts after Cloudberry was started. Place your scripts in the `/docker-entrypoint-initdb.d` directory inside the container.

Scripts in `/docker-entrypoint-initdb.d` are executed only if a container is started with an empty data directory; any pre-existing database will remain untouched when the container is started.

#### Script Execution Process

Scripts are processed as follows:
- **SQL scripts** (`*.sql`): Executed using `psql` with the following options:
  - Executed for the database specified in `CLOUDBERRY_DATABASE_NAME`.
  - Run with `-v ON_ERROR_STOP=1` flag.
  - Run with `--no-psqlrc`.
  - Connected as the `CLOUDBERRY_USER`.
- **Shell scripts** (`*.sh`):
  - If the script has executable permissions, it is executed directly.
  - If not executable, it is sourced.
- **Other files**: Files with other extensions are ignored.

Example SQL initialization script `00_init.sql`:

```sql
CREATE TABLE test_initialization (
  id serial PRIMARY KEY,
  name text,
  created_at timestamp DEFAULT current_timestamp
);

INSERT INTO test_initialization (name) VALUES ('Initialized via sql script');
```
Example shell script `01_init.sh`:

```bash
#!/bin/bash
echo "Executing initialization shell script"
psql -U ${CLOUDBERRY_USER} -h $(hostname) -d ${CLOUDBERRY_DATABASE_NAME} -c "INSERT INTO test_initialization (name) VALUES ('Added via shell script');"
echo "Shell script executed successfully!"
```

You can mount your initialization scripts directory to the container:

```bash
docker run -p 5432:5432 \
  -e CLOUDBERRY_PASSWORD=gparray \
  -v $(pwd)/docs/custom_init_scripts:/docker-entrypoint-initdb.d \
  -d cloudberry:2.1.0-incubating
```

Or build a custom image:

```bash
FROM cloudberry:2.1.0-incubating
COPY docs/custom_init_scripts/* /docker-entrypoint-initdb.d/
```

#### WAL-G configuration

When `CLOUDBERRY_WALG_ENABLE=true`, WAL-G is installed and available, but you need to configure it manually or use initialization scripts to set up `archive_command` and other parameters.


```bash
docker run -p 5432:5432 \
  -e CLOUDBERRY_PASSWORD=gparray \
  -e CLOUDBERRY_WALG_ENABLE=true \
  -v $(pwd)/wal-g.yaml:/tmp/wal-g.yaml \
  -v $(pwd)/wal-g_init.sh:/docker-entrypoint-initdb.d/wal-g_init.sh \
  -d cloudberry:2.1.0-incubating
```

Where init scripts for WAL-G looks like:
```bash
#!/bin/bash
echo "Configuring wal-g archive_command"
USER=${CLOUDBERRY_USER} gpconfig -c archive_command -v "wal-g seg wal-push %p --content-id=%c --config /tmp/wal-g.yaml"
USER=${CLOUDBERRY_USER} gpconfig -c archive_timeout -v 600 --skipvalidation
USER=${CLOUDBERRY_USER} gpstop -u
```

#### Yezzey and Yproxy

Cloudberry 2.2 images can enable S3 offload with `CLOUDBERRY_YEZZEY_ENABLE=true`. Mount the Yproxy configuration at `/data/yproxy.yaml` on every cluster host. See the [Yezzey and Yproxy guide](docs/yezzey_yproxy.md) for configuration and a complete Compose example.

#### gpbackup exporter

`gpbackup_exporter` collects Prometheus metrics from `gpbackup_history.db`. It is available in the image but is not started automatically. Start it on the coordinator with the path to its history database. The default `gpadmin` user keeps the exporter from running as root:

```bash
docker exec -d --user gpadmin <coordinator-container> \
  /usr/local/cloudberry-db/bin/gpbackup_exporter \
  --gpbackup.history-file=/data/master/gpseg-1/gpbackup_history.db
```

By default, it listens on port `19854`, serves metrics at `/metrics`, and refreshes them every 600 seconds. To expose the endpoint outside the container, publish port `19854` in your own Docker Compose configuration.

### Docker Compose
#### Prepare

Prepare password file (**set your own password**):
```bash
echo "gparray" > docker-compose/secrets/gpdb_password
```

For correct start docker compose, configs should be mounted to `/tmp`.
It's valid for `gpinitsystem_config`, `hostfile_gpinitsystem` and `authorized_keys` files.

SSH rsa keys should be mounted to `/home/${CLOUDBERRY_USER}/.ssh/` directory.
Coordinator mounts:
```yaml
    volumes:
      - ./conf/gpinitsystem_config_no_mirrors:/tmp/gpinitsystem_config
      - ./conf/hostfile_gpinitsystem:/tmp/hostfile_gpinitsystem
      - ./conf/ssh/id_rsa:/home/gpadmin/.ssh/id_rsa
      - ./conf/ssh/id_rsa.pub:/home/gpadmin/.ssh/id_rsa.pub
```
Segments mounts:
```yaml
    volumes:
       - ./conf/ssh/authorized_keys:/tmp/authorized_keys
```

#### Standby Coordinator

Standby coordinator mounts:
```yaml
    environment:
      - CLOUDBERRY_DEPLOYMENT=standby
      - CLOUDBERRY_COORDINATOR_HOSTNAME=master
    volumes:
      - ./conf/ssh/authorized_keys:/tmp/authorized_keys
      - ./conf/hostfile_gpinitsystem:/tmp/hostfile_gpinitsystem
      - ./conf/ssh/id_rsa:/home/gpadmin/.ssh/id_rsa
      - ./conf/ssh/id_rsa.pub:/home/gpadmin/.ssh/id_rsa.pub
```

`CLOUDBERRY_COORDINATOR_HOSTNAME` is required to add coordinator's SSH host key to `known_hosts` on standby. `hostfile_gpinitsystem` and SSH keys are required for standby to connect to segments after failover via `gpactivatestandby`.

The standby coordinator initialization is triggered only during the initial cluster setup. If the standby data volume is recreated later while the active coordinator data persists, it will not be initialized automatically. Manual restoration via `gpinitstandby` is required.

#### Run
Run cluster with 1 coordinator and 2 segments without mirroring:
```bash
docker compose -f ./docker-compose/docker-compose.no_mirrors.yaml up -d
```

Run cluster with persistent storage:
```bash
docker compose -f ./docker-compose/docker-compose.no_mirrors_persistent.yaml up -d
```

Run cluster with 1 coordinator and 2 segments with mirroring:
```bash
docker compose -f ./docker-compose/docker-compose.with_mirrors.yaml up -d
```

Run cluster with 1 coordinator, standby coordinator and 2 segments with mirroring:
```bash
docker compose -f ./docker-compose/docker-compose.with_mirrors_and_standby.yaml up -d
```

## Build

Build the default Ubuntu 22.04 profiles for both release lines:

```bash
make all
```

Build a specific profile:

```bash
make build_cbdb_21_ubuntu22
make build_cbdb_21_rockylinux9
make build_cbdb_22_ubuntu22
make build_cbdb_22_ubuntu24
make build_cbdb_22_rockylinux9
```

The release-line tags and parallelism can be overridden without editing Dockerfiles:

```bash
make build_cbdb_22_ubuntu24 TAG_CBDB_22=2.2.0-incubating-rc1 BUILD_JOBS=4
```

Each Dockerfile also accepts component build arguments: `CBDB_VERSION`, `PXF_VERSION`, `CBDB_BACKUP_VERSION`, `WALG_VERSION`, `GOLANG_VERSION`, `YPROXY_VERSION` (2.2 only), the base OS version, `BUILD_JOBS`, and `REPO_BUILD_TAG`. Java remains fixed at version 11. The 2.1 backup pin remains unchanged.

**Manual build example:**

```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  -f docker/cloudberry/ubuntu22.04/2.2/Dockerfile \
  --build-arg BUILD_JOBS=4 \
  -t cloudberry:2.2.0-incubating-rc1 .
```

## Running tests
Run the end-to-end tests:
```bash
make test-e2e
```

Run the separate Cloudberry 2.2 Yezzey test:

```bash
make test-e2e-yezzey
```
See [tests description](./e2e-tests/README.md).
