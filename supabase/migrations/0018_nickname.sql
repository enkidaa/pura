-- Used for the "Buongiorno, {nickname}" greeting on Oggi. Optional — falls
-- back to a plain greeting when unset.
alter table profiles
  add column nickname text;
