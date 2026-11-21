-- Run after migrations on a local database with the Supabase API roles.
DO $test$
DECLARE
  api_role text;
  relation_name text;
  privilege_name text;
BEGIN
  FOREACH api_role IN ARRAY ARRAY['anon', 'authenticated'] LOOP
    FOREACH relation_name IN ARRAY ARRAY[
      'prediction_markets', 'market_outcomes', 'prediction_results', 'market_bets',
      'market_activity', 'prediction_credits', 'prediction_entries', 'prediction_wallet_locks',
      'prediction_market_resolutions', 'wallet_ledger', 'holdings'
    ] LOOP
      FOREACH privilege_name IN ARRAY ARRAY['INSERT', 'UPDATE', 'DELETE', 'TRUNCATE'] LOOP
        IF has_table_privilege(api_role, 'public.' || relation_name, privilege_name) THEN
          RAISE EXCEPTION '% has unexpected % on %', api_role, privilege_name, relation_name;
        END IF;
      END LOOP;
    END LOOP;
    IF has_column_privilege(api_role, 'public.profiles', 'api_key', 'SELECT,INSERT,UPDATE')
       OR NOT has_column_privilege(api_role, 'public.profiles', 'display_name', 'SELECT') THEN
      RAISE EXCEPTION 'Unexpected profile column permissions for %', api_role;
    END IF;
    IF has_function_privilege(api_role, 'public.resolve_prediction_market(uuid,uuid)', 'EXECUTE')
       OR has_function_privilege(api_role, 'public.execute_trade_transaction(uuid,uuid,public.trade_side,integer,numeric,numeric,numeric,integer,numeric,numeric,numeric,uuid,numeric,numeric,numeric)', 'EXECUTE') THEN
      RAISE EXCEPTION 'Unexpected settlement permissions for %', api_role;
    END IF;
  END LOOP;
  IF EXISTS (SELECT FROM pg_class WHERE oid IN ('public.profiles'::regclass, 'public.posts'::regclass) AND NOT relrowsecurity)
     OR EXISTS (SELECT FROM pg_proc WHERE oid IN ('public.get_prediction_locked_balance(uuid)'::regprocedure, 'public.get_prediction_wallet_summary(uuid)'::regprocedure) AND prosecdef) THEN
    RAISE EXCEPTION 'Owner or wallet visibility rules are inactive';
  END IF;
  IF NOT has_column_privilege('authenticated', 'public.profiles', 'display_name', 'UPDATE')
     OR NOT has_function_privilege('authenticated', 'public.place_prediction_bet(uuid,uuid,uuid,integer)', 'EXECUTE')
     OR NOT has_function_privilege('service_role','public.resolve_prediction_market(uuid,uuid)','EXECUTE') THEN
    RAISE EXCEPTION 'Expected application permissions are missing';
  END IF;
END;
$test$;
