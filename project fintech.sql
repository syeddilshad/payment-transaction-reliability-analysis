-- 1. Create the Users Table
CREATE TABLE users (
    user_id VARCHAR(20) PRIMARY KEY,
    user_name VARCHAR(100),
    registration_date DATE,
    account_tier VARCHAR(20),
    kyc_status VARCHAR(20)
);

-- 2. Create the Gateways Table
CREATE TABLE gateways (
    gateway_id VARCHAR(20) PRIMARY KEY,
    gateway_name VARCHAR(50),
    bank_code VARCHAR(10),
    is_active BOOLEAN DEFAULT TRUE
);

-- 3. Create the Transactions Table (Linked to Users and Gateways)
CREATE TABLE transactions (
    txn_id VARCHAR(30) PRIMARY KEY,
    user_id VARCHAR(20) REFERENCES users(user_id),
    gateway_id VARCHAR(20) REFERENCES gateways(gateway_id),
    amount DECIMAL(10, 2),
    currency VARCHAR(5) DEFAULT 'INR',
    txn_status VARCHAR(15),
    error_code VARCHAR(30),
    decline_type VARCHAR(20),
    txn_timestamp TIMESTAMP
);

-- Insert Sample Users
INSERT INTO users VALUES 
('U101', 'Syed Dilshad', '2026-01-15', 'Premium', 'Verified'),
('U102', 'Rohan Sharma', '2026-03-22', 'Standard', 'Verified'),
('U103', 'Ananya Roy', '2026-05-10', 'Standard', 'Pending'),
('U104', 'Priya Patel', '2026-06-01', 'VIP', 'Verified');

-- Insert Sample Gateways
INSERT INTO gateways VALUES 
('GW_HDFC', 'HDFC Payment Gateway', 'HDFC', TRUE),
('GW_ICICI', 'ICICI Payment Gateway', 'ICICI', TRUE),
('GW_RZP', 'Razorpay Gateway', 'RZP', TRUE);

-- Insert Sample Transactions
INSERT INTO transactions VALUES 
('TXN001', 'U101', 'GW_HDFC', 1500.00, 'INR', 'SUCCESS', NULL, 'None', '2026-10-01 10:00:00'),
('TXN002', 'U102', 'GW_HDFC', 450.00, 'INR', 'FAILED', 'BANK_TIMEOUT', 'Technical Decline', '2026-10-01 10:05:00'),
('TXN003', 'U103', 'GW_ICICI', 200.00, 'INR', 'FAILED', 'INSUFFICIENT_FUNDS', 'Business Decline', '2026-10-01 10:10:00'),
('TXN004', 'U101', 'GW_HDFC', 3200.00, 'INR', 'FAILED', 'BANK_TIMEOUT', 'Technical Decline', '2026-10-01 10:12:00'),
('TXN005', 'U104', 'GW_RZP', 12000.00, 'INR', 'SUCCESS', NULL, 'None', '2026-10-01 10:15:00'),
('TXN006', 'U102', 'GW_HDFC', 500.00, 'INR', 'FAILED', 'BANK_TIMEOUT', 'Technical Decline', '2026-10-01 10:20:00'),
('TXN007', 'U103', 'GW_ICICI', 150.00, 'INR', 'SUCCESS', NULL, 'None', '2026-10-01 10:25:00');

SELECT * FROM users;
SELECT * FROM gateways;
SELECT * FROM transactions;

SELECT 
      g.gateway_name,
	  COUNT(t.txn_id) AS total_transactions,
	  SUM(CASE WHEN t.txn_status='SUCCESS' THEN 1 ELSE 0 END)AS successful_txns,
	  SUM(CASE WHEN t.decline_type='Technical Decline' THEN 1 ELSE 0 END) AS tech_declines,
	  SUM(CASE WHEN t.decline_type='Business Decline' THEN 1 ELSE 0 END) AS biz_declines,
	  ROUND(
           (SUM(CASE WHEN t.txn_status='SUCCESS' THEN 1 ELSE 0 END)*100.0)/ COUNT(t.txn_id),
		   2
	 )AS success_rate_pct
FROM transactions t
JOIN gateways g ON t.gateway_id=g.gateway_id
GROUP BY g.gateway_name
ORDER BY success_rate_pct DESC;


WITH hourly_failures AS(
     SELECT 
	       DATE_TRUNC('hour',txn_timestamp) AS txn_hour,
		   gateway_id,
		   error_code,
		   COUNT(txn_id) AS failure_count,
		   DENSE_RANK() OVER(
                PARTITION BY DATE_TRUNC('hour',txn_timestamp)
				ORDER BY COUNT(txn_id)DESC
		   )AS error_rank
	 FROM transactions
	 WHERE txn_status='FAILED'
	 GROUP BY DATE_TRUNC('hour',txn_timestamp),gateway_id,error_code
)

SELECT 
      txn_hour,
	  gateway_id,
      error_code,
	  failure_count
FROM hourly_failures
WHERE error_rank = 1
ORDER BY txn_hour DESC;


