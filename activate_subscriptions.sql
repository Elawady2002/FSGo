-- Update all subscriptions to be active for testing
-- Using correct column names: status, start_date, end_date

UPDATE subscriptions
SET 
  status = 'active',
  start_date = NOW(),
  end_date = NOW() + INTERVAL '30 days'
WHERE status = 'pending';
