-- Per-request telemetry for the focus-del-giorno LLM call. Metadata only —
-- no user content, no prompt text, no suggestion text. This is what backs
-- cost/latency/safety-rate monitoring, distinct from safety_events (which is
-- specifically the safety-layer audit trail).
create table llm_call_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  model text not null,
  prompt_version text not null,
  latency_ms integer,
  token_input integer,
  token_output integer,
  estimated_cost_usd numeric(10, 6),
  error text,
  safety_category text
);

alter table llm_call_logs enable row level security;

create policy "Users manage their own llm call logs"
  on llm_call_logs
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Aggregate view over the last 7 days. security_invoker means it respects
-- the RLS of the querying role: a normal user sees only their own calls
-- aggregated; querying as postgres/service_role (e.g. from the SQL Editor)
-- bypasses RLS as usual and sees everything.
create view llm_call_logs_summary_7d
with (security_invoker = true) as
select
  count(*) as total_calls,
  count(*) filter (where error is not null) as error_count,
  round(
    100.0 * count(*) filter (where safety_category is not null and safety_category != 'wellness_recommendation')
      / nullif(count(*), 0),
    1
  ) as safety_flag_rate_pct,
  round(avg(latency_ms)) as avg_latency_ms,
  round(avg(estimated_cost_usd), 6) as avg_cost_usd,
  round(sum(estimated_cost_usd), 4) as total_cost_usd
from llm_call_logs
where created_at >= now() - interval '7 days';
