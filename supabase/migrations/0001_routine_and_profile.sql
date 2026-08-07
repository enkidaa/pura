-- Raw log: one row per step completed on a given day.
-- This is the source of truth; the AI never reads this table wholesale,
-- only aggregated queries computed on demand (e.g. "last 7 days completion rate").
create table routine_completions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  step_id text not null,
  completed_on date not null,
  created_at timestamptz not null default now(),
  unique (user_id, step_id, completed_on)
);

alter table routine_completions enable row level security;

create policy "Users manage their own routine completions"
  on routine_completions
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- One row per user: the AI-written narrative digest ("pattern" summary),
-- refreshed periodically by the Edge Function (not on every request).
create table profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  narrative_summary text,
  narrative_updated_at timestamptz
);

alter table profiles enable row level security;

create policy "Users manage their own profile"
  on profiles
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
