# config

Central configuration, documentation, and tooling for Adam King's development environment. Contains shared reference files for infra, project setup, and retrospectives.

## Structure

- **`docs/`** — Documentation (structs, specs, how-tos).
- **`terraform/`** — Shared Terraform/OpenTofu configurations.
- **`.github/workflows/`** — CI: self-check.yml validates docs links and structure.

## Commands

| Action | Command |
|--------|---------|
| validate | `cd terraform && tofu fmt -check` |
| plan | `cd terraform && tofu plan` |

## Key Files

- `eslint/` — Shared ESLint flat configs: `vite-react.mjs`, `worker.mjs`.
- `tsconfig/` — Shared TS configs: `vite-app.json`, `vite-node.json`, `worker.json`, `worker-lib.json`.
- `python/ruff.toml` — Shared Python lint/format config.
- `prettier/index.json` — Shared Prettier config.
- `tf-modules/cloudflare-site/` — Reusable Terraform module for Cloudflare sites.
- `host-infra/` — Host infrastructure: backup scripts, Netdata configs, tests.

## Skip These

- `node_modules/` — Dependencies.
- `package-lock.json` — Generated lockfile.
- `plugins/` — Currently empty, no content to read.

## Notes

<!-- Quick-add scratchpad below -->