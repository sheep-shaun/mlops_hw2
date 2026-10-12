CREATE DATABASE IF NOT EXISTS fraud;

CREATE TABLE IF NOT EXISTS fraud.transactions
(
    transaction_time DateTime CODEC(Delta, ZSTD(1)),
    merch LowCardinality(String) CODEC(ZSTD(1)),
    cat_id LowCardinality(String) CODEC(ZSTD(1)),
    amount Decimal(18, 2) CODEC(ZSTD(1)),
    name_1 String CODEC(ZSTD(1)),
    name_2 String CODEC(ZSTD(1)),
    gender LowCardinality(String),
    street String CODEC(ZSTD(1)),
    one_city LowCardinality(String) CODEC(ZSTD(1)),
    us_state LowCardinality(String),
    post_code String CODEC(ZSTD(1)),
    lat Float64 CODEC(Gorilla, ZSTD(1)),
    lon Float64 CODEC(Gorilla, ZSTD(1)),
    population_city UInt32 CODEC(ZSTD(1)),
    jobs LowCardinality(String) CODEC(ZSTD(1)),
    merchant_lat Float64 CODEC(Gorilla, ZSTD(1)),
    merchant_lon Float64 CODEC(Gorilla, ZSTD(1)),
    PROJECTION max_by_state
    (
        SELECT
            us_state,
            argMax(tuple(cat_id, amount), tuple(amount, cat_id))
        GROUP BY us_state
    )
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(transaction_time)
ORDER BY (us_state, transaction_time);

CREATE TABLE IF NOT EXISTS fraud.transactions_kafka
(
    transaction_time DateTime,
    merch String,
    cat_id String,
    amount Decimal(18, 2),
    name_1 String,
    name_2 String,
    gender String,
    street String,
    one_city String,
    us_state String,
    post_code String,
    lat Float64,
    lon Float64,
    population_city UInt32,
    jobs String,
    merchant_lat Float64,
    merchant_lon Float64
)
ENGINE = Kafka
SETTINGS
    kafka_broker_list = 'kafka:9092',
    kafka_topic_list = 'transactions',
    kafka_group_name = 'clickhouse-hw2',
    kafka_format = 'JSONEachRow',
    kafka_num_consumers = 3,
    kafka_thread_per_consumer = 1,
    kafka_max_block_size = 65536,
    kafka_flush_interval_ms = 1000;

CREATE MATERIALIZED VIEW IF NOT EXISTS fraud.transactions_mv
TO fraud.transactions AS
SELECT * FROM fraud.transactions_kafka;
