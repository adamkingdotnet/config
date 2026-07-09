# host-infra — shared docker-host conventions & fragments

Canonical home for the small surface the two docker-compose host stacks
(`adamkingdotnet/nas-docker`, `adamkingdotnet/vps-docker`) genuinely share. The
two stacks are **not merged** — different hosts, different TLS, different
topology. They share *fragments*, a *secrets convention*, and the *house style*
documented here.

## Vendored fragments (copy-with-CI-lint)

| Canonical | Vendored into | Purpose |
|---|---|---|
| `host-infra/backup-lib.sh` | nas `db-backup/backup-lib.sh`, vps `lib/backup-lib.sh` | `verify_dump` / `atomic_publish` / `prune_keep` — backup integrity primitives, `source`d by each per-service dump driver |
| `host-infra/netdata-apps-off.conf` | vps `netdata/netdata.conf` | reduced-privilege netdata base (`[plugins] apps = no`) |

There is **no submodule**. Each host repo keeps a byte-identical copy and its CI
runs `scripts/check-vendored.sh <canonical> <local>`, which fetches the canonical
from this repo (public, `@main`) and `diff`s it — drift fails the build. To
change a fragment: edit it here, push, then re-vendor the copies in lockstep
(same guarantee as the fleet-wide `.editorconfig`).

**netdata is a special case.** `netdata.conf` is monolithic (no `include`), so
only the VPS — which runs the reduced-privilege base verbatim — vendors it. The
NAS runs a **superset** (the same `[plugins] apps = no` base plus a `[statsd]`
heartbeat block and an expanded comment); it is documented as sharing the base
but is not byte-gated, because you can't assemble a monolithic conf from parts.

## Backup driver house style

Each service keeps its own driver (the NAS runs a containerized `pg_dump | gzip`
loop; the VPS runs host-cron `pg_dump -Fc` for Umami and a container-stop + `tar`
for Pocket ID's SQLite). What they share, via `backup-lib.sh`:

1. **Dump to a temp name** (`.tmp` / `.partial`), never the final name.
2. **`verify_dump "$tmp" "$MIN_DUMP_BYTES"`** — a size floor plus, for `*.gz`,
   `gzip -t`. An interrupted-but-flushed gzip can still pass `-t`, so the floor
   is a second, independent guard.
3. **`atomic_publish "$tmp" "$final"`** — a single rename, so no reader ever sees
   a half-written dump under the final name.
4. **`prune_keep "$dir" "<glob>" "$KEEP"`** — retain N newest, and only *after* a
   successful publish, so a failed dump can never evict a good generation.

## Compose house style

- **`name:` the project** at the top of the top-level compose file so container
  names and volume prefixes are stable across `docker compose` invocations.
- **Memory limits use `deploy.resources.limits.memory`** (the v3 form, honored by
  `docker compose up` outside swarm), not the legacy `mem_limit:`. *(The VPS
  stack still carries legacy `mem_limit:` on its services — a known, low-priority
  normalization, not yet converted.)*
- **`x-common: &common` anchors are file-local.** YAML anchors don't cross
  `include:` boundaries, so each compose file declares its own — intentional
  duplication, not drift.
- **Harden by default:** `security_opt: [no-new-privileges:true]`, `cap_drop:
  [ALL]` then add back only what's needed, `read_only: true` + a `tmpfs` for
  `/tmp` where the image allows, and a real `healthcheck` on every long-lived
  service.
- **Postgres 18+ `PGDATA` gotcha:** the image moved the default data dir to a
  version-specific subdir (`/var/lib/postgresql/<major>/docker`) and expects the
  volume at `/var/lib/postgresql`. Either pin `PGDATA` to the legacy
  `/var/lib/postgresql/data` (VPS, to reuse an existing mount) or mount the
  parent so majors live side-by-side for dump/restore upgrades (NAS).

## Caddy pattern (shared shape, not shared bytes)

Both stacks front everything with Caddy as the **only** container binding public
host ports; everything else is reachable only over the internal compose network
or `docker exec`. The `Caddyfile` is bind-mounted **read-only**; certs + the ACME
account persist in a `caddy-data` volume so they survive recreation; reload
in place with `docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile`.

The Caddyfiles themselves stay **per-host** (not vendored): the NAS runs a custom
`xcaddy` build with the Cloudflare DNS-01 plugin for `*.adamking.net`; the VPS
runs stock `caddy:2-alpine` with HTTP-01 for `*.kingconsulting.llc`. Different
plugins, ACME challenge, and zones — only the *pattern* above is shared.

## Secrets convention (sops + age)

Both stacks keep secrets in a git-committed `.env.sops` (sops + age), decrypted
to a gitignored `.env` at deploy time by `scripts/deploy.sh` under `umask 077`.
`.sops.yaml` uses `path_regex: '\.env.*\.sops$'`. **Each host has its own age
keypair** — a VPS compromise cannot decrypt NAS/finances/health secrets and vice
versa. Back each private key up off-host; losing it means losing every secret.
