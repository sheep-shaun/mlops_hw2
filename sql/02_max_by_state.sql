SELECT
    us_state,
    largest.1 AS cat_id,
    largest.2 AS amount
FROM
(
    SELECT
        us_state,
        argMax(tuple(cat_id, amount), tuple(amount, cat_id)) AS largest
    FROM fraud.transactions
    GROUP BY us_state
)
ORDER BY us_state
FORMAT CSVWithNames;
