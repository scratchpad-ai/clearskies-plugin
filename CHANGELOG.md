# Changelog

## 0.2.0

Repackaged as an [Agent Plugins 1.0.0](https://agent-plugins.org) package. The
portable root `plugin.json` and `mcp.json` are now the source of truth, so any
conformant client can load the plugin from the repository root.

Merged the five sales skills from `clearskies-cursor-plugin` into this
repository: `account-brief`, `meeting-prep`, `pipeline-review`, `call-recap`,
and `customer-health`. Cursor now gets the workflow builder, and Claude Code and
Codex now get the sales skills.

Added the MIT license and the privacy policy. Client adapter manifests for
Claude Code, Codex, and Cursor are retained; see the README for why. They are now
generated from `plugin.json` by `scripts/sync-manifests.sh`, so the identity and
metadata live in exactly one place.

## 0.1.0

Initial package: three skills (`use-clearskies-revenue-data`,
`clearskies-workflow-builder`, `ai-update-salesforce-field`), the clearskies MCP
server pointer, and manifests for Claude Code and Codex.
