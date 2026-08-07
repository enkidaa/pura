# Pura

App di benessere per iOS/Android — Flutter + Supabase (Postgres, Auth, Storage, Edge Functions) + Gemini per consigli personalizzati generati sui dati reali dell'utente.

Progetto personale, non un esercizio: nasce come riscrittura seria di un prototipo React fatto su Lovable ([pura-wellness-flow.lovable.app](https://pura-wellness-flow.lovable.app)), usato solo come riferimento di prodotto — il codice qui è scritto da zero.

## Cosa funziona davvero

- **Autenticazione** — email/password via Supabase Auth
- **Routine mattutina** — checklist giornaliera sincronizzata, si azzera ogni giorno
- **Diversità vegetale settimanale** — traccia piante uniche mangiate in 7 giorni (indicatore di salute del microbioma)
- **Sonno** — registrazione manuale o import da Apple Salute (HealthKit)
- **Digiuno** — traccia primo/ultimo pasto, finestra di digiuno vs obiettivo
- **Skincare** — foto prodotti mattino/sera, salvate su Supabase Storage (bucket privato, RLS per cartella utente)
- **Suoni** — link Spotify/Apple Music/podcast del giorno
- **Lab** — inventario ingredienti dell'utente, matching automatico contro una libreria di ricette/tonici funzionali, diario di cosa è stato preparato
- **Scopri** — contenuti editoriali (sfide, protocolli stagionali)
- **Focus del giorno** — un consiglio personalizzato al giorno, generato da Gemini leggendo un digest aggregato dei dati recenti dell'utente (non i log grezzi — vedi sotto)
- **Impostazioni** — tema chiaro/scuro/sistema

**In lavorazione:** libreria "Pratiche" (categorie di abitudini da aggiungere alla propria routine — solo una categoria ha contenuto reale finora, le altre aspettano contenuto).

## Decisioni di architettura degne di nota

- **La chiave dell'LLM non tocca mai il client.** `Focus del giorno` passa da una Supabase Edge Function (`supabase/functions/focus-del-giorno`) che gira lato server: legge i dati recenti dell'utente, costruisce un digest, chiama Gemini, ritorna solo il testo. La chiave vive nei secrets di Supabase.
- **Digest, non log grezzi.** Mandare mesi di cronologia grezza a un LLM ogni volta scala male sui costi e diluisce il segnale. La Edge Function aggrega al volo (streak, medie, conteggi) invece di allegare tutta la cronologia.
- **RLS ovunque.** Ogni tabella ha Row Level Security: un utente legge/scrive solo le proprie righe, anche se la chiave pubblica dell'app fosse esposta.
- **Nessun fallback locale silenzioso.** Le scritture (routine, piante, ecc.) vanno dirette su Supabase; se falliscono, l'interfaccia torna indietro e avvisa invece di fingere che sia andato tutto bene.

## Stack

- **Flutter** (iOS/Android)
- **Supabase** — Postgres + Row Level Security, Auth, Storage, Edge Functions (Deno)
- **Gemini Flash** — via Edge Function, per il costo quasi nullo al volume d'uso di un'app personale

## Struttura del progetto

```
lib/
  models/       # Strutture dati
  screens/      # Schermate, organizzate per area (es. auth/)
  services/     # Comunicazione con Supabase (auth, routine, sonno, lab, ecc.)
supabase/
  migrations/   # Schema del database, versionato (supabase db push)
  functions/    # Edge Function per i consigli AI
```

## Setup locale

1. [Flutter](https://docs.flutter.dev/get-started/install) installato e funzionante (`flutter doctor`)
2. Crea un progetto su [supabase.com](https://supabase.com), copia `lib/services/supabase_config.example.dart` in `lib/services/supabase_config.dart` con URL e chiave pubblica del tuo progetto (file escluso da git)
3. [Supabase CLI](https://supabase.com/docs/guides/cli) → `supabase link --project-ref <ref>` → `supabase db push` per applicare le migrazioni
4. Per la Edge Function: vedi `supabase/functions/focus-del-giorno/DEPLOY.md`
5. `flutter pub get && flutter run`

## Perché questo progetto esiste

Sto imparando a programmare seriamente costruendo qualcosa di vero e usato ogni giorno, non solo esercizi — con Claude come copilota tecnico mentre guido io le decisioni di prodotto.
