# CLAUDE.md

Guidance for working in this repository.

## Config terminology

Two RuboCop configs live in this repo. Always refer to them by these names to
avoid confusion:

- **Public Config** — [`config/default.yml`](config/default.yml). The config the
  kaizo gem *ships*. It is loaded into any downstream project that installs kaizo
  and lists it under `plugins:`, so changing it changes what every consumer gets.
- **Private Config** — [`.rubocop.yml`](.rubocop.yml). The config kaizo uses to
  lint *itself* (dogfooding), at relaxed thresholds. It affects only this repo,
  never consumers.

When a change should reach gem users, edit the Public Config; when it is only
about how kaizo lints its own source, edit the Private Config. Some changes need
both.
