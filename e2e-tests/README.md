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
