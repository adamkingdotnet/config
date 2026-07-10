---
description: Safely edit an encrypted .env.sops (avoids the sops truncation footgun); for docker-host repos
disable-model-invocation: true
---

Help safely edit this repo's sops-encrypted `.env.sops`. **Never** hand-roll the encryption:
`sops encrypt > .env.sops` truncates the file to 0 bytes on a creation-rule mismatch, and
`sops set` chokes on the `#` comments in a dotenv file. Use the interactive in-place flow.

1. **Key availability.** On the host, `~/.config/sops/age/keys.txt` is found automatically. On the
   Mac, export the repo's key from the Keychain first:
   - nas-docker: `export SOPS_AGE_KEY="$(security find-generic-password -s sops-age-key -w)"`
   - vps-docker: `export SOPS_AGE_KEY="$(security find-generic-password -s sops-age-key-vps -w)"`
   (On the VPS over SSH, sops is at `~/.local/bin/sops` — use the full path in non-login shells.)
2. **Edit in place** (decrypts into `$EDITOR`, re-encrypts on save): `sops .env.sops`
3. **Verify still encrypted:** `grep -q 'ENC\[AES256_GCM' .env.sops && echo OK`

If you must add a key **non-interactively** (no `$EDITOR`): decrypt to a temp file in a dir with **no**
`.sops.yaml` (e.g. the scratchpad), append, re-encrypt with an explicit `--age <recipient>` (nas:
`age12kcn6…`; vps: `age1l7vtwugra9t8t2u9khxeeq3mnaeyq3ftjhzcgnsscuzddfcksyqsxyrvnc`), then VALIDATE the
candidate (decrypts OK; key count = original + N; still contains `ENC[AES256_GCM`) before copying it
over the real `.env.sops`. Recover a clobbered file with `git checkout -- .env.sops` (it's committed).
