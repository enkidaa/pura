-- Documents (referti, ecc.) the user uploads for the AI to consider
-- when generating "Focus del giorno" (e.g. a nutritionist's report).
create table user_documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  storage_path text not null,
  label text not null,
  mime_type text not null,
  uploaded_at timestamptz not null default now()
);

alter table user_documents enable row level security;

create policy "Users manage their own documents"
  on user_documents
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

insert into storage.buckets (id, name, public)
values ('user-documents', 'user-documents', false);

create policy "Users manage their own document files"
  on storage.objects
  for all
  using (
    bucket_id = 'user-documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'user-documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
