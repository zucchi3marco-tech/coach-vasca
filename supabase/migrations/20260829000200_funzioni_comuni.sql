-- Funzione generica per aggiornare updated_at su ogni UPDATE.
-- Usata dal trigger set_updated_at su tutte le tabelle applicative
-- (supporta la strategia last-write-wins della sync offline, vedi ROADMAP.md).
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
