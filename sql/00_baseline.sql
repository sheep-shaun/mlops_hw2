CREATE TABLE IF NOT EXISTS fraud.transactions_baseline
(
    transaction_time String,
    merch String,
    cat_id String,
    amount Float64,
    name_1 String,
    name_2 String,
    gender String,
    street String,
    one_city String,
    us_state String,
    post_code String,
    lat Float64,
    lon Float64,
    population_city UInt64,
    jobs String,
    merchant_lat Float64,
    merchant_lon Float64
)
ENGINE = MergeTree
ORDER BY tuple();

TRUNCATE TABLE fraud.transactions_baseline;

INSERT INTO fraud.transactions_baseline
SELECT * FROM fraud.transactions;
