-- Create subscription_installments table
CREATE TABLE IF NOT EXISTS subscription_installments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    subscription_id UUID REFERENCES subscriptions(id) ON DELETE CASCADE,
    amount NUMERIC NOT NULL,
    due_date TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT DEFAULT 'pending', -- pending, paid, overdue
    payment_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add columns to subscriptions table
ALTER TABLE subscriptions 
ADD COLUMN IF NOT EXISTS allow_location_change BOOLEAN DEFAULT FALSE;

ALTER TABLE subscriptions 
ADD COLUMN IF NOT EXISTS is_installment BOOLEAN DEFAULT FALSE;

ALTER TABLE subscriptions 
ADD COLUMN IF NOT EXISTS interest_rate NUMERIC DEFAULT 0;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_subscription_installments_subscription_id 
ON subscription_installments(subscription_id);

-- Refresh schema cache
NOTIFY pgrst, 'reload config';
