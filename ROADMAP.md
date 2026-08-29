# SwimCoach FIN — Roadmap & Note di Progetto

App di coaching Nuoto + Pallanuoto — Flutter · Supabase · Cursor · Claude Code

## Stack tecnico
- **Flutter** (mobile + web/desktop)
- **Supabase** (region EU/Frankfurt) — database, auth, backend
- **Drift** — database locale per offline-first
- **Riverpod** — state management
- **Cursor** — editor quotidiano
- **Claude Code** — sviluppo assistito da AI per i task più corposi

## Ambiente di sviluppo
- Flutter SDK: `D:\src\flutter`
- Android SDK: `D:\AndroidSdk`
- Cartella progetto: `D:\Dev\coach-vasca`
- Repository GitHub privato: github.com/zucchi3marco-tech/coach-vasca

## Decisioni chiave di sicurezza e privacy
- Gli atleti sono spesso minorenni: serve informativa privacy + consenso di un genitore/tutore alla raccolta dati
- Supabase in region **EU (Frankfurt)** per residenza dati in Europa
- **Row Level Security (RLS) attiva da subito** su ogni tabella (isolamento per club/coach) — senza RLS chiunque abbia la anon key legge i dati di tutti i club
- Solo la **anon key** nell'app; la **service_role key** non deve mai finire nel client
- Chiavi segrete sempre in file `.env`, mai nel codice, mai su Git — `.gitignore` corretto fin dal primo commit
- Repository GitHub **privato**, non pubblico
- Strategia di conflitto per la sync offline: **last-write-wins su campo `updated_at`** + log delle modifiche
- Strategia branch: `main` sempre funzionante + un branch per ogni feature

## Fuori scope per la V1
Wearable, OCR referti, computer vision, Banister completo, pubblicazione sugli store.

---

## FASE 0 — Preparazione PC ✅ QUASI COMPLETATA
- [x] Git, Cursor, Flutter, Android Studio installati e funzionanti
- [x] Config Git (nome, email, SSH) fatta
- [x] Account GitHub (repo privato) creato
- [x] Claude Code installato
- [x] Account Supabase (region EU) creato — progetto "Coach-vasca"
- [x] Primo `flutter create` fatto dentro questa cartella — progetto `coach_vasca` (Android/iOS/Web/Linux/macOS/Windows)

## FASE 1 — Fondazione prodotto (~1 settimana)
- [x] Schema DB V1: Club, Atleti, Test_BVS_T30, Tabelle_Passi, Stagione/Macro/Meso/Micro, Allenamenti, Serie, Presenze — migrazioni SQL in `supabase/migrations/`, applicate al progetto reale e verificate (12 tabelle, RLS attiva, 4 policy ciascuna), vedi `supabase/README.md`
- [x] RLS attiva su ogni tabella Supabase da subito (isolamento per club/coach) — multi-coach per club con ruoli owner/coach/assistente
- [x] `.env` con chiavi Supabase, escluso da Git — `.env.example` come template versionato, `.env` reale creato e verificato ignorato
- [x] Bozza informativa privacy + consenso genitori (atleti minorenni) — `docs/privacy/`, da far rivedere da un consulente prima dell'uso reale
- [x] Wireframe 6 schermate: login, lista atleti, test→passi, calendario stagione, scheda bordo vasca, placeholder "Genera con AI" — vedi `docs/wireframes/README.md`

## FASE 2 — MVP Nuoto usabile (~2-4 settimane)
- [x] Auth coach (Supabase email) — Riverpod + client Supabase (`lib/core/supabase/`), login/logout/reset password (`lib/features/auth/`)
- [ ] CRUD Atleti
- [ ] Inserimento BVS o T30
- [ ] Motore tabelle passi (A1…D) per atleta/corsia
- [ ] Scheda allenamento manuale (serie, distanza, regime, ripartenza, note)
- [ ] Presenze sessione
- [ ] UI pool-first, alto contrasto, bottoni grandi, landscape tablet
- [ ] Checklist di test manuale prima di chiudere la fase
- [ ] Test su Chrome + telefono Android reale
- [ ] Commit frequenti su branch feature, merge su main solo quando funziona

