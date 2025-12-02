-- Add RLS policies for subscription_installments table

-- Enable RLS on subscription_installments
ALTER TABLE subscription_installments ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own installments" ON subscription_installments;
DROP POLICY IF EXISTS "Service can insert installments" ON subscription_installments;
DROP POLICY IF EXISTS "Service can update installments" ON subscription_installments;

-- Policy: Users can view their own installments
CREATE POLICY "Users can view own installments"
ON subscription_installments
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM subscriptions
    WHERE subscriptions.id = subscription_installments.subscription_id
    AND subscriptions.user_id = auth.uid()
  )
);

-- Policy: Service role can insert installments
CREATE POLICY "Service can insert installments"
ON subscription_installments
FOR INSERT
WITH CHECK (true);

-- Policy: Service role can update installments
CREATE POLICY "Service can update installments"
ON subscription_installments
FOR UPDATE
USING (true);
