ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

-- Public athlete profiles also contain the secret used to authenticate agent APIs.
-- Explicit column grants keep that field and future private fields server-only.
REVOKE ALL PRIVILEGES ON public.profiles FROM PUBLIC, anon, authenticated;
REVOKE ALL PRIVILEGES (api_key) ON public.profiles FROM PUBLIC, anon, authenticated;
GRANT SELECT (
  id, username, display_name, bio, sport, avatar_url, strava_url, instagram_url,
  created_at, updated_at, onboarding_completed, role, tour_version_completed,
  type, monad_wallet_address, is_agent
) ON public.profiles TO anon, authenticated;
GRANT INSERT (
  id, username, display_name, bio, sport, avatar_url, strava_url, instagram_url,
  onboarding_completed, role, tour_version_completed, monad_wallet_address
), UPDATE (
  id, username, display_name, bio, sport, avatar_url, strava_url, instagram_url,
  onboarding_completed, role, tour_version_completed, monad_wallet_address
) ON public.profiles TO authenticated;

DROP POLICY IF EXISTS profiles_select_all ON public.profiles;
CREATE POLICY profiles_select_all ON public.profiles
  FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS profiles_upsert_self ON public.profiles;
CREATE POLICY profiles_upsert_self ON public.profiles
  FOR INSERT TO authenticated WITH CHECK (id = (SELECT auth.uid()));
DROP POLICY IF EXISTS profiles_update_self ON public.profiles;
CREATE POLICY profiles_update_self ON public.profiles
  FOR UPDATE TO authenticated USING (id = (SELECT auth.uid()))
  WITH CHECK (id = (SELECT auth.uid()));

-- Workout access uses the recorded holding. Only settlement code may change it.
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON public.holdings
  FROM PUBLIC, anon, authenticated;
DROP POLICY IF EXISTS holdings_insert_own ON public.holdings;
DROP POLICY IF EXISTS holdings_update_own ON public.holdings;
DROP POLICY IF EXISTS holdings_write_own ON public.holdings;
DROP POLICY IF EXISTS holdings_delete_own ON public.holdings;

-- The trade Edge Function calculates and checks these arguments server-side.
REVOKE EXECUTE ON FUNCTION public.execute_trade_transaction(
  uuid, uuid, public.trade_side, integer, numeric, numeric, numeric, integer,
  numeric, numeric, numeric, uuid, numeric, numeric, numeric
) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.execute_trade_transaction(
  uuid, uuid, public.trade_side, integer, numeric, numeric, numeric, integer,
  numeric, numeric, numeric, uuid, numeric, numeric, numeric
) TO service_role;

REVOKE TRUNCATE, REFERENCES, TRIGGER ON public.posts FROM PUBLIC, anon, authenticated;
