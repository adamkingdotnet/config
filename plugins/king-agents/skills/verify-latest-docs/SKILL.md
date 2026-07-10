---
name: verify-latest-docs
description: Use before relying on any external library/tool/provider version, flag, or API — verify against the LATEST upstream docs rather than trusting model-ingrained (possibly stale) knowledge. Triggers when writing/upgrading dependency code, wrangler/tofu/docker/sops/eslint/ts flags, MCP server configs, or any provider API call.
---

The fleet moves fast and model knowledge lags. Before you rely on an external version, flag, or API:

1. **Name the uncertainty.** Which exact symbol/flag/version/endpoint are you about to use, and from
   which tool/provider?
2. **Check the live source**, not memory: the provider's current docs (WebFetch/WebSearch), the
   package's latest release notes, or `--help`/`<tool> version`. Prefer the primary source.
3. **Reconcile** with what the repo already pins (package.json / wrangler.toml / *.tf ref / Dockerfile).
   If your intended usage differs from the installed/pinned version, follow the pin, not your memory.
4. **State the check** in your response ("verified against <url> as of <date>") so it's auditable.

This is the operational form of the working-agreement's "verify-latest, not verify-current" tenet.
Do NOT invent API shapes; if the live docs are unreachable, say so and flag the uncertainty.
