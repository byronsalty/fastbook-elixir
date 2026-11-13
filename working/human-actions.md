# Human actions

Actions only a person can take. Delete an entry once it's confirmed done.

- **Mark the GitGuardian incidents from the standards sync as false positives.**
  GitGuardian incident 9443278 has 3 occurrences on commit 201a71b
  (`standards: sync to dd4ad62`), in `.standards/workflows/test.yml`,
  `.standards/workflows/pr-webapp.yml` and `.standards/workflows/deploy-fly.yml`.
  Each one is `POSTGRES_PASSWORD: postgres`, the credential for a throwaway CI
  Postgres service container, not a real secret. `.gitguardian.yaml` stops new
  scans from flagging these paths, but incidents that were already raised have
  to be resolved by hand in the GitGuardian dashboard
  (https://dashboard.gitguardian.com/workspace/319628/incidents/9443278).
- **Delete the `standards/sync-dd4ad62` branch once PR #24 merges.**
