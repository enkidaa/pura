-- One link per day (Spotify/Apple Music/podcast url pasted by the user).
create table sound_links (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  log_date date not null,
  url text not null,
  created_at timestamptz not null default now(),
  unique (user_id, log_date)
);

alter table sound_links enable row level security;

create policy "Users manage their own sound links"
  on sound_links
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
