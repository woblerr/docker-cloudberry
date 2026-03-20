-- heap
DROP TABLE IF EXISTS walg_heap;
CREATE TABLE walg_heap AS SELECT i FROM generate_series(1,1000) AS i;

-- append-optimized row-oriented
DROP TABLE IF EXISTS walg_ao;
CREATE TABLE walg_ao(a int, b int) WITH (appendoptimized = true) DISTRIBUTED BY (a);
INSERT INTO walg_ao select i, i FROM generate_series(1,1000) i;

-- append-optimized column-oriented
DROP TABLE IF EXISTS walg_co;
CREATE TABLE walg_co(a int, b int) WITH (appendoptimized = true, orientation = column) DISTRIBUTED BY (a);
INSERT INTO walg_co select i, i FROM generate_series(1,1000) i;
