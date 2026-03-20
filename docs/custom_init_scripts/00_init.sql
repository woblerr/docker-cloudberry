CREATE TABLE test_initialization (
  id serial PRIMARY KEY,
  name text,
  created_at timestamp DEFAULT current_timestamp
);

INSERT INTO test_initialization (name) VALUES ('Initialized via sql script');
