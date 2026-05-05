CBDB_PASSWORD := $(shell cat ../docker-compose/secrets/gpdb_password)

.PHONY: test-e2e
test-e2e: test-e2e-walg test-e2e-standby-coordinator

.PHONY: test-e2e-standby-coordinator
test-e2e-standby-coordinator: 
	make test-e2e-standby-coordinator-down
	make test-e2e-standby-coordinator-up
	make test-e2e-standby-coordinator-run 
	make test-e2e-standby-coordinator-down

.PHONY: test-e2e-standby-coordinator-up
test-e2e-standby-coordinator-up:
	@echo "INFO - Start e2e tests for standby coordinator"
	docker compose -f ../docker-compose/docker-compose.with_mirrors_and_standby.yaml up -d

.PHONY: test-e2e-standby-coordinator-run
test-e2e-standby-coordinator-run:
	@echo "INFO - Run e2e tests for standby coordinator"
	CLOUDBERRY_PASSWORD=$(CBDB_PASSWORD) ./scripts/e2e-standby-coordinator-test.sh

.PHONY: test-e2e-standby-coordinator-down
test-e2e-standby-coordinator-down:
	@echo "INFO - Stop e2e tests for standby coordinator"
	docker compose -f ../docker-compose/docker-compose.with_mirrors_and_standby.yaml down

.PHONY: test-e2e-walg
test-e2e-walg: 
	make test-e2e-walg-down
	make test-e2e-walg-up
	make test-e2e-walg-run 
	make test-e2e-walg-down

.PHONY: test-e2e-walg-up
test-e2e-walg-up:
	@echo "INFO - Start e2e tests for wal-g"
	docker compose -f docker-compose.s3.yml -f docker-compose.cbdb.yml -f docker-compose.cbdb-restore.yml up -d

.PHONY: test-e2e-walg-run
test-e2e-walg-run:
	@echo "INFO - Run e2e tests for wal-g"
	CLOUDBERRY_PASSWORD=$(CBDB_PASSWORD) ./scripts/e2e-test.sh

.PHONY: test-e2e-walg-down
test-e2e-walg-down:
	@echo "INFO - Stop e2e tests for wal-g"
	docker compose -f docker-compose.s3.yml -f docker-compose.cbdb.yml -f docker-compose.cbdb-restore.yml down
