-- ============================================================
-- Il logo del club (proposta 17, passo A): un file per club, PNG o
-- JPG fino a 1 MB, in uno spazio privato, sempre in
-- «<club_id>/logo». Va in testa ai PDF dell'app.
-- Lo vedono lo staff e gli atleti del club; lo mette, lo cambia e lo
-- toglie solo il capo allenatore (il responsabile, ruolo owner).
-- ============================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('loghi_club', 'loghi_club', false, 1048576, array['image/png', 'image/jpeg'])
on conflict (id) do nothing;

-- La cartella è il club come testo: niente conversioni a uuid, che
-- fallirebbero sui file degli altri spazi.
create or replace function public.logo_club_visibile(p_cartella text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.club_membri
    where club_id::text = p_cartella and user_id = auth.uid()
  ) or exists (
    select 1 from public.atleti
    where club_id::text = p_cartella and user_id = auth.uid()
  );
$$;

create or replace function public.logo_club_modificabile(p_cartella text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.club_membri
    where club_id::text = p_cartella
      and user_id = auth.uid()
      and ruolo = 'owner'
  );
$$;

grant execute on function public.logo_club_visibile(text) to authenticated;
grant execute on function public.logo_club_modificabile(text) to authenticated;

create policy loghi_club_select on storage.objects
  for select to authenticated
  using (
    bucket_id = 'loghi_club'
    and public.logo_club_visibile((storage.foldername(name))[1])
  );

create policy loghi_club_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'loghi_club'
    and name = (storage.foldername(name))[1] || '/logo'
    and public.logo_club_modificabile((storage.foldername(name))[1])
  );

create policy loghi_club_update on storage.objects
  for update to authenticated
  using (
    bucket_id = 'loghi_club'
    and public.logo_club_modificabile((storage.foldername(name))[1])
  )
  with check (
    bucket_id = 'loghi_club'
    and name = (storage.foldername(name))[1] || '/logo'
    and public.logo_club_modificabile((storage.foldername(name))[1])
  );

create policy loghi_club_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'loghi_club'
    and public.logo_club_modificabile((storage.foldername(name))[1])
  );
