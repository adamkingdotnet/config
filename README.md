# adamkingdotnet/config

Shared, cross-project configuration for the `adamkingdotnet` workspace. **Public** — contains no secrets.

## `tf-modules/cloudflare-site`

Terraform module for a standard Cloudflare-fronted site: a zone, the house-style
zone settings (`ssl=strict`, `always_use_https`, `automatic_https_rewrites`,
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

## Roadmap

- Phase 5 adds JS/lint presets here (ESLint, tsconfig, Prettier, `.editorconfig`, ruff/mypy).
