create table supplement_routine (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  supplement_id text not null,
  added_at timestamptz not null default now(),
  unique (user_id, supplement_id)
);

alter table supplement_routine enable row level security;

create policy "Users manage their own supplement routine"
  on supplement_routine for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
