-- Integratori moves from a free-add list to a fixed catalog (copied from
-- the Lovable prototype's Pratiche > Integratori group) — supplement_id is
-- now a catalog string id ('sup-nad', ...) instead of a user_supplements
-- FK. user_supplements is left in place, just unused by the app now.
alter table supplement_intake_logs
  drop constraint if exists supplement_intake_logs_supplement_id_fkey;
alter table supplement_intake_logs
  alter column supplement_id type text using supplement_id::text;

create table supplement_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  supplement_id text not null,
  note text not null default '',
  updated_at timestamptz not null default now(),
  unique (user_id, supplement_id)
);

alter table supplement_notes enable row level security;

create policy "Users manage their own supplement notes"
  on supplement_notes
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create table supplement_sources (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  supplement_id text not null,
  source text not null,
  created_at timestamptz not null default now()
);

alter table supplement_sources enable row level security;

create policy "Users manage their own supplement sources"
  on supplement_sources
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
