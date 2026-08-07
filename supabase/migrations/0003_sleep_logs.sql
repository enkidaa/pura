-- One row per night. sleep_date = the morning this record is "for"
-- (e.g. bedtime 23:30 on Mon + wake 07:00 Tue -> sleep_date = Tue).
create table sleep_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  sleep_date date not null,
  bedtime timestamptz not null,
  wake_time timestamptz not null,
  created_at timestamptz not null default now(),
  unique (user_id, sleep_date)
);

alter table sleep_logs enable row level security;

create policy "Users manage their own sleep logs"
  on sleep_logs
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
