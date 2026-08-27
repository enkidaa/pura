-- 0032 defaulted onboarding_completed to false for every existing row too,
-- which would force the brand-new quiz onto an account that configured
-- its profile long before this feature existed. Anyone with a profile row
-- already has, by definition, been through setup — mark them done. New
-- signups after this point still get the correct `false` default from the
-- column itself.
update profiles set onboarding_completed = true;
