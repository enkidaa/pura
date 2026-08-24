-- Practice catalog itself lives in Dart (lib/models/practice_catalog.dart) —
-- this table is only "is this practice in my routine" membership. Notes and
-- user sources reuse the existing generic routine_step_notes/sources
-- tables (already keyed by arbitrary text id), no new tables needed there.
create table practice_routine (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  practice_id text not null,
  added_at timestamptz not null default now(),
  unique (user_id, practice_id)
);

alter table practice_routine enable row level security;

create policy "Users manage their own practice routine"
  on practice_routine
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
