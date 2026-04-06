-- ============================================================
-- Migration 003: Multi-Role Platform
-- Adds coordinator workflow fields and office subscription plans
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

-- Only admin can set is_approved — block coordinator from flipping it directly
-- (Enforce via RLS: coordinators may INSERT/UPDATE other fields but not is_approved)
CREATE POLICY IF NOT EXISTS "Coordinators cannot approve own schedules"
  ON public.schedules
  FOR UPDATE
  USING (auth.uid() = coordinator_id)
  WITH CHECK (is_approved = OLD.is_approved);  -- cannot change is_approved

-- Coordinators can read their own schedules
CREATE POLICY IF NOT EXISTS "Coordinators read own schedules"
  ON public.schedules FOR SELECT
  USING (auth.uid() = coordinator_id OR auth.uid() = driver_id);

-- Coordinators can insert schedules
CREATE POLICY IF NOT EXISTS "Coordinators insert schedules"
  ON public.schedules FOR INSERT
  WITH CHECK (auth.uid() = coordinator_id);

-- 2. Add boarding_status to bookings for passenger check-in
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS boarding_status TEXT NOT NULL DEFAULT 'booked'
    CHECK (boarding_status IN ('booked', 'boarded'));

-- 3. Create office_subscription_plans table
CREATE TABLE IF NOT EXISTS public.office_subscription_plans (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  coordinator_id  UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  plan_name       TEXT        NOT NULL,
  plan_type       TEXT        NOT NULL CHECK (plan_type IN ('monthly', 'semester')),
  price           NUMERIC(10,2) NOT NULL,
  duration_days   INT         NOT NULL,
  max_students    INT,
  is_active       BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.office_subscription_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "Coordinators manage own plans"
  ON public.office_subscription_plans
  USING (auth.uid() = coordinator_id)
  WITH CHECK (auth.uid() = coordinator_id);

-- 4. Index for fast driver-duty lookups
CREATE INDEX IF NOT EXISTS idx_schedules_driver_id
  ON public.schedules(driver_id)
  WHERE driver_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_schedules_coordinator_id
  ON public.schedules(coordinator_id)
  WHERE coordinator_id IS NOT NULL;
