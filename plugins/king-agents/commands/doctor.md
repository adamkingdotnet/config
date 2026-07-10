---
description: Health-check this repo's shared agent layer (plugin, king.json gate, settings/agreement drift)
---

Run the shared-layer health check for the current repo and report a compact PASS/FAIL summary, one line per check:

1. **Plugin** — run `!claude plugin list` and report whether `king-agents` is enabled and at what version.
2. **Verify gate** — if `.claude/king.json` exists, print its `verify.cmd`; otherwise report "no gate (advisory-only repo)".
3. **Working-agreement drift** — diff this repo's `AGENTS.md` working-agreement block against the canonical at `https://raw.githubusercontent.com/adamkingdotnet/config/main/agents/working-agreement.md`; report match or drift.
4. **Settings drift** — read the repo type from `.claude/settings.json` (its `enabledPlugins`/activation block identifies it as a king-agents consumer), then diff `.claude/settings.json` against `https://raw.githubusercontent.com/adamkingdotnet/config/main/plugins/king-agents/settings-templates/<type>.json`; report match or drift. If unsure of `<type>`, state which template you compared against.

Do not modify anything — this is read-only. Report only the four-line summary.
