# Deploy focus-del-giorno

Passaggi da fare tu (richiedono login/credenziali, non posso farli io):

## 0. Se manca, installa la CLI Supabase

```bash
brew install supabase/tap/supabase
```

Se dà errore "Command Line Tools are too outdated": Impostazioni di Sistema → Generali → Aggiornamento Software, installa gli aggiornamenti disponibili, poi riprova.

## 1. Login e collegamento al progetto

```bash
supabase login
supabase link --project-ref wpskwtcgfkuwxigfxwzt
```

`login` apre il browser per autenticarti — normale, serve la tua sessione Supabase.

## 2. Prendi una chiave API Gemini

Vai su [aistudio.google.com/apikey](https://aistudio.google.com/apikey), crea una chiave (account Google richiesto).

## 3. Imposta la chiave come secret (mai nel codice/repo)

```bash
supabase secrets set GEMINI_API_KEY=la_tua_chiave_qui
```

## 4. Deploy della funzione

```bash
supabase functions deploy focus-del-giorno
```

## 5. Verifica

Nell'app, tab "Oggi" → card "Focus del giorno" → "Genera consiglio". Se dà errore, controlla i log:

```bash
supabase functions logs focus-del-giorno
```
