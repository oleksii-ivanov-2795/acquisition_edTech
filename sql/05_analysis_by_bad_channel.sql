-- funnel

WITH landing_visit AS (
    SELECT
        e.user_id,
        MIN(e.event_time) AS landing_time
    FROM events e
    WHERE e.event_name = 'landing_visit'
    GROUP BY e.user_id
),
registration AS (
    SELECT
        l.user_id,
        MIN(e.event_time) AS registration_time
    FROM landing_visit l
    JOIN events e
        ON e.user_id = l.user_id
       AND e.event_name = 'registration'
       AND e.event_time >= l.landing_time
    GROUP BY l.user_id
),
trial_start AS (
    SELECT
        r.user_id,
        MIN(e.event_time) AS trial_time
    FROM registration r
    JOIN events e
        ON e.user_id = r.user_id
       AND e.event_name = 'trial_start'
       AND e.event_time >= r.registration_time
    GROUP BY r.user_id
),
key_product_action AS (
    SELECT
        t.user_id,
        MIN(e.event_time) AS action_time
    FROM trial_start t
    JOIN events e
        ON e.user_id = t.user_id
       AND e.event_name = 'key_product_action'
       AND e.event_time >= t.trial_time
    GROUP BY t.user_id
),
payment AS (
    SELECT
        t.user_id,
        MIN(p.payment_time) AS payment_time
    FROM trial_start t
    JOIN payments p
        ON p.user_id = t.user_id
       AND p.payment_time >= t.trial_time
    GROUP BY t.user_id
),
payment_succeeded AS (
    SELECT
        t.user_id,
        MIN(p.payment_time) AS payment_time
    FROM trial_start t
    JOIN payments p
        ON p.user_id = t.user_id
       AND p.payment_status = 'succeeded'
       AND p.payment_time >= t.trial_time
    GROUP BY t.user_id
)
SELECT
    LOWER(u.acquisition_channel) AS acquisition_channel,
    LOWER(u.landing_variant) AS landing_variant,

    COUNT(DISTINCT t.user_id)::numeric
        / NULLIF(COUNT(DISTINCT r.user_id), 0) AS trial_start_cr,

    COUNT(DISTINCT a.user_id)::numeric
        / NULLIF(COUNT(DISTINCT t.user_id), 0) AS key_action_cr,

    COUNT(DISTINCT p.user_id)::numeric
        / NULLIF(COUNT(DISTINCT t.user_id), 0) AS payment_cr,

    COUNT(DISTINCT ps.user_id)::numeric
        / NULLIF(COUNT(DISTINCT t.user_id), 0) AS succeeded_payment_cr

FROM landing_visit l

LEFT JOIN registration r
    ON r.user_id = l.user_id

LEFT JOIN trial_start t
    ON t.user_id = l.user_id

LEFT JOIN key_product_action a
    ON a.user_id = l.user_id

LEFT JOIN payment p
    ON p.user_id = l.user_id

LEFT JOIN payment_succeeded ps
    ON ps.user_id = l.user_id

LEFT JOIN users u
    ON u.user_id = l.user_id

GROUP BY
    LOWER(u.acquisition_channel),
    LOWER(u.landing_variant)

ORDER BY
    acquisition_channel,
    landing_variant;