CREATE DATABASE IF NOT EXISTS telco_churn_db;
USE telco_churn_db;

-- The table must match the one you are importing
CREATE TABLE telco_churn (
    customerid VARCHAR(50),
    count INT,
    country VARCHAR(50),
    state VARCHAR(50),
    city VARCHAR(50),
    zip_code VARCHAR(10),
    lat_long VARCHAR(50),
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6),
    gender VARCHAR(10),
    senior_citizen VARCHAR(5),
    partner VARCHAR(5),
    dependents VARCHAR(5),
    tenure_months INT,
    phone_service VARCHAR(5),
    multiple_lines VARCHAR(20),
    internet_service VARCHAR(20),
    online_security VARCHAR(20),
    online_backup VARCHAR(20),
    device_protection VARCHAR(20),
    tech_support VARCHAR(20),
    streaming_tv VARCHAR(20),
    streaming_movies VARCHAR(20),
    contract VARCHAR(20),
    paperless_billing VARCHAR(5),
    payment_method VARCHAR(50),
    monthly_charges FLOAT,
    total_charges FLOAT,
    churn_label VARCHAR(10),
    churn_score INT,
    cltv FLOAT,
    churn_reason VARCHAR(100),
    churn_flag TINYINT,
    tenure_groups VARCHAR(20),
    high_value_customer TINYINT,
    number_of_services INT
);


SELECT COUNT(*) FROM telco_churn;
SELECT * FROM telco_churn;

## Fix high_value_customer column ##
ALTER TABLE telco_churn
ADD PRIMARY KEY (customerid);
-- Turn off safe updates
SET SQL_SAFE_UPDATES = 0;
-- Run your update
UPDATE telco_churn
SET high_value_customer = 0;
-- Re-enable safe updates
SET SQL_SAFE_UPDATES = 1;
-- This is to fix the high_value_customer column 
UPDATE telco_churn
JOIN (
    SELECT 
        AVG(monthly_charges) AS avg_monthly,
        AVG(cltv) AS avg_cltv
    FROM telco_churn
) AS avg_vals
SET high_value_customer = 1
WHERE monthly_charges > avg_vals.avg_monthly
   OR cltv > avg_vals.avg_cltv;
SELECT COUNT(DISTINCT churn_flag) FROM telco_churn;
-- high_value_customer column is working again
SELECT high_value_customer, COUNT(*) AS customers
FROM telco_churn
GROUP BY high_value_customer;

## Overall churn rate 
SELECT COUNT(*) AS total_customers,
    SUM(churn_flag) AS churned_customers,
    ROUND(SUM(churn_flag) / COUNT(*) * 100, 2) AS churn_rate_percent
FROM telco_churn;

## Churn by tenure group
SELECT tenure_groups, COUNT(*) AS customers, SUM(churn_flag) AS churned,
    ROUND(SUM(churn_flag) / COUNT(*) * 100, 2) AS churn_rate_percent
FROM telco_churn
GROUP BY tenure_groups
ORDER BY churn_rate_percent DESC;

## Churn by contract type
SELECT contract, COUNT(*) AS customers, SUM(churn_flag) AS churned,
    ROUND(SUM(churn_flag) / COUNT(*) * 100, 2) AS churn_rate_percent
FROM telco_churn
GROUP BY contract
ORDER BY churn_rate_percent DESC;

## Revenue at risk
SELECT SUM(monthly_charges) AS monthly_revenue_at_risk
FROM telco_churn
WHERE churn_flag = 1;


###          KPI VIEWS         ###

## 1)Churn overview
CREATE VIEW churn_overview AS
SELECT churn_flag, COUNT(*) AS customers,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM telco_churn) * 100, 2) AS percent_of_total
FROM telco_churn
GROUP BY churn_flag;

SELECT * FROM churn_overview;

## 2)Churn_by_tenure
CREATE VIEW churn_by_tenure AS
SELECT tenure_groups, COUNT(*) AS customers,
    ROUND(SUM(churn_flag) / COUNT(*) * 100, 2) AS churn_rate_percent
FROM telco_churn
GROUP BY tenure_groups;

SELECT * FROM churn_by_tenure;

## 3)Churn by contract type
CREATE OR REPLACE VIEW vw_churn_by_contract AS
SELECT contract, COUNT(*) AS customers, SUM(churn_flag) AS churned,
    ROUND(SUM(churn_flag) / COUNT(*) * 100, 2) AS churn_rate_percent
FROM telco_churn
GROUP BY contract
ORDER BY churn_rate_percent DESC;

SELECT * FROM vw_churn_by_contract;

## 4)Churn by high value customer
CREATE OR REPLACE VIEW vw_churn_by_value AS
SELECT high_value_customer, COUNT(*) AS customers, SUM(churn_flag) AS churned,
    ROUND(SUM(churn_flag) / COUNT(*) * 100, 2) AS churn_rate_percent
FROM telco_churn
GROUP BY high_value_customer;

SELECT * FROM vw_churn_by_value;

## 5)Revenue at risk
CREATE VIEW vw_revenue_at_risk AS
SELECT SUM(monthly_charges) AS monthly_revenue_at_risk, SUM(cltv) AS total_cltv_at_risk
FROM telco_churn
WHERE churn_flag = 1;

SELECT * FROM vw_revenue_at_risk;

## 6)Churn by number of services 
CREATE VIEW vw_churn_by_services AS
SELECT number_of_services, COUNT(*) AS customers, SUM(churn_flag) AS churned,
    ROUND(SUM(churn_flag) / COUNT(*) * 100, 2) AS churn_rate_percent
FROM telco_churn
GROUP BY number_of_services
ORDER BY number_of_services;

SELECT * FROM vw_churn_by_services;

## 7)Top churn reasons
CREATE VIEW vw_top_churn_reasons AS
SELECT churn_reason, COUNT(*) AS churned_customers
FROM telco_churn
WHERE churn_flag = 1 AND churn_reason IS NOT NULL
GROUP BY churn_reason
ORDER BY churned_customers DESC
LIMIT 10;

SELECT * FROM vw_top_churn_reasons;


### KPI List ###
SELECT * FROM churn_overview;
SELECT * FROM churn_by_tenure;
SELECT * FROM vw_churn_by_contract;
SELECT * FROM vw_churn_by_value;
SELECT * FROM vw_revenue_at_risk;
SELECT * FROM vw_churn_by_services;
SELECT * FROM vw_top_churn_reasons;



## Churn rate by high value status
SELECT
    high_value_customer,
    COUNT(*) AS customers,
    SUM(churn_flag) AS churned,
    ROUND(SUM(churn_flag) / COUNT(*) * 100, 2) AS churn_rate_percent
FROM telco_churn
GROUP BY high_value_customer;

## Revenue at risk - high value customers only 
SELECT SUM(monthly_charges) AS high_value_revenue_at_risk
FROM telco_churn
WHERE churn_flag = 1
  AND high_value_customer = 1;






