-- Metadata row per photo; the file itself lives in Storage under
-- <user_id>/<log_date>_<period>.jpg — one photo per period per day.
create table skincare_photos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  log_date date not null,
  period text not null check (period in ('mattino', 'sera')),
  storage_path text not null,
  created_at timestamptz not null default now(),
  unique (user_id, log_date, period)
);

alter table skincare_photos enable row level security;

create policy "Users manage their own skincare photo rows"
  on skincare_photos
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Private bucket: photos are personal, never public.
insert into storage.buckets (id, name, public)
values ('skincare-photos', 'skincare-photos', false);

-- Objects are stored under <user_id>/... — restrict access to your own folder.
create policy "Users manage their own skincare photo files"
  on storage.objects
  for all
  using (
    bucket_id = 'skincare-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'skincare-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
