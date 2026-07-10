# config

<!-- BEGIN working-agreement (vendored from adamkingdotnet/config — edit there, then re-vendor) -->
## Working agreement

These four tenets are non-negotiable:

1. Ask, don't assume. If something is unclear, ask before writing a single line. Never make silent assumptions about intent, architecture, or requirements.
2. Simplest solution first. Always implement the simplest thing that could work. Do not add abstractions or flexibility that weren't explicitly requested.
3. Don't touch unrelated code. If a file or function is not directly part of the current task, do not modify it, even if you think it could be improved.
4. Flag uncertainty explicitly. If you are not confident about an approach or technical detail, say so before proceeding. Confidence without certainty causes more damage than admitting a gap.

Operating instructions:

- Keep remote CI/CD green — after pushing **and** after merging. A change isn't done until checks pass on the merged result. (See **Applies here** below for what runs where — some repos gate on PRs only, some have no CI yet.)
- Reach infrastructure directly over SSH (`ssh nas`, `ssh vps`, …) for logs, inspection, and deploys rather than asking for output.
- Drive providers with their own tooling (e.g. `wrangler` for Cloudflare) rather than asking to click through a dashboard.
- Verify implementation specifics against the **latest** upstream docs — don't trust model-ingrained versions or APIs that may be stale; check the live docs first.
<!-- END working-agreement -->
Canonical **public** shared config for the `adamkingdotnet` fleet. **No secrets** — every file here is consumed verbatim by other repos. Repo: `github.com/adamkingdotnet/config`. See [README.md](README.md) and [host-infra/README.md](host-infra/README.md) (authoritative house-style).

## Blast radius — read first

Every file here is fanned out fleet-wide. A byte-change is a downstream break until consumers re-vendor/re-pin in lockstep:

- **Vendored host fragments** (`host-infra/backup-lib.sh`, `host-infra/netdata-apps-off.conf`) are copied byte-identical into `nas-docker`/`vps-docker`. Their CI runs `check-vendored.sh` against `@main` and **fails on any drift**. Editing one here breaks those builds until the copies are re-vendored.
- **Working-agreement block** (`agents/working-agreement.md`) is vendored into every repo's AGENTS.md between `BEGIN/END working-agreement` markers; consumers' `check-agreement.sh` byte-gates it.
- **Presets** (`eslint/`, `tsconfig/`, `prettier/`, `python/ruff.toml`, `.editorconfig`) re-lint downstream worker/vite repos the moment they re-install — a rule change can turn a clean consumer red.
- **tf module** (`tf-modules/cloudflare-site`) is pinned by tag; see release model below.

## The four surfaces

- **`@king/config` npm presets** — `eslint/{worker,vite-react}.mjs`, `tsconfig/{worker,worker-lib,vite-app,vite-node}.json`, `prettier/index.json`. Package is `private` (unpublished); consumed as a `github:` tarball, exposed via `exports` in `package.json`.
- **Python/editor** — `python/ruff.toml` (E/F/W/I/B/UP, line-length 100), `.editorconfig`. No mypy.
- **`tf-modules/cloudflare-site`** — OpenTofu/Terraform module: zone + house-style zone settings + worker custom-domain attachments. Consumed via `git::…//tf-modules/cloudflare-site?ref=cf-site-v1`.
- **`host-infra/`** — shared docker-host fragments (`backup-lib.sh`, `netdata-apps-off.conf`) + house-style doc. Its byte-gate tooling lives at repo root: `scripts/{check-vendored,check-agreement}.sh` + `agents/working-agreement.md`.

## Release / consumption model

- **tf module:** pinned per-consumer via `?ref=cf-site-v1`. A change = **new tag** + bump every consumer root's `?ref=` (and add `moved {}` blocks so `tofu plan` is a state-only no-op). Never mutate a live tag.
- **npm presets:** no version bump ceremony — consumers pull a `github:` tarball, so `@main` is the release. Downstream re-lints on re-install.
- **vendored fragments:** edit here → push → re-vendor the copies in `nas-docker`/`vps-docker` in the same change set.

## Commands

- `host-infra/tests/run.sh` — plain-bash tests for `backup-lib.sh` (`verify_dump`/`atomic_publish`/`prune_keep`); no bats needed. (`host-infra/tests/backup-lib.bats` mirrors it.)
- `tofu -chdir=tf-modules/cloudflare-site validate` and `tofu fmt` — module hygiene.

## Applies here

- **Self-CI runs here now** (`.github/workflows/self-check.yml`): the plain-bash test suites (`verify-gate`, `check-settings`, `check-version-bump`), the working-agreement gate on this `AGENTS.md`, and a PR-only version-bump guard (any `plugins/king-agents/**` change must bump `plugin.json`'s `version`). "Green" still *also* means **downstream** consumers pass after you push (host repos' `check-vendored`/`check-agreement`, worker/vite lint).
- **`wrangler` is N/A** — the Cloudflare surface is the tofu module, so `tofu`/`terraform` is the tool, not `wrangler`.
- **SSH is load-bearing** for host-infra changes — verify `backup-lib.sh` edits against live NAS/VPS dumps (`ssh nas`, `ssh vps`).
- **Verify-latest applies** to the lint/ts presets — check current ESLint/typescript-eslint APIs against upstream before editing.
