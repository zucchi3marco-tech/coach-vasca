-- Tipi enumerati condivisi dallo schema

create type public.ruolo_club as enum ('owner', 'coach', 'assistente');

create type public.sport as enum ('nuoto', 'pallanuoto');

create type public.tipo_test as enum ('BVS', 'T30');

-- Zone di intensita' standard citate nel roadmap (tabelle passi A1...D)
create type public.zona_intensita as enum ('A1', 'A2', 'B1', 'B2', 'C', 'D');

create type public.blocco_serie as enum ('riscaldamento', 'principale', 'defaticamento', 'altro');

create type public.stato_presenza as enum ('presente', 'assente', 'giustificato');
