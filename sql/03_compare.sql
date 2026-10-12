SELECT
    us_state,
    argMax(tuple(cat_id, amount), tuple(amount, cat_id)) AS largest
FROM fraud.transactions_baseline
GROUP BY us_state
ORDER BY us_state
SETTINGS log_comment = 'hw2_baseline', use_query_cache = 0
FORMAT Null;

SELECT
    us_state,
    argMax(tuple(cat_id, amount), tuple(amount, cat_id)) AS largest
FROM fraud.transactions
GROUP BY us_state
ORDER BY us_state
SETTINGS log_comment = 'hw2_optimized', use_query_cache = 0
FORMAT Null;

SYSTEM FLUSH LOGS;

SELECT
    log_comment,
    query_duration_ms,
    read_rows,
    read_bytes,
    projections
FROM system.query_log
WHERE type = 'QueryFinish'
    AND log_comment IN ('hw2_baseline', 'hw2_optimized')
ORDER BY event_time_microseconds DESC
LIMIT 2;

SELECT
    table,
    sum(rows) AS rows,
    sum(bytes_on_disk) AS bytes_on_disk
FROM system.parts
WHERE database = 'fraud'
    AND table IN ('transactions_baseline', 'transactions')
    AND active
GROUP BY table
ORDER BY table;
