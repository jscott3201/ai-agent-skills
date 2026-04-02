#!/usr/bin/env bash
# Renames the plugin by updating plugin.json
# Usage: ./scripts/rename-plugin.sh new-name

set -euo pipefail

NEW_NAME="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$REPO_ROOT/.claude-plugin/plugin.json"

if [[ -z "$NEW_NAME" ]]; then
  echo "Usage: $0 <new-name>"
  echo "  name must be lowercase letters, numbers, and hyphens"
  exit 1
fi

if [[ ! "$NEW_NAME" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
  echo "Error: name must be lowercase letters, numbers, and hyphens"
  exit 1
fi

OLD_NAME=$(python3 -c "import json; print(json.load(open('$MANIFEST'))['name'])")

python3 -c "
import json, sys
with open('$MANIFEST') as f:
    m = json.load(f)
m['name'] = '$NEW_NAME'
with open('$MANIFEST', 'w') as f:
    json.dump(m, f, indent=2)
    f.write('\n')
"

echo "Renamed: $OLD_NAME -> $NEW_NAME"
echo "Skills are now invoked as /$NEW_NAME:<skill-name>"
