-- Enable RLS on subscriptions table
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- Policy to allow users to view their own subscriptions
DROP POLICY IF EXISTS "Users can view their own subscriptions" ON subscriptions;
CREATE POLICY "Users can view their own subscriptions"
ON subscriptions FOR SELECT
USING (auth.uid() = user_id);

-- Policy to allow users to insert their own subscriptions
DROP POLICY IF EXISTS "Users can insert their own subscriptions" ON subscriptions;
CREATE POLICY "Users can insert their own subscriptions"
ON subscriptions FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy to allow users to update their own subscriptions (e.g. for payment proof)
DROP POLICY IF EXISTS "Users can update their own subscriptions" ON subscriptions;
CREATE POLICY "Users can update their own subscriptions"
ON subscriptions FOR UPDATE
USING (auth.uid() = user_id);
