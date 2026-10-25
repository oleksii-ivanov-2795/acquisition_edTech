-- ============================================================
-- PROJECT 1: EDTECH FUNNEL & UNIT ECONOMICS DATABASE SCHEMA
-- PostgreSQL DDL (Handling Real-World / Raw Production Data)
-- ============================================================

DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS subscriptions CASCADE;
DROP TABLE IF EXISTS events CASCADE;
DROP TABLE IF EXISTS web_sessions CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS marketing_spend CASCADE;

-- 1. Marketing Spend Table
CREATE TABLE marketing_spend (
    spend_date DATE NOT NULL,
    channel VARCHAR(100) NOT NULL,
    campaign_id VARCHAR(100) NOT NULL,
    spend_amount NUMERIC(10, 2) NOT NULL CHECK (spend_amount >= 0),
    impressions INT NOT NULL CHECK (impressions >= 0),
    clicks INT NOT NULL CHECK (clicks >= 0),
    PRIMARY KEY (spend_date, campaign_id)
);

-- 2. Users Table (Raw registration data with nullable fields & uncleaned strings)
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    created_at TIMESTAMP NOT NULL,
    acquisition_channel VARCHAR(100),
    campaign_id VARCHAR(100),
    landing_variant VARCHAR(50),
    device VARCHAR(50),
    country VARCHAR(50)
);

-- 3. Web Sessions Table
CREATE TABLE web_sessions (
    session_id INT PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id),
    session_start TIMESTAMP NOT NULL,
    landing_page VARCHAR(255),
    device VARCHAR(50),
    utm_source VARCHAR(100),
    utm_campaign VARCHAR(100)
);

-- 4. Events Table (Allows NULL session_id for server-side events)
CREATE TABLE events (
    event_id INT PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id),
    session_id INT REFERENCES web_sessions(session_id),
    event_time TIMESTAMP NOT NULL,
    event_name VARCHAR(100) NOT NULL,
    event_properties JSONB
);

-- 5. Subscriptions Table
CREATE TABLE subscriptions (
    subscription_id INT PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id),
    plan_type VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL,
    trial_start TIMESTAMP NOT NULL,
    trial_end TIMESTAMP NOT NULL,
    current_period_start TIMESTAMP NOT NULL,
    current_period_end TIMESTAMP NOT NULL
);

-- 6. Payments Table (Includes failed/refunded attempts and nullable payment_method)
CREATE TABLE payments (
    payment_id INT PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id),
    subscription_id INT NOT NULL REFERENCES subscriptions(subscription_id),
    payment_time TIMESTAMP NOT NULL,
    amount NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
    currency VARCHAR(10) DEFAULT 'USD',
    payment_status VARCHAR(50) NOT NULL,
    payment_method VARCHAR(50)
);

-- Performance Indexes
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_users_campaign ON users(campaign_id);
CREATE INDEX idx_events_name_time ON events(event_name, event_time);
CREATE INDEX idx_events_user_id ON events(user_id);
CREATE INDEX idx_payments_time ON payments(payment_time);
