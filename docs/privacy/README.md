# Privacy e consenso genitori — bozza FASE 1

Questi documenti sono un **punto di partenza**, non un parere legale. Prima
di usarli con famiglie vere, farli rivedere da un consulente privacy/legale
(anche uno studio che segue già la società sportiva per gli aspetti FIN/CONI
puo' bastare).

## Chi e' il Titolare del trattamento

L'app e' multi-tenant: ogni **club** che usa SwimCoach FIN e' Titolare
autonomo dei dati dei propri atleti (non chi sviluppa l'app). Per questo
`informativa_privacy.md` ha dei placeholder tra `[...]` che ogni club deve
compilare con i propri dati reali (ragione sociale, indirizzo, email/PEC,
eventuale P.IVA/CF) prima di consegnarla alle famiglie.

Il fornitore del software (chi gestisce Supabase e il codice dell'app) agisce
come **Responsabile del trattamento** (art. 28 GDPR) per conto del club: in
V1, prima di andare in produzione con dati reali, serve un accordo scritto
di nomina a responsabile (DPA) — anche solo un modello standard — tra chi
gestisce l'infrastruttura e ogni club cliente. Non ancora presente in questa
fase, va aggiunto prima dell'uso con atleti reali.

## Cosa c'e' qui

- `informativa_privacy.md` — informativa ex art. 13 GDPR, da consegnare a chi
  esercita la responsabilita' genitoriale sul minore (o all'atleta stesso se
  maggiorenne) al momento dell'iscrizione.
- `modulo_consenso_genitori.md` — modulo di consenso/presa visione da far
  firmare al genitore o tutore, con le voci separate per trattamento
  necessario alla gestione sportiva e trattamento facoltativo.

## Dati realmente raccolti dall'app (da schema DB V1)

- **Anagrafici atleta**: nome, cognome, data di nascita, sesso, sport,
  gruppo/squadra (`atleti`)
- **Contatti del genitore/tutore**: email, telefono (`atleti`)
- **Dati sportivi**: test d'ingresso BVS/T30 e tempi (`test_ingresso`),
  tabelle passi per zona di allenamento (`tabelle_passi`), programmazione
  stagionale (`stagioni`/`macrocicli`/`mesocicli`/`microcicli`), schede di
  allenamento e serie (`allenamenti`/`serie`), presenze alle sessioni
  (`presenze`), eventuali note libere del coach
- Nessuna foto, video, dato biometrico o dato sanitario e' previsto in V1
  (fuori scope, vedi ROADMAP.md)

## Conservazione dei dati

I dati sono ospitati su Supabase in **region EU (Frankfurt)** — nessun
trasferimento extra-UE. Solo lo staff tecnico autorizzato del club (coach,
assistenti registrati come membri di quel club) puo' accedervi, grazie alla
Row Level Security attiva su ogni tabella (vedi `supabase/README.md`).
