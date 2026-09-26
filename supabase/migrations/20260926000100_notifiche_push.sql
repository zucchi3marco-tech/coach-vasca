-- ============================================================
-- NOTIFICHE PUSH (fase C1): oltre alla campanella, le notifiche
-- arrivano sul telefono anche ad app chiusa (Web Push).
--
-- 1) notifiche: destinatario personale opzionale (user_id), atleta
--    collegato, chiave anti-duplicato per le notifiche automatiche,
--    e traccia dell'invio push. Nuovi tipi per le fasi successive.
-- 2) push_subscriptions: un'iscrizione per browser/telefono.
-- L'invio lo fa la Edge Function `invia-push`, chiamata da un
-- Database Webhook sull'insert di `notifiche` (vedi supabase/README.md).
-- ============================================================

alter table public.notifiche
  add column user_id uuid references auth.users(id) on delete cascade,
  add column atleta_id uuid references public.atleti(id) on delete cascade,
  add column chiave text,
  add column push_inviata_at timestamptz;

alter table public.notifiche drop constraint notifiche_tipo_check;
alter table public.notifiche add constraint notifiche_tipo_check check (
  tipo in (
    'atleta_registrato',
    'convocazione_gara',
    'convocazione_partita',
    'visita_medica'
  )
);

-- Unico ma non parziale: i valori nulli (le notifiche senza chiave) non
-- confliggono fra loro, e un upsert ON CONFLICT (chiave) funziona anche da
-- PostgREST, che non sa indicare il predicato di un indice parziale.
create unique index idx_notifiche_chiave on public.notifiche(chiave);
create index idx_notifiche_user
  on public.notifiche(user_id) where user_id is not null;

-- user_id nullo = notifica per tutto il club (come finora); valorizzato =
-- personale: la vede solo quell'utente, non i coach del club.
drop policy notifiche_select on public.notifiche;
drop policy notifiche_update on public.notifiche;
drop policy notifiche_delete on public.notifiche;

create policy notifiche_select on public.notifiche
  for select using (
    (user_id is null and public.is_membro_club(club_id))
    or user_id = auth.uid()
  );

create policy notifiche_update on public.notifiche
  for update using (
    (user_id is null and public.is_membro_club(club_id))
    or user_id = auth.uid()
  ) with check (
    (user_id is null and public.is_membro_club(club_id))
    or user_id = auth.uid()
  );

create policy notifiche_delete on public.notifiche
  for delete using (
    (user_id is null and public.is_membro_club(club_id))
    or user_id = auth.uid()
  );

-- ------------------------------------------------------------
-- push_subscriptions
-- ------------------------------------------------------------

create table public.push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  endpoint text not null unique,
  p256dh text not null,
  auth_key text not null,
  user_agent text,
  created_at timestamptz not null default now()
);

create index idx_push_subscriptions_user on public.push_subscriptions(user_id);

alter table public.push_subscriptions enable row level security;

create policy push_subscriptions_select on public.push_subscriptions
  for select using (user_id = auth.uid());

create policy push_subscriptions_delete on public.push_subscriptions
  for delete using (user_id = auth.uid());

-- Le scritture passano da queste funzioni: lo stesso telefono puo' passare
-- da un account all'altro (stesso endpoint), cosa che un upsert diretto
-- bloccherebbe con le regole di accesso.
create or replace function public.registra_push_subscription(
  p_endpoint text,
  p_p256dh text,
  p_auth_key text,
  p_user_agent text default null
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Utente non autenticato';
  end if;
  insert into public.push_subscriptions (user_id, endpoint, p256dh, auth_key, user_agent)
  values (auth.uid(), p_endpoint, p_p256dh, p_auth_key, p_user_agent)
  on conflict (endpoint) do update
    set user_id = excluded.user_id,
        p256dh = excluded.p256dh,
        auth_key = excluded.auth_key,
        user_agent = excluded.user_agent;
end;
$$;

revoke all on function public.registra_push_subscription(text, text, text, text) from public;
grant execute on function public.registra_push_subscription(text, text, text, text) to authenticated;
