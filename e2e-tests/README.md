# End-to-end tests

The following architecture is used to run the tests:

* Separate containers with Cloudberry.
* Separate containers for MinIO and nginx. Official images [minio/minio](https://hub.docker.com/r/minio/minio), [minio/mc](https://hub.docker.com/r/minio/mc) and [nginx](https://hub.docker.com/_/nginx) are used. It's necessary for S3 compatible storage for WAL archiving and backups.

## Prerequisites

Before running tests:

1. Build Cloudberry docker images as described in [Build section](../README.md#build).

2. Configure test environment by editing `e2e-tests/.env` file if needed.

3. Prepare password files as described in [Prepare section](../README.md#prepare) for Docker Compose. In tests used ssh keys from `docker-compose/conf/ssh/` directory, so you can use them or create your own.

## Running tests

Run all tests:
```bash
make test-e2e
``` 

### WAL-G tests

Primary cluster is described in `e2e-tests/docker-compose.cbdb.yml`, standby cluster is described in `e2e-tests/docker-compose.cbdb-restore.yml`, and S3 compatible storage is described in `e2e-tests/docker-compose.s3.yml`.

The test validates WAL-G backup and restore functionality for Cloudberry:

1. **Full backup test**:
   - Creates full backup on primary cluster
   - Restores backup on standby cluster
   - Compares data between primary and standby clusters

2. **Restore point test**:
   - Inserts additional data into primary cluster
   - Creates restore point
   - Restores to specific restore point on standby cluster  
   - Compares data between clusters at the restore point

The test verifies that data in tables `walg_ao`, `walg_co`, and `walg_heap` matches exactly between primary and standby clusters after backup/restore operations.

Run:

```bash
make test-e2e-walg
```

or

```bash
cd e2e-tests
make test-e2e-walg
```

or manually:

```bash
cd [docker-cloudberry-root]/e2e-tests
docker compose -f docker-compose.s3.yml -f docker-compose.cbdb.yml -f docker-compose.cbdb-restore.yml up -d
CLOUDBERRY_PASSWORD=$(cat ../docker-compose/secrets/gpdb_password) ./scripts/e2e-test.sh
docker compose -f docker-compose.s3.yml -f docker-compose.cbdb.yml -f docker-compose.cbdb-restore.yml down
```

### Standby coordinator tests

The cluster is described in `../docker-compose/docker-compose.with_mirrors_and_standby.yaml`.

The test validates standby coordinator promotion and cluster recovery functionality for Cloudberry:

1. **Graceful failover test**:
   - Stops the primary master coordinator gracefully
   - Promotes the standby coordinator to be the new primary
   - Compares test data on the new primary
   - Cleans up and initializes the old primary as a new standby coordinator
   - Verifies the standby replication state

2. **Crash recovery test**:
   - Simulates a crash by killing the primary coordinator container
   - Promotes the standby coordinator
   - Compares test data on the new primary
   - Revives the crashed container, cleans up data, and re-initializes it as a standby
   - Verifies the standby replication state

Run:

```bash
make test-e2e-standby-coordinator
```

or

```bash
cd e2e-tests
make test-e2e-standby-coordinator
```

or manually:

```bash
cd [docker-cloudberry-root]/e2e-tests
docker compose -f ../docker-compose/docker-compose.with_mirrors_and_standby.yaml up -d
CLOUDBERRY_PASSWORD=$(cat ../docker-compose/secrets/gpdb_password) ./scripts/e2e-standby-coordinator-test.sh
docker compose -f ../docker-compose/docker-compose.with_mirrors_and_standby.yaml down
```
