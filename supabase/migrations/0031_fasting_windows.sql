-- fasting_logs (see migration 0030) now only holds the *current* open
-- phase, so there's no more per-day history to compute trends from. This
-- table is the actual history: one row per *completed* window (a finished
-- fast or a finished eating window), written when the toggle button closes
-- one — real data for the AI digest to reason about (e.g. "average fasting
-- window over the last 7 days"), not a fragile cross-day reconstruction.
create table fasting_windows (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  kind text not null check (kind in ('fast', 'eating')),
  started_at timestamptz not null,
  ended_at timestamptz not null,
  created_at timestamptz not null default now()
);

alter table fasting_windows enable row level security;

create policy "Users manage their own fasting windows"
  on fasting_windows
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
