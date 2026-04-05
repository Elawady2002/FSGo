-- Migration: 002_driver_onboarding
-- Feature: Driver & Coordinator Platform Onboarding
-- Branch: 002-driver-onboarding
-- Date: 2026-04-05

-- 1. Add new role values to user_type check constraint
-- (If user_type is a text column with a CHECK constraint, update it)
ALTER TABLE users
  DROP CONSTRAINT IF EXISTS users_user_type_check;

ALTER TABLE users
  ADD CONSTRAINT users_user_type_check
  CHECK (user_type IN ('student', 'driver', 'admin', 'station_owner', 'office_owner'));

-- 2. Add office_name column (for office_owner registrations)
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS office_name TEXT;

-- 3. Add station_name column (for station_owner registrations)
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS station_name TEXT;

-- 4. (Optional) Create a separate offices table for richer data
CREATE TABLE IF NOT EXISTS offices (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  owner_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. (Optional) Create a separate stations table for richer data
CREATE TABLE IF NOT EXISTS stations (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  owner_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  location    POINT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Enable RLS on new tables
ALTER TABLE offices ENABLE ROW LEVEL SECURITY;
ALTER TABLE stations ENABLE ROW LEVEL SECURITY;

-- 7. RLS policies: owners can read/write their own records
CREATE POLICY "office_owner_access" ON offices
  FOR ALL USING (auth.uid() = owner_id);

CREATE POLICY "station_owner_access" ON stations
  FOR ALL USING (auth.uid() = owner_id);
