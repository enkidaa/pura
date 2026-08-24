-- "Quanto tempo hai?" — asked once at the first morning open and once in
-- the evening (~21:00), not every time. The most recent non-skipped
-- answer for today drives how many Ritual steps get suggested.
create table time_budgets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  day_part text not null check (day_part in ('morning', 'evening')),
  taken_on date not null default current_date,
  minutes integer,
  created_at timestamptz not null default now(),
  unique (user_id, day_part, taken_on)
);

alter table time_budgets enable row level security;

create policy "Users manage their own time budgets"
  on time_budgets
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
