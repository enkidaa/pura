create table supplement_reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  supplement_id text not null,
  weekdays int[] not null,
  hour int not null,
  minute int not null,
  enabled boolean not null default true,
  updated_at timestamptz not null default now(),
  unique (user_id, supplement_id)
);

alter table supplement_reminders enable row level security;

create policy "Users manage their own supplement reminders"
  on supplement_reminders for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
