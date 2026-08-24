-- Ritual nodes now open a detail screen (same pattern as Integratori):
-- personal notes + user-added sources per step.
create table routine_step_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  step_id text not null,
  note text not null default '',
  updated_at timestamptz not null default now(),
  unique (user_id, step_id)
);

alter table routine_step_notes enable row level security;

create policy "Users manage their own routine step notes"
  on routine_step_notes
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create table routine_step_sources (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  step_id text not null,
  source text not null,
  created_at timestamptz not null default now()
);

alter table routine_step_sources enable row level security;

create policy "Users manage their own routine step sources"
  on routine_step_sources
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
