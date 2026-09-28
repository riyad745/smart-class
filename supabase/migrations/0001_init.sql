-- Smart Class backend schema (Phase 2: cloud sync).
-- Every table has row-level security so one account can never read or write
-- another account's data, even with a modified client.

create table if not exists public.file_nodes (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  parent_id uuid references public.file_nodes (id) on delete cascade,
  name text not null check (length(trim(name)) > 0),
  type text not null check (type in ('folder', 'pdf', 'board')),
  is_favorite boolean not null default false,
  size_bytes bigint not null default 0,
  last_opened_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz -- soft delete so other devices learn about deletions
);
create index if not exists file_nodes_user_updated on public.file_nodes (user_id, updated_at);

create table if not exists public.canvas_documents (
  file_id text not null, -- file id, or '<pdfId>_board' for a PDF's side board
  user_id uuid not null references auth.users (id) on delete cascade default auth.uid(),
  data jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, file_id)
);

create table if not exists public.preferences (
  user_id uuid primary key references auth.users (id) on delete cascade default auth.uid(),
  data jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.file_nodes enable row level security;
alter table public.canvas_documents enable row level security;
alter table public.preferences enable row level security;

create policy "own file nodes" on public.file_nodes
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own canvas documents" on public.canvas_documents
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own preferences" on public.preferences
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- PDF storage: objects live at pdfs/<user id>/<file id>.pdf
insert into storage.buckets (id, name, public)
values ('pdfs', 'pdfs', false)
on conflict (id) do nothing;

create policy "own pdfs" on storage.objects
  for all using (bucket_id = 'pdfs' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'pdfs' and (storage.foldername(name))[1] = auth.uid()::text);
