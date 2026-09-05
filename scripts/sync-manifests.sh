#!/usr/bin/env bash
# Generates every client adapter manifest from the portable plugin.json and mcp.json.
#
# plugin.json and mcp.json are the single source of truth. Never edit an adapter
# by hand; edit the portable files and re-run this script.
#
#   ./scripts/sync-manifests.sh          rewrite the adapters
#   ./scripts/sync-manifests.sh --check  verify the adapters are current and the
#                                        portable files and skills are valid
set -euo pipefail

cd "$(dirname "$0")/.."

# Cursor listing fields with no portable equivalent. Agent Plugins leaves user
# interface out of the portable specification, so these live here.
CURSOR_LOGO="assets/logo.png"
CURSOR_MIN_VERSION="3.13.0"

out="."
if [ "${1:-}" = "--check" ]; then
  out=$(mktemp -d)
  trap 'rm -rf "$out"' EXIT
fi
mkdir -p "$out/.claude-plugin" "$out/.codex-plugin" "$out/.cursor-plugin" "$out/.agents/plugins"

jq -e '.extensions["com.openai"].interface | type == "object"' plugin.json >/dev/null 2>&1 \
  || { echo 'FAIL: plugin.json is missing extensions["com.openai"].interface' >&2; exit 1; }

identity='{
  name: .name,
  version: .version,
  description: .description,
  author: {name: .author.name, email: .author.email},
  homepage: .homepage,
  repository: .repository,
  license: .license,
  keywords: .keywords
}'
iface='.extensions["com.openai"].interface'

jq --argjson id "$(jq "$identity" plugin.json)" \
   "\$id * {displayName: $iface.displayName} | {name, displayName, version, description, author, homepage, repository, license, keywords}" \
   plugin.json > "$out/.claude-plugin/plugin.json"

jq --argjson id "$(jq "$identity" plugin.json)" \
   "\$id + {skills: \"./skills/\", mcpServers: \"./.mcp.json\", interface: $iface}" \
   plugin.json > "$out/.codex-plugin/plugin.json"

jq --argjson id "$(jq "$identity" plugin.json)" \
   --arg logo "$CURSOR_LOGO" --arg minver "$CURSOR_MIN_VERSION" \
   "\$id * {displayName: $iface.displayName}
    | {name, displayName, version, description, author, homepage, repository, license, keywords}
    + {logo: \$logo, minClientVersions: {cursor: \$minver}, skills: \"./skills/\", mcpServers: \"./.mcp.json\"}" \
   plugin.json > "$out/.cursor-plugin/plugin.json"

jq '{
  name: "clearskies-marketplace",
  owner: {name: .author.name, email: .author.email},
  metadata: {description: .description},
  plugins: [{name: .name, source: "./", description: .description, category: "productivity", keywords: .keywords}]
}' plugin.json > "$out/.claude-plugin/marketplace.json"

jq "{
  name: \"clearskies-marketplace\",
  interface: {displayName: $iface.displayName},
  plugins: [{
    name: .name,
    source: {source: \"local\", path: \"./\"},
    policy: {installation: \"AVAILABLE\", authentication: \"ON_INSTALL\"},
    category: $iface.category
  }]
}" plugin.json > "$out/.agents/plugins/marketplace.json"

# Claude Code, Cursor, and legacy Codex read .mcp.json and expect the pre-1.0.0
# transport tag.
jq 'del(."$schema")
    | .mcpServers |= with_entries(.value.type |= (if . == "streamable-http" then "http" else . end))' \
   mcp.json > "$out/.mcp.json"

ADAPTERS=(.claude-plugin/plugin.json .claude-plugin/marketplace.json .codex-plugin/plugin.json
          .cursor-plugin/plugin.json .agents/plugins/marketplace.json .mcp.json)

if [ "$out" = "." ]; then
  printf 'Regenerated %s\n' "${ADAPTERS[@]}"
  exit 0
fi

fail=0
note() { printf 'FAIL: %s\n' "$1" >&2; fail=1; }

for f in "${ADAPTERS[@]}"; do
  diff -q "$f" "$out/$f" >/dev/null 2>&1 || note "$f is stale; run ./scripts/sync-manifests.sh"
done

ALLOWED='["$schema","name","version","description","author","homepage","repository","license","keywords","extensions"]'
[ "$(jq -r '."$schema"' plugin.json)" = "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json" ] \
  || note "plugin.json \$schema is not the 1.0.0 plugin schema"
extra=$(jq -r --argjson allowed "$ALLOWED" 'keys_unsorted - $allowed | join(", ")' plugin.json)
[ -z "$extra" ] || note "plugin.json has non-portable top-level keys: $extra"
jq -e '.name | test("^(?!.*(--|\\.\\.))[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?$") and (length <= 64)' plugin.json >/dev/null \
  || note "plugin.json name does not satisfy the Agent Plugins naming rules"
jq -e '.extensions // {} | to_entries | all(.value | type == "object")' plugin.json >/dev/null \
  || note "every plugin.json extensions member must be an object"

[ "$(jq -r '."$schema"' mcp.json)" = "https://agent-plugins.org/schemas/1.0.0/mcp.schema.json" ] \
  || note "mcp.json \$schema is not the 1.0.0 MCP schema"
jq -e '.mcpServers | to_entries | all(.value.type | IN("stdio", "streamable-http", "sse"))' mcp.json >/dev/null \
  || note "mcp.json declares a transport outside stdio, streamable-http, sse"

# skills-ref validates frontmatter shape and the description limit in CI. This only
# catches the directory mismatch, which silently drops the skill instead of erroring.
for skill in skills/*/; do
  name=$(basename "$skill")
  meta=$(awk 'NR==1{if($0!="---") exit; next} /^---$/{exit} {print}' "$skill/SKILL.md")
  grep -q "^name: $name\$" <<<"$meta" || note "$skill SKILL.md name does not match its directory"
done

[ "$fail" -eq 0 ] && echo "Adapters are current and the portable package is valid."
exit "$fail"
