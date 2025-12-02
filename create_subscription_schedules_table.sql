-- Create subscription_schedules table to store daily trip schedules for subscriptions

-- Drop existing policies first
DROP POLICY IF EXISTS "Users can view own schedules" ON subscription_schedules;
DROP POLICY IF EXISTS "Users can insert own schedules" ON subscription_schedules;
DROP POLICY IF EXISTS "Users can update own schedules" ON subscription_schedules;
DROP POLICY IF EXISTS "Users can delete own schedules" ON subscription_schedules;

-- Create table if not exists
CREATE TABLE IF NOT EXISTS subscription_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
  trip_date DATE NOT NULL,
  trip_type TEXT NOT NULL CHECK (trip_type IN ('departure_only', 'return_only', 'round_trip')),
  departure_time TEXT,
  return_time TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(subscription_id, trip_date)
);

-- Enable RLS
ALTER TABLE subscription_schedules ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own schedules
CREATE POLICY "Users can view own schedules"
ON subscription_schedules
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM subscriptions
    WHERE subscriptions.id = subscription_schedules.subscription_id
    AND subscriptions.user_id = auth.uid()
  )
);

-- Policy: Users can insert their own schedules
CREATE POLICY "Users can insert own schedules"
ON subscription_schedules
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM subscriptions
    WHERE subscriptions.id = subscription_schedules.subscription_id
    AND subscriptions.user_id = auth.uid()
  )
);

-- Policy: Users can update their own schedules
CREATE POLICY "Users can update own schedules"
ON subscription_schedules
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM subscriptions
    WHERE subscriptions.id = subscription_schedules.subscription_id
    AND subscriptions.user_id = auth.uid()
  )
);

-- Policy: Users can delete their own schedules
CREATE POLICY "Users can delete own schedules"
ON subscription_schedules
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM subscriptions
    WHERE subscriptions.id = subscription_schedules.subscription_id
    AND subscriptions.user_id = auth.uid()
  )
);

-- Create index for faster queries (only if they don't exist)
CREATE INDEX IF NOT EXISTS idx_subscription_schedules_subscription_id ON subscription_schedules(subscription_id);
CREATE INDEX IF NOT EXISTS idx_subscription_schedules_trip_date ON subscription_schedules(trip_date);
