SELECT
    date_trunc('month', spend_date) as date,
    SUM(spend_amount)
FROM marketing_spend
GROUP BY 1
ORDER BY 1

SELECT
    date_trunc('month', session_start) as date,
    COUNT(session_id) as session_coune
FROM web_sessions
GROUP BY 1
ORDER BY 1

SELECT
    date_trunc('month', created_at) as date,
    COUNT(DISTINCT user_id) as user_count
FROM users
GROUP BY 1
ORDER BY 1

WITH first_payment AS (
    SELECT
        user_id,
        MIN(payment_time) AS first_payment_time
    FROM payments
    GROUP BY user_id
)
SELECT
    DATE_TRUNC('month', first_payment_time) AS month,
    COUNT(*) AS new_paying_users
FROM first_payment
GROUP BY 1
ORDER BY 1;