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

## Notes

<!-- Quick-add scratchpad below -->