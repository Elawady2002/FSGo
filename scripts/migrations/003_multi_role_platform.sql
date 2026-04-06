-- ============================================================
-- Migration 003: Multi-Role Platform
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================================

-- 1. Extend schedules table for coordinator workflow
ALTER TABLE public.schedules
  ADD COLUMN IF NOT EXISTS is_approved    BOOLEAN   NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS driver_id      UUID      REFERENCES public.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS coordinator_id UUID      REFERENCES public.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS origin         TEXT,
  ADD COLUMN IF NOT EXISTS destination    TEXT,
  ADD COLUMN IF NOT EXISTS base_fare      NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS admin_margin   NUMERIC(10,2) DEFAULT 0;

-- Make route_id nullable so coordinator schedules don't need a university route
ALTER TABLE public.schedules
  ALTER COLUMN route_id DROP NOT NULL;

-- 2. RLS policies for schedules (drop first to avoid duplicates)
DROP POLICY IF EXISTS "Coordinators read own schedules" ON public.schedules;
DROP POLICY IF EXISTS "Coordinators insert schedules"   ON public.schedules;

CREATE POLICY "Coordinators read own schedules"
  ON public.schedules FOR SELECT
  USING (auth.uid() = coordinator_id OR auth.uid() = driver_id);

CREATE POLICY "Coordinators insert schedules"
  ON public.schedules FOR INSERT
  WITH CHECK (auth.uid() = coordinator_id);

-- 3. Add boarding_status to bookings for passenger check-in
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS boarding_status TEXT NOT NULL DEFAULT 'booked'
    CHECK (boarding_status IN ('booked', 'boarded'));

-- 4. Create office_subscription_plans table
CREATE TABLE IF NOT EXISTS public.office_subscription_plans (
  id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  coordinator_id  UUID          NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  plan_name       TEXT          NOT NULL,
  plan_type       TEXT          NOT NULL CHECK (plan_type IN ('monthly', 'semester')),
  price           NUMERIC(10,2) NOT NULL,
  duration_days   INT           NOT NULL,
  max_students    INT,
  is_active       BOOLEAN       NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT now()
);

ALTER TABLE public.office_subscription_plans ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Coordinators manage own plans" ON public.office_subscription_plans;

CREATE POLICY "Coordinators manage own plans"
  ON public.office_subscription_plans
  USING (auth.uid() = coordinator_id)
  WITH CHECK (auth.uid() = coordinator_id);

-- 5. Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_schedules_driver_id
  ON public.schedules(driver_id)
  WHERE driver_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_schedules_coordinator_id
  ON public.schedules(coordinator_id)
  WHERE coordinator_id IS NOT NULL;
