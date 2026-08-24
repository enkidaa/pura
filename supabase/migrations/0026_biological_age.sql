-- Chronological age is a required input to the PhenoAge formula itself
-- (not just a display value) — without it, focus-del-giorno cannot compute
-- a biological age estimate from an uploaded blood panel, no matter how
-- many biomarkers are present. Nullable/opt-in like the rest of profiles.
alter table profiles add column birth_date date;