**Criterio di fine fase:** un coach usa l'app in vasca per una sessione reale, senza AI.

## FASE 3 — Offline-first (~1-2 settimane)
- [ ] Drift come DB locale (al posto di SQLite puro)
- [ ] Scrittura sempre in locale in impianto
- [ ] Regola di conflitto documentata (last-write-wins su updated_at)
- [ ] Sync verso Supabase a rete disponibile
- [ ] Indicatore "sincronizzato / in coda"
- [ ] Test in modalità aereo

## FASE 4 — Programmazione di stagione (~2-3 settimane)
- [ ] Creare Stagione (date, obiettivo, gruppo)
- [ ] Suddivisione macro/meso/micro (anche solo settimane, in V1)
- [ ] Assegnare allenamenti alle date
- [ ] Vista settimanale e mensile
- [ ] Duplica settimana / sposta scheda

**Criterio di fine fase:** il coach vede il piano della settimana e apre la scheda del giorno.

## FASE 5 — Modulo AI "Genera allenamento" (~2-3 settimane)
Modulo indipendente, ispirato a funzionalità pubbliche viste online, non al codice di terzi.
- [ ] Form input: gruppo/livello, volume, focus, regimi ammessi, vincoli
- [ ] Chiamata API con limite di spesa mensile impostato sul provider
- [ ] Output sempre in JSON strutturato e validato (metri, tempi, regimi noti)
- [ ] Anteprima scheda generata + conferma manuale del coach prima del salvataggio
- [ ] "Aggiungi al calendario" → collega alla stagione
- [ ] Storico prompt/output per migliorare i prompt nel tempo
- [ ] (Opzionale, dopo) dettatura vocale → stesso parser JSON

**Criterio di fine fase:** generi una scheda, la correggi, la metti in una data della stagione.

## FASE 6 — Polish e uso reale (~2 settimane)
- [ ] 2-3 sessioni vere in piscina
- [ ] Export PDF/CSV scheda o settimana
- [ ] Messaggi di errore chiari
- [ ] Backup manuale del DB Supabase se ancora su piano Free
- [ ] Valutare Cursor Pro se i limiti free iniziano a bloccare il lavoro

## FASE 7 — Pallanuoto V2 (~3-5 settimane)
- [ ] Distinta FIN (13/15, portieri, capitani, fuoriquota)
- [ ] Partita + eventi base (tiro, fallo, uomo ±)
- [ ] Plus/minus semplice
- [ ] (Dopo) digitalizzazione referto solo con fogli reali di esempio

## FASE 8 — Avanzato V3
- [ ] Parsing file .cl2 / .sd3 / risultati FIN
- [ ] Banister / tapering su storico carichi
- [ ] Referti: invio foto a un modello con visione invece di OCR dedicato
- [ ] Computer vision stroke rate (elaborazione locale sul device)
- [ ] Supabase Pro (backup automatici)
- [ ] Pubblicazione store (Play/App Store) se necessario

---

## Ordine di dipendenze (non invertire)
PC pronto → Atleti + Passi + Scheda manuale → Offline → Calendario stagione → AI genera scheda → importa in stagione → (voce, opzionale) → Pallanuoto / referti / CV

*Senza atleti, passi e calendario, una scheda generata dall'AI non ha dove finire.*

## Costi nel tempo (indicativi)
| Momento | Spesa mensile tipica |
| --- | --- |
| Setup + MVP in sviluppo | 0 € |
| Uso quotidiano intenso di Cursor | ~20 $/mese (Cursor Pro) |
| + Refactor pesanti / task lunghi | ~37-40 $/mese (+ Claude Pro) |
| + App in uso reale | ~62-65 $/mese (+ Supabase Pro) |
| Modulo AI genera-allenamento | pochi €/mese (API a consumo, con tetto di spesa) |
