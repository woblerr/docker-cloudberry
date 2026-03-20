CBDB_PASSWORD := $(shell cat ../docker-compose/secrets/gpdb_password)

.PHONY: test-e2e
test-e2e: test-e2e-walg

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
