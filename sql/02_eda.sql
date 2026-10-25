

-- 0. Quick overview: number of rows in each table
SELECT 'users' AS table_name, COUNT(*) AS row_count FROM users
UNION ALL
SELECT 'web_sessions', COUNT(*) FROM web_sessions
UNION ALL
SELECT 'events', COUNT(*) FROM events
UNION ALL
SELECT 'subscriptions', COUNT(*) FROM subscriptions 
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'marketing_spend', COUNT(*) FROM marketing_spend
ORDER BY table_name;


-- ============================================================
-- 1. USERS
-- ============================================================

-- 1.1 Row count and duplicate primary/business IDs
SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT user_id) AS unique_user_ids,
    COUNT(*) - COUNT(DISTINCT user_id) AS duplicate_user_id_rows,
    COUNT(*) FILTER (WHERE user_id IS NULL) AS missing_user_ids,
    MIN(created_at) AS min_created_at,
    MAX(created_at) AS max_created_at
FROM users;

-- 1.2 Missing values in each column
SELECT
    COUNT(*) FILTER (WHERE user_id IS NULL) AS user_id_missing,
    COUNT(*) FILTER (WHERE created_at IS NULL) AS created_at_missing,
    COUNT(*) FILTER (WHERE acquisition_channel IS NULL) AS acquisition_channel_missing,
    COUNT(*) FILTER (WHERE campaign_id IS NULL) AS campaign_id_missing,
    COUNT(*) FILTER (WHERE landing_variant IS NULL) AS landing_variant_missing,
    COUNT(*) FILTER (WHERE device IS NULL) AS device_missing,
    COUNT(*) FILTER (WHERE country IS NULL) AS country_missing
FROM users;

-- 1.3 Unique values in important categorical columns
SELECT 'acquisition_channel' AS column_name, acquisition_channel AS value, COUNT(*) AS rows_count
FROM users GROUP BY acquisition_channel
UNION ALL
SELECT 'campaign_id', campaign_id, COUNT(*) FROM users GROUP BY campaign_id
UNION ALL
SELECT 'landing_variant', landing_variant, COUNT(*) FROM users GROUP BY landing_variant
UNION ALL
SELECT 'device', device, COUNT(*) FROM users GROUP BY device
UNION ALL
SELECT 'country', country, COUNT(*) FROM users GROUP BY country
ORDER BY column_name, rows_count DESC, value;


-- ============================================================
-- 2. WEB_SESSIONS
-- ============================================================

SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT session_id) AS unique_session_ids,
    COUNT(*) - COUNT(DISTINCT session_id) AS duplicate_session_id_rows,
    COUNT(*) FILTER (WHERE session_id IS NULL) AS missing_session_ids,
    MIN(session_start) AS min_session_start,
    MAX(session_start) AS max_session_start
FROM web_sessions;

SELECT
    COUNT(*) FILTER (WHERE session_id IS NULL) AS session_id_missing,
    COUNT(*) FILTER (WHERE user_id IS NULL) AS user_id_missing,
    COUNT(*) FILTER (WHERE session_start IS NULL) AS session_start_missing,
    COUNT(*) FILTER (WHERE landing_page IS NULL) AS landing_page_missing,
    COUNT(*) FILTER (WHERE device IS NULL) AS device_missing,
    COUNT(*) FILTER (WHERE utm_source IS NULL) AS utm_source_missing,
    COUNT(*) FILTER (WHERE utm_campaign IS NULL) AS utm_campaign_missing
FROM web_sessions;

SELECT 'landing_page' AS column_name, landing_page AS value, COUNT(*) AS rows_count
FROM web_sessions GROUP BY landing_page
UNION ALL
SELECT 'device', device, COUNT(*) FROM web_sessions GROUP BY device
UNION ALL
SELECT 'utm_source', utm_source, COUNT(*) FROM web_sessions GROUP BY utm_source
UNION ALL
SELECT 'utm_campaign', utm_campaign, COUNT(*) FROM web_sessions GROUP BY utm_campaign
ORDER BY column_name, rows_count DESC, value;


-- ============================================================
-- 3. EVENTS
-- ============================================================

SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT event_id) AS unique_event_ids,
    COUNT(*) - COUNT(DISTINCT event_id) AS duplicate_event_id_rows,
    COUNT(*) FILTER (WHERE event_id IS NULL) AS missing_event_ids,
    MIN(event_time) AS min_event_time,
    MAX(event_time) AS max_event_time
FROM events;

SELECT
    COUNT(*) FILTER (WHERE event_id IS NULL) AS event_id_missing,
    COUNT(*) FILTER (WHERE user_id IS NULL) AS user_id_missing,
    COUNT(*) FILTER (WHERE session_id IS NULL) AS session_id_missing,
    COUNT(*) FILTER (WHERE event_time IS NULL) AS event_time_missing,
    COUNT(*) FILTER (WHERE event_name IS NULL) AS event_name_missing,
    COUNT(*) FILTER (WHERE event_properties IS NULL) AS event_properties_missing
FROM events;

