-- Un quarto stato per la presenza: 'ritardo' (arrivato dopo l'inizio).
--
-- Perché: all'appello il coach voleva distinguere chi arriva in ritardo da
-- chi c'è dall'inizio, senza perderlo fra i presenti.
--
-- Per l'app «in ritardo» CONTA COME PRESENTE ovunque (carico, percentuali,
-- statistiche, Excel, assistente, home dell'atleta): si mostra e si conta
-- a parte, ma non è mai un'assenza. La regola sta in
-- `contaComePresente` (lib/features/presenze/domain/presenza.dart).
--
-- Nessuna funzione o policy SQL confronta lo stato con 'presente', quindi
-- non serve altro. `add value` non può stare dentro un blocco di
-- transazione insieme a un uso del valore nuovo: qui non lo si usa.

alter type public.stato_presenza add value if not exists 'ritardo' after 'presente';
