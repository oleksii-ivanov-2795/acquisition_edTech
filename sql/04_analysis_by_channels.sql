--Кол-во пользователей которые совершили оплату, успешные оплаты

SELECT
    date_trunc('month', p.payment_time) as date,
    LOWER(u.acquisition_channel) as channel,
    COUNT(DISTINCT p.user_id) as users
FROM payments p
LEFT JOIN users u ON u.user_id = p.user_id
WHERE payment_time < '2026-11-01'
GROUP BY 1,2
ORDER BY 1,2

SELECT
    date_trunc('month', p.payment_time) as date,
    LOWER(u.acquisition_channel) as channel,
    COUNT(DISTINCT p.user_id) as users
FROM payments p
LEFT JOIN users u ON u.user_id = p.user_id
WHERE payment_time < '2026-11-01' AND payment_status = 'succeeded'
GROUP BY 1,2
ORDER BY 1,2

-- CAC

WITH mark_spends_by_month as (
    SELECT
        date_trunc('month', spend_date) as date,
        LOWER(channel) as channel,
        SUM(COALESCE(spend_amount, 0)) as amount
    FROM marketing_spend
    GROUP BY 1,2
), users_count AS (
SELECT
    date_trunc('month', p.payment_time) as date,
    LOWER(u.acquisition_channel) as channel,
    COUNT(DISTINCT p.user_id) as users
FROM payments p
LEFT JOIN users u ON u.user_id = p.user_id
WHERE payment_time < '2026-11-01' AND payment_status = 'succeeded'
GROUP BY 1,2
)
SELECT
    uc.date,
    uc.channel,
    m.amount::numeric / uc.users as cac
FROM users_count uc
LEFT JOIN mark_spends_by_month m ON uc.date = m.date AND uc.channel = m.channel

-- CR to pay

WITH user_count AS (
SELECT
    date_trunc('month', created_at) as date,
    LOWER(acquisition_channel) as channel,
    COUNT(DISTINCT user_id) as users
FROM users
GROUP BY 1,2
), pay_users AS (
SELECT
    date_trunc('month', p.payment_time) as date,
    LOWER(u.acquisition_channel) as channel,
    COUNT(DISTINCT p.user_id) as users
FROM payments p
LEFT JOIN users u ON u.user_id = p.user_id
LEFT JOIN user_count uc ON uc.date = date_trunc('month', p.payment_time) AND uc.channel = u.acquisition_channel
WHERE payment_time < '2026-11-01' AND payment_status = 'succeeded'
GROUP BY 1,2
)

SELECT
    uc.date,
    uc.channel,
    COALESCE(pu.users::numeric / uc.users,0) as cr_to_pay
FROM user_count uc
LEFT JOIN pay_users pu ON pu.date = uc.date AND pu.channel = uc.channel
ORDER BY 1,2

-- funnel

WITH params AS (
    SELECT 'month'::text AS date_grain
),
landing_visit AS (
    SELECT
        date_trunc(p.date_grain, e.event_time) AS period,
        e.user_id,
        MIN(e.event_time) AS landing_time
    FROM events e
    CROSS JOIN params p
    WHERE e.event_name = 'landing_visit'
    GROUP BY 1, 2
),
registration AS (
    SELECT
        l.period,
        l.user_id,
        MIN(e.event_time) AS registration_time
    FROM landing_visit l
    JOIN events e
        ON e.user_id = l.user_id
       AND e.event_name = 'registration'
       AND e.event_time >= l.landing_time
    GROUP BY 1, 2
),
trial_start AS (
    SELECT
        r.period,
        r.user_id,
        MIN(e.event_time) AS trial_time
    FROM registration r
    JOIN events e
        ON e.user_id = r.user_id
       AND e.event_name = 'trial_start'
       AND e.event_time >= r.registration_time
    GROUP BY 1, 2
),
key_product_action AS (
    SELECT
        t.period,
        t.user_id,
        MIN(e.event_time) AS action_time
    FROM trial_start t
    JOIN events e
        ON e.user_id = t.user_id
       AND e.event_name = 'key_product_action'
       AND e.event_time >= t.trial_time
    GROUP BY 1, 2
),
payment_succeeded AS (
    SELECT
        t.period,
        t.user_id,
        MIN(p.payment_time) AS payment_time
    FROM trial_start t
    JOIN payments p
        ON p.user_id = t.user_id
       AND p.payment_status = 'succeeded'
       AND p.payment_time >= t.trial_time
    GROUP BY 1, 2
)
SELECT
    l.period,
    LOWER(u.acquisition_channel) AS channel,
    -- 1.0 AS landing_users,
    -- COUNT(DISTINCT r.user_id)::numeric
    --     / NULLIF(COUNT(DISTINCT l.user_id), 0) AS registration_cr,
    COUNT(DISTINCT t.user_id)::numeric
        / NULLIF(COUNT(DISTINCT r.user_id), 0) AS trial_start_cr,

    COUNT(DISTINCT a.user_id)::numeric
        / NULLIF(COUNT(DISTINCT t.user_id), 0) AS key_action_cr,

    COUNT(DISTINCT ps.user_id)::numeric
        / NULLIF(COUNT(DISTINCT t.user_id), 0) AS payment_cr

FROM landing_visit l

LEFT JOIN registration r
    ON r.user_id = l.user_id
   AND r.period = l.period

LEFT JOIN trial_start t
    ON t.user_id = l.user_id
   AND t.period = l.period

LEFT JOIN key_product_action a
    ON a.user_id = l.user_id
   AND a.period = l.period

LEFT JOIN payment_succeeded ps
    ON ps.user_id = l.user_id
   AND ps.period = l.period

LEFT JOIN users u
    ON u.user_id = l.user_id

GROUP BY 1, 2
ORDER BY 1, 2;

