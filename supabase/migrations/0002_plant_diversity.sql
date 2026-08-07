-- One row per unique plant logged by the user. Weekly count = distinct
-- plant_name in the last 7 days, computed on the fly (same pattern as routines).
create table plant_diversity_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  plant_name text not null,
  logged_on date not null default current_date,
  created_at timestamptz not null default now()
);

alter table plant_diversity_logs enable row level security;

create policy "Users manage their own plant diversity logs"
  on plant_diversity_logs
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
