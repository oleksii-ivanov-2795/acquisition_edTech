WITH channels AS (
    SELECT DISTINCT
        LOWER(acquisition_channel) AS channel
    FROM users
),
months AS (
    SELECT generate_series(
        DATE '2026-05-01',
        DATE '2026-10-01',
        INTERVAL '1 month'
    ) AS date
),
revenue AS (
    SELECT
        date_trunc('month', p.payment_time) AS date,
        LOWER(u.acquisition_channel) AS channel,
        SUM(p.amount) AS revenue
    FROM payments p
    JOIN users u ON u.user_id = p.user_id
    WHERE p.payment_status = 'succeeded'
      AND p.payment_time >= DATE '2026-05-01'
      AND p.payment_time < DATE '2026-11-01'
    GROUP BY 1, 2
),
marketing AS (
    SELECT
        date_trunc('month', spend_date) AS date,
        LOWER(channel) AS channel,
        SUM(spend_amount) AS marketing_cost
    FROM marketing_spend
    WHERE spend_date >= DATE '2026-05-01'
      AND spend_date < DATE '2026-11-01'
    GROUP BY 1, 2
)
SELECT
    m.date,
    c.channel,
    COALESCE(r.revenue, 0) AS revenue,
    COALESCE(ms.marketing_cost, 0) AS marketing_cost,
    COALESCE(r.revenue, 0)
        - COALESCE(ms.marketing_cost, 0) AS net_profit
FROM months m
CROSS JOIN channels c
LEFT JOIN revenue r
    ON r.date = m.date
   AND r.channel = c.channel
LEFT JOIN marketing ms
    ON ms.date = m.date
   AND ms.channel = c.channel
ORDER BY 1, 2;