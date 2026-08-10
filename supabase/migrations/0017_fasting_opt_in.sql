-- Fasting stops being a default pillar of Oggi — it's opt-in, hidden until
-- the user explicitly turns it on (same gating pattern as sex→cycle card).
alter table profiles
  add column fasting_enabled boolean not null default false;
