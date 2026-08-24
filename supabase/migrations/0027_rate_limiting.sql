-- Reuses llm_call_logs (already has user_id + created_at per request)
-- instead of a new table — a rate-limit check is just "how many of this
-- user's rows in the last 24h", which this table already records.
--
-- `rate_limited` distinguishes an actual attempted Gemini call (may itself
-- have failed, e.g. a real HTTP 429 from Gemini) from a request Pura
-- itself refused before ever calling Gemini. It's NOT NULL so the count
-- query can filter with a plain `= false` — no NULL-vs-empty ambiguity
-- from overloading the existing nullable `error` text column for this.
alter table llm_call_logs add column rate_limited boolean not null default false;

-- The rate-limit check is `where user_id = ? and created_at >= ?`, run on
-- every focus-del-giorno request — without this index it's a sequential
-- scan of the whole table once it has any real history.
create index llm_call_logs_user_created_idx on llm_call_logs (user_id, created_at);
