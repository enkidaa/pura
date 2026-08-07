-- Ingredients the user currently has on hand.
create table user_ingredients (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  ingredient text not null,
  created_at timestamptz not null default now(),
  unique (user_id, ingredient)
);

alter table user_ingredients enable row level security;

create policy "Users manage their own ingredients"
  on user_ingredients
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Log of mixes the user has made (diary).
create table mix_diary_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  mix_name text not null,
  made_at timestamptz not null default now()
);

alter table mix_diary_logs enable row level security;

create policy "Users manage their own mix diary"
  on mix_diary_logs
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
