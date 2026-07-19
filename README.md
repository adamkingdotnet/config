# adamkingdotnet/config

Shared configuration and small infrastructure building blocks I reuse across my
personal projects: a Terraform module, linter/formatter/TypeScript presets, and a
few CI helpers. Public because none of it is secret — but it's tuned for my own
repositories rather than meant as a general-purpose library.

## `tf-modules/cloudflare-site`

Terraform module for a standard Cloudflare-fronted site: a zone, house-style zone
settings (`ssl=strict`, `always_use_https`, `automatic_https_rewrites`,
`min_tls_version=1.2`), and worker custom-domain attachments (apex + optional
`www` + extra hostnames).

### Usage

```hcl
module "site" {
  source = "git::https://github.com/adamkingdotnet/config.git//tf-modules/cloudflare-site?ref=cf-site-v1"

  account_id  = var.account_id
  zone_name   = var.zone_name
  worker_name = var.worker_name

  # optional:
  create_www             = true                 # set false for apex-only sites
  worker_environment     = "production"
  extra_worker_hostnames = ["form"]             # -> form.<zone_name>
  extra_zone_settings    = { http3 = "off" }    # extra cloudflare_zone_setting entries
}
```

Consume the zone in your own DNS/redirect resources via `module.site.zone_id`.

### Adopting in an existing root (state-move, no destroy)

Moving live resources into this module changes their state addresses. Add
`moved {}` blocks in the root so `tofu plan` is a **state-only no-op**
(`0 to add, 0 to change, 0 to destroy`), e.g.:

```hcl
moved {
  from = cloudflare_zone.this
  to   = module.site.cloudflare_zone.this
}
# ...one per moved resource (zone settings, custom domains: www[0], extra["form"])
```

Pin `?ref=` to a tag; bump the tag when the module changes.

## Presets

Shared JS/TS/Python/editor presets, exposed via the `@king/config` package `exports`
(the package is `private`; consumers pull it as a `github:` tarball, so `@main` is the release).

- **ESLint** — `eslint/worker.mjs` and `eslint/vite-react.mjs` (flat config). Import as
  `@king/config/eslint/worker` / `@king/config/eslint/vite-react`.
- **tsconfig** — `tsconfig/worker.json`, `tsconfig/worker-lib.json`, `tsconfig/vite-app.json`,
  `tsconfig/vite-node.json`. Extend via `@king/config/tsconfig/<name>.json`.
- **Prettier** — `prettier/index.json` (`semi: false`, `singleQuote: true`, `printWidth: 100`,
  `trailingComma: "all"`). Reference as `@king/config/prettier`.
- **Python (ruff)** — `python/ruff.toml` (rules `E`/`F`/`W`/`I`/`B`/`UP`, `line-length = 100`,
  `E501` ignored). ruff has no cross-repo package mechanism, so consumers copy it and add their
  own `target-version` locally.
- **Editor** — `.editorconfig` (UTF-8, LF, 2-space indent, final newline, trailing-whitespace trim
  except in Markdown).

## Also here

- **`host-infra/`** — shared fragments for my Docker host stacks (a backup
  verify/prune helper and a reduced-privilege Netdata base), plus house-style notes.
  See [`host-infra/README.md`](host-infra/README.md).
