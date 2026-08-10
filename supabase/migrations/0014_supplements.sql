-- Replaces the old ingredient/mix "Lab" concept with a real supplement
-- tracker: what the user takes, categorized naturale/scientifico, and a
-- daily intake log (same pattern as routine_completions).
create table user_supplements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  category text not null check (category in ('natural', 'scientific')),
  created_at timestamptz not null default now(),
  unique (user_id, name)
);

alter table user_supplements enable row level security;

create policy "Users manage their own supplements"
  on user_supplements
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create table supplement_intake_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  supplement_id uuid not null references user_supplements (id) on delete cascade,
  taken_on date not null,
  created_at timestamptz not null default now(),
  unique (user_id, supplement_id, taken_on)
);

alter table supplement_intake_logs enable row level security;

create policy "Users manage their own supplement intake logs"
  on supplement_intake_logs
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
