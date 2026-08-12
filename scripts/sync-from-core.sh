#!/usr/bin/env bash
# Sync the integration from a home-assistant-core checkout into this repo,
# preserving the custom-component manifest keys (version, issue_tracker, ...).
set -euo pipefail

CORE=${1:?usage: sync-from-core.sh /path/to/home-assistant-core}
SRC="$CORE/homeassistant/components/poolside"
DST="$(dirname "$0")/../custom_components/poolside"

[ -f "$SRC/manifest.json" ] || { echo "not a poolside component: $SRC" >&2; exit 1; }

rsync -a --delete \
  --exclude '__pycache__' \
  --exclude 'quality_scale.yaml' \
  --exclude 'manifest.json' \
  "$SRC/" "$DST/"

# Merge core manifest changes while keeping custom-only keys and dropping
# core-only ones. Bump "version" manually when cutting a release.
python3 - "$SRC/manifest.json" "$DST/manifest.json" <<'EOF'
import json, sys
core = json.load(open(sys.argv[1]))
custom = json.load(open(sys.argv[2]))
core.pop("quality_scale", None)
for key in ("documentation", "issue_tracker", "version"):
    if key in custom:
        core[key] = custom[key]
json.dump(core, open(sys.argv[2], "w"), indent=2)
open(sys.argv[2], "a").write("\n")
EOF

echo "Synced. Remember to bump 'version' in $DST/manifest.json for a release."