SELECT event_name, COUNT(*) AS rows_count
FROM events
GROUP BY event_name
ORDER BY rows_count DESC, event_name;

SELECT
    user_id,
    session_id,
    event_time,
    event_name,
    COUNT(*) AS duplicate_count
FROM events
GROUP BY user_id, session_id, event_time, event_name
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, event_time;


-- ============================================================
-- 4. SUBSCRIPTIONS
-- ============================================================

SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT subscription_id) AS unique_subscription_ids,
    COUNT(*) - COUNT(DISTINCT subscription_id) AS duplicate_subscription_id_rows,
    COUNT(*) FILTER (WHERE subscription_id IS NULL) AS missing_subscription_ids,
    MIN(trial_start) AS min_trial_start,
    MAX(trial_start) AS max_trial_start,
    MIN(trial_end) AS min_trial_end,
    MAX(trial_end) AS max_trial_end,
    MIN(current_period_start) AS min_current_period_start,
    MAX(current_period_end) AS max_current_period_end
FROM subscriptions;

SELECT
    COUNT(*) FILTER (WHERE subscription_id IS NULL) AS subscription_id_missing,
    COUNT(*) FILTER (WHERE user_id IS NULL) AS user_id_missing,
    COUNT(*) FILTER (WHERE plan_type IS NULL) AS plan_type_missing,
    COUNT(*) FILTER (WHERE status IS NULL) AS status_missing,
    COUNT(*) FILTER (WHERE trial_start IS NULL) AS trial_start_missing,
    COUNT(*) FILTER (WHERE trial_end IS NULL) AS trial_end_missing,
    COUNT(*) FILTER (WHERE current_period_start IS NULL) AS current_period_start_missing,
    COUNT(*) FILTER (WHERE current_period_end IS NULL) AS current_period_end_missing
FROM subscriptions;

SELECT 'plan_type' AS column_name, plan_type AS value, COUNT(*) AS rows_count
FROM subscriptions GROUP BY plan_type
UNION ALL
SELECT 'status', status, COUNT(*) FROM subscriptions GROUP BY status
ORDER BY column_name, rows_count DESC, value;


-- ============================================================
-- 5. PAYMENTS
-- ============================================================

SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT payment_id) AS unique_payment_ids,
    COUNT(*) - COUNT(DISTINCT payment_id) AS duplicate_payment_id_rows,
    COUNT(*) FILTER (WHERE payment_id IS NULL) AS missing_payment_ids,
    MIN(payment_time) AS min_payment_time,
    MAX(payment_time) AS max_payment_time
FROM payments;

SELECT
    COUNT(*) FILTER (WHERE payment_id IS NULL) AS payment_id_missing,
    COUNT(*) FILTER (WHERE user_id IS NULL) AS user_id_missing,
    COUNT(*) FILTER (WHERE subscription_id IS NULL) AS subscription_id_missing,
    COUNT(*) FILTER (WHERE payment_time IS NULL) AS payment_time_missing,
    COUNT(*) FILTER (WHERE amount IS NULL) AS amount_missing,
    COUNT(*) FILTER (WHERE currency IS NULL) AS currency_missing,
    COUNT(*) FILTER (WHERE payment_status IS NULL) AS payment_status_missing,
    COUNT(*) FILTER (WHERE payment_method IS NULL) AS payment_method_missing
FROM payments;

SELECT 'currency' AS column_name, currency AS value, COUNT(*) AS rows_count
FROM payments GROUP BY currency
UNION ALL
SELECT 'payment_status', payment_status, COUNT(*) FROM payments GROUP BY payment_status
UNION ALL
SELECT 'payment_method', payment_method, COUNT(*) FROM payments GROUP BY payment_method
ORDER BY column_name, rows_count DESC, value;


-- ============================================================
-- 6. MARKETING_SPEND
-- ============================================================

SELECT
    COUNT(*) AS row_count,
    MIN(spend_date) AS min_spend_date,
    MAX(spend_date) AS max_spend_date
FROM marketing_spend;

SELECT
    COUNT(*) FILTER (WHERE spend_date IS NULL) AS spend_date_missing,
    COUNT(*) FILTER (WHERE channel IS NULL) AS channel_missing,
    COUNT(*) FILTER (WHERE campaign_id IS NULL) AS campaign_id_missing,
    COUNT(*) FILTER (WHERE spend_amount IS NULL) AS spend_amount_missing,
    COUNT(*) FILTER (WHERE impressions IS NULL) AS impressions_missing,
    COUNT(*) FILTER (WHERE clicks IS NULL) AS clicks_missing
FROM marketing_spend;

SELECT 'channel' AS column_name, channel AS value, COUNT(*) AS rows_count
FROM marketing_spend GROUP BY channel
UNION ALL
SELECT 'campaign_id', campaign_id, COUNT(*) FROM marketing_spend GROUP BY campaign_id
ORDER BY column_name, rows_count DESC, value;

SELECT
    spend_date,
    campaign_id,
    COUNT(*) AS duplicate_count
FROM marketing_spend
GROUP BY spend_date, campaign_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, spend_date;

