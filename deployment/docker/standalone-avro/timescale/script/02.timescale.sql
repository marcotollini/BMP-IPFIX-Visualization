CREATE EXTENSION IF NOT EXISTS timescaledb;

SELECT create_hypertable('event', 'timestamp_database', chunk_time_interval => INTERVAL '1 day');
SELECT create_hypertable('dump', 'timestamp_database', chunk_time_interval => INTERVAL '1 day');