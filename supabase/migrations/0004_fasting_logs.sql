-- One row per day. first_meal_time/last_meal_time set when the user taps
-- the corresponding button; either can be null until logged.
create table fasting_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  log_date date not null,
  first_meal_time timestamptz,
  last_meal_time timestamptz,
  created_at timestamptz not null default now(),
  unique (user_id, log_date)
);

alter table fasting_logs enable row level security;

create policy "Users manage their own fasting logs"
  on fasting_logs
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
