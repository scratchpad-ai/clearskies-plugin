# Contributing

This repository is an [Agent Plugins 1.0.0](https://agent-plugins.org) package.

## Repository layout

```text
plugin.json              Agent Plugins 1.0.0 manifest (canonical)
mcp.json                 Agent Plugins MCP configuration (canonical)
skills/                  Portable Agent Skills, one directory each
assets/                  Logos and the composer icon
scripts/                 sync-manifests.sh generates every adapter below
.github/workflows/       CI
```

## Edit two files, generate the rest

`plugin.json` and `mcp.json` are the only manifests you edit by hand. Every file in the
table below is generated from them:

```bash
./scripts/sync-manifests.sh          # rewrite the adapters
./scripts/sync-manifests.sh --check  # verify they are current and the package is valid
```

| Adapter | Read by | Why it exists |
| --- | --- | --- |
| `.claude-plugin/` | Claude Code | Claude Code has no Agent Plugins support and reads only this path. |
| `.cursor-plugin/` | Cursor | Cursor checks `.cursor-plugin/` then `.claude-plugin/` then the root manifest, and stops at the first one with a `displayName`. Without this file Cursor would load the Claude manifest and lose the listing logo. |
| `.codex-plugin/` | Older Codex builds | Current Codex prefers the root manifest, but older builds read only this path. |
| `.agents/plugins/` | Codex marketplace | Marketplace entries sit outside the portable package by design. |
| `.mcp.json` | Claude Code, Cursor, legacy Codex | None of them read the root `mcp.json`. The generator rewrites the `streamable-http` transport tag to the legacy `http` tag here. |

Two values have no portable home, because Agent Plugins leaves user interface outside the
specification. They live as labelled constants at the top of `scripts/sync-manifests.sh`:
`CURSOR_LOGO` and `CURSOR_MIN_VERSION`.

Codex app card metadata lives under `extensions["com.openai"].interface` in `plugin.json`.
That namespace is the one Codex reads; see `agent_plugin_manifest.rs` in
[openai/codex](https://github.com/openai/codex).

## Adding a skill

Create `skills/<name>/SKILL.md`. The frontmatter `name` must match the directory name.
Put detail in `references/` rather than inline, so agents load it only when needed. Add a
row to the skills table in `README.md`.

## Before you open a pull request

```bash
./scripts/sync-manifests.sh --check
npx --yes skills-ref@0.1.5 validate ./skills/<name>
```

CI runs both on every pull request, plus `ajv` validation of `plugin.json` and `mcp.json`
against the published Agent Plugins schemas. A hand-edited adapter fails the build.
