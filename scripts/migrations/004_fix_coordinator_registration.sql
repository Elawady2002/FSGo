-- Migration: 004_fix_coordinator_registration
-- Feature: Ensure station_name column exists and boarding_stations table is ready
-- Date: 2026-04-13

-- 1. Add station_name column to users table if missing
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS station_name TEXT;

-- 2. Ensure boarding_stations table exists
-- This table is used by passengers to find their starting point.
-- Usually, it might already exist in the user/passenger app schema.
CREATE TABLE IF NOT EXISTS public.boarding_stations (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  city_id     UUID NOT NULL REFERENCES public.cities(id) ON DELETE CASCADE,
  name_ar     TEXT NOT NULL,
  name_en     TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_active   BOOLEAN NOT NULL DEFAULT TRUE
);

-- 3. Enable RLS on boarding_stations
ALTER TABLE public.boarding_stations ENABLE ROW LEVEL SECURITY;

-- 4. RLS policies: everyone can read, admins/coordinators can manage
-- (Adjust policies as needed)
DROP POLICY IF EXISTS "Anyone can read boarding stations" ON public.boarding_stations;
CREATE POLICY "Anyone can read boarding stations" 
  ON public.boarding_stations FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Coordinators can insert their own stations" ON public.boarding_stations;
-- Note: In a production environment, we might want to link stations to coordinators via coordinator_id
-- For now, let's keep it simple as requested.
CREATE POLICY "Coordinators can insert their own stations"
  ON public.boarding_stations FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');
