-- Gates the one-time onboarding quiz shown right after signup. profiles
-- already has no row at all for a brand-new user (loadSettings falls back
-- to AppSettings.defaults), so a missing/false value here just means
-- "hasn't seen it yet" without needing a special-case for new accounts.
alter table profiles add column onboarding_completed boolean not null default false;
