-- One row per logged period start. Cycle length and current phase are
-- computed client/server-side from consecutive start dates, not stored.
create table menstrual_cycle_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  period_start_date date not null,
  created_at timestamptz not null default now(),
  unique (user_id, period_start_date)
);

alter table menstrual_cycle_logs enable row level security;

create policy "Users manage their own menstrual cycle logs"
  on menstrual_cycle_logs
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
