-- Audit trail for the safety layer: records when a generated suggestion was
-- passed through unchanged, modified, or its category escalated — never the
-- actual suggestion text/content, only categories and the action taken.
create table safety_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  model_category text not null,
  final_category text not null,
  action text not null check (action in ('passthrough', 'modified')),
  created_at timestamptz not null default now()
);

alter table safety_events enable row level security;

create policy "Users manage their own safety events"
  on safety_events
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
