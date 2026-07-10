---
description: Release a new tf-module version and fan the pin out to every consumer (human-triggered)
disable-model-invocation: true
---

Release a new version of `tf-modules/cloudflare-site` and propagate it. This is the tf-module tag flow
(NOT the vendored-fragment re-vendor flow — that's separate; see AGENTS.md "Release / consumption model").

1. Make the module change under `tf-modules/cloudflare-site`; `tofu -chdir=tf-modules/cloudflare-site fmt`
   and `… validate`.
2. Cut a **new immutable tag** (e.g. `cf-site-v2`) — **never mutate a live tag** like `cf-site-v1`.
3. For **every consumer** whose root pins `?ref=cf-site-v1` (adamking.net, king-consulting,
   deervalleytexas.com, cf-data-workers — verify the live set with a search), bump the `git::…?ref=` to
   the new tag.
4. In each consumer, add `moved {}` blocks so `tofu plan` is a **state-only no-op** (0 add/change/destroy)
   — omitting these turns a plan into a destroy/recreate.
5. Confirm each consumer's `tofu plan` is clean before merging.

Report which consumers were bumped and paste each clean plan summary.
