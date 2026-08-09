# Privacy Architecture

Honest documentation of how user data actually flows through Pura today — not a legal privacy policy, an engineering description of what the code does.

## 1. Request flow: user → JWT → RLS → private storage → server-side AI

1. **Auth.** The user signs in via Supabase Auth (email/password). Every subsequent request from the Flutter app carries the user's JWT.
2. **Database access.** All Postgres tables (`routine_completions`, `plant_diversity_logs`, `sleep_logs`, `fasting_logs`, `sound_links`, `skincare_photos`, `user_ingredients`, `mix_diary_logs`, `user_documents`, `profiles`, `safety_events`, `llm_call_logs`) have **Row Level Security enabled**, with a policy of the shape `using (auth.uid() = user_id) with check (auth.uid() = user_id)`. A user's JWT can only ever touch their own rows — this is enforced by Postgres itself, not by application code, so a bug in the Flutter app or the Edge Function cannot leak one user's data to another.
3. **File storage.** Uploaded skincare photos and documents live in **private** Supabase Storage buckets (`skincare-photos`, `user-documents`), never public. Objects are stored under a `<user_id>/...` path, and a storage RLS policy restricts access to `(storage.foldername(name))[1] = auth.uid()::text` — a user can only read/write their own folder.
4. **AI processing happens only server-side.** The Flutter app never calls Gemini directly. It calls a Supabase Edge Function (`focus-del-giorno`) with the user's JWT. The function re-derives the user's identity from that JWT via `supabase.auth.getUser()`, then queries the database **as that user** (through a Supabase client scoped to their JWT), so the same RLS policies apply inside the Edge Function too — it cannot accidentally query another user's data even if the code had a bug.
5. **The LLM API key lives only in Supabase secrets**, injected as an environment variable into the Edge Function at runtime. It is never sent to the client, never in the Flutter app bundle, never in the repo.

## 2. What is sent to the LLM provider (Gemini), and what is explicitly not

**Sent:**
- A **digest**, not raw history: aggregated counts (e.g. "routine step X completed 4/7 days"), the count of unique plants logged in the last 7 days, and — if present — a short AI-authored narrative summary from the user's `profiles` row.
- If the user has uploaded a document (e.g. a nutritionist's report), the **most recent one** is attached natively as multimodal `inline_data` (base64 PDF/image) — read directly by the model, no OCR/text-extraction step of ours in between.
- For the independent safety classifier call: only the generated `observation` and `recommendation` text (see `PRIVACY.md` §3 in the Edge Function comments) — deliberately narrower context, on purpose, so the classifier isn't anchored by the same framing that produced the content.

**Explicitly not sent:**
- Raw event-level history (every single routine checkbox tick, every plant log entry) — only the aggregated digest.
- Documents older than the most recent one (only one document is attached per request today).
- Any other user's data (impossible by construction, see RLS above).
- The user's email or any account/profile metadata beyond what's in the digest text itself.

## 3. Logging — confirmed no sensitive content

Two tables record telemetry about AI calls, both metadata-only:

- **`llm_call_logs`**: timestamp, model name, prompt version, latency, token counts, estimated cost, error message (if any), final safety category. **No prompt text, no digest content, no suggestion text, no document content.**
- **`safety_events`**: timestamp, the model's self-reported safety category, the independent layer's final category, and the action taken (`passthrough` / `modified`). Same rule — categories and an action label only, never the actual recommendation text.

Both tables have the same per-user RLS as everything else. Errors from the LLM provider are logged as short strings (e.g. `"HTTP 429"`), never as raw response bodies that could contain echoed prompt content.

## 4. Data deletion — what exists today, what's missing

**Exists:**
- Uploaded documents can be deleted individually from the Profilo screen (removes both the Storage object and the `user_documents` row).
- Routine/plant-diversity entries can be un-toggled, which deletes the underlying row (not just hides it).
- Every table's foreign key to `auth.users` is declared `on delete cascade` — if a user's auth account is deleted (today only possible via the Supabase dashboard/Admin API, not self-service), all their rows across every table and their Storage objects' *metadata rows* are removed automatically at the database level.

**Missing (honest gap, not yet built):**
- No self-service "delete my account" or "delete all my data" flow in the app itself.
- `on delete cascade` removes database rows, but does **not** delete the actual files in Storage buckets — a Storage-object cleanup step (or a scheduled job) would be needed alongside account deletion to avoid orphaned files.
- No data-export ("give me my data") flow.

These would be the next concrete steps before this app could reasonably handle other users' health data beyond personal/development use.
