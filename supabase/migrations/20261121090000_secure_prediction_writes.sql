-- Public clients read market data. Privileged routines own changes to market state.
DROP POLICY IF EXISTS "Markets insertable by service role" ON public.prediction_markets;
DROP POLICY IF EXISTS "Markets updatable by service role" ON public.prediction_markets;
DROP POLICY IF EXISTS "Outcomes insertable by service role" ON public.market_outcomes;
DROP POLICY IF EXISTS "Outcomes updatable by service role" ON public.market_outcomes;
DROP POLICY IF EXISTS "Results insertable by service role" ON public.prediction_results;
DROP POLICY IF EXISTS "Results updatable by service role" ON public.prediction_results;
DROP POLICY IF EXISTS "Service role can insert bets" ON public.market_bets;
DROP POLICY IF EXISTS "Service can insert activity" ON public.market_activity;
DROP POLICY IF EXISTS "Authenticated can insert credits" ON public.prediction_credits;
DROP POLICY IF EXISTS "Credits updatable" ON public.prediction_credits;

REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON
  public.prediction_markets, public.market_outcomes, public.prediction_results,
  public.market_bets, public.market_activity, public.prediction_credits,
  public.prediction_entries, public.prediction_wallet_locks,
  public.prediction_market_resolutions, public.wallet_ledger
  FROM PUBLIC, anon, authenticated;

-- The existing profile trigger handles future users. Preserve all accrued balances.
INSERT INTO public.prediction_credits (user_id, balance)
SELECT id, 1000 FROM public.profiles
ON CONFLICT (user_id) DO NOTHING;

-- These read-only helpers must honor the caller's wallet and prediction lock policies.
ALTER FUNCTION public.get_prediction_locked_balance(uuid) SECURITY INVOKER;
ALTER FUNCTION public.get_prediction_wallet_summary(uuid) SECURITY INVOKER;

REVOKE EXECUTE ON FUNCTION
  public.get_prediction_locked_balance(uuid), public.get_prediction_wallet_summary(uuid),
  public.place_prediction_bet(uuid, uuid, uuid, integer),
  public.place_prediction_entry_v2(uuid, uuid, numeric, uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION
  public.get_prediction_locked_balance(uuid), public.get_prediction_wallet_summary(uuid),
  public.place_prediction_bet(uuid, uuid, uuid, integer),
  public.place_prediction_entry_v2(uuid, uuid, numeric, uuid)
  TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION
  public.resolve_prediction_market(uuid, uuid),
  public.resolve_prediction_market_v2(uuid, uuid, text, text, jsonb, text),
  public.cancel_prediction_market_v2(uuid, text, jsonb, text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION
  public.resolve_prediction_market(uuid, uuid),
  public.resolve_prediction_market_v2(uuid, uuid, text, text, jsonb, text),
  public.cancel_prediction_market_v2(uuid, text, jsonb, text)
  TO service_role;
