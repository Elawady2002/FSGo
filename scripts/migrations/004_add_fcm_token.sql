-- Migration 004: Add FCM token column to users table
-- Run in Supabase Dashboard → SQL Editor

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Index for quick lookups when sending targeted notifications
CREATE INDEX IF NOT EXISTS idx_users_fcm_token
  ON public.users(fcm_token)
  WHERE fcm_token IS NOT NULL;
