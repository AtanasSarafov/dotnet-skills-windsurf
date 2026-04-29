#!/usr/bin/env bash
# install.sh — Install .NET skills and agent rules for Windsurf.
#
# Skill source (first available wins):
#   1. skills/          — pre-generated copy committed to this repo (fastest)
#   2. upstream/plugins/ — live from the git submodule (fallback)
#
# Usage:
#   ./install.sh                            # workspace install (current directory)
#   ./install.sh /path/to/project           # workspace install (specified directory)
#   ./install.sh --global                   # global install (~/.codeium/windsurf/skills/)
#   ./install.sh --plugin dotnet-msbuild    # one plugin, workspace (current dir)
#   ./install.sh --plugin dotnet-msbuild /path/to/project

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GLOBAL=false
PLUGIN_FILTER=""
TARGET_DIR="$PWD"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --global)
      GLOBAL=true
      shift
      ;;
    --plugin)
      PLUGIN_FILTER="$2"
      shift 2
      ;;
    -*)
      echo "Unknown option: $1" >&2
      echo "Usage: $0 [--global] [--plugin <name>] [<target-dir>]" >&2
      exit 1
      ;;
    *)
      TARGET_DIR="$1"
      shift
      ;;
  esac
done

# Determine skill source
if [[ -d "$SCRIPT_DIR/skills" ]]; then
  SKILL_SOURCE="pregenerated"
elif [[ -d "$SCRIPT_DIR/upstream/plugins" ]]; then
  SKILL_SOURCE="upstream"
  echo "Note: skills/ not found, reading directly from upstream submodule."
else
  echo "ERROR: No skill source found." >&2
  echo "  Either the skills/ directory or the upstream/ submodule must be present." >&2
  echo "  Run: git submodule update --init --recursive" >&2
  exit 1
fi

# Determine rules source
RULES_SRC=""
if [[ -d "$SCRIPT_DIR/rules" ]]; then
  RULES_SRC="$SCRIPT_DIR/rules"
elif [[ "$SKILL_SOURCE" == "upstream" ]] && command -v python3 &>/dev/null; then
  echo "Note: rules/ not found — generating from upstream agent definitions..."
  python3 "$SCRIPT_DIR/generator/generate.py" >/dev/null
  RULES_SRC="$SCRIPT_DIR/rules"
fi

# Resolve install targets
if $GLOBAL; then
  SKILLS_DEST="$HOME/.codeium/windsurf/skills"
  RULES_DEST=""
else
  mkdir -p "$TARGET_DIR"
  TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
  SKILLS_DEST="$TARGET_DIR/.windsurf/skills"
  RULES_DEST="$TARGET_DIR/.windsurf/rules"
fi

skills_installed=0
rules_installed=0

mkdir -p "$SKILLS_DEST"

# Install skills — handle both source layouts
if [[ "$SKILL_SOURCE" == "pregenerated" ]]; then
  # Layout: skills/<plugin>/<skill-name>/SKILL.md
  for plugin_dir in "$SCRIPT_DIR/skills"/*/; do
    plugin_name="$(basename "$plugin_dir")"
    [[ -n "$PLUGIN_FILTER" && "$plugin_name" != "$PLUGIN_FILTER" ]] && continue
    for skill_dir in "$plugin_dir"*/; do
      [[ -f "$skill_dir/SKILL.md" ]] || continue
      skill_name="$(basename "$skill_dir")"
      rm -rf "$SKILLS_DEST/$skill_name"
      cp -r "$skill_dir" "$SKILLS_DEST/$skill_name"
      skills_installed=$((skills_installed + 1))
    done
  done
else
  # Layout: upstream/plugins/<plugin>/skills/<skill-name>/SKILL.md
  for plugin_dir in "$SCRIPT_DIR/upstream/plugins"/*/; do
    plugin_json="$plugin_dir/plugin.json"
    [[ -f "$plugin_json" ]] || continue
    plugin_name="$(python3 -c "import json,sys; print(json.load(open('$plugin_json'))['name'])" 2>/dev/null || basename "$plugin_dir")"
    [[ -n "$PLUGIN_FILTER" && "$plugin_name" != "$PLUGIN_FILTER" ]] && continue
    skills_dir="$plugin_dir/skills"
    [[ -d "$skills_dir" ]] || continue
    for skill_dir in "$skills_dir"/*/; do
      [[ -f "$skill_dir/SKILL.md" ]] || continue
      skill_name="$(basename "$skill_dir")"
      rm -rf "$SKILLS_DEST/$skill_name"
      cp -r "$skill_dir" "$SKILLS_DEST/$skill_name"
      skills_installed=$((skills_installed + 1))
    done
  done
fi

# Install rules (workspace only)
if [[ -n "$RULES_DEST" && -n "$RULES_SRC" && -d "$RULES_SRC" ]]; then
  mkdir -p "$RULES_DEST"
  for rule_file in "$RULES_SRC"/*.md; do
    [[ -f "$rule_file" ]] || continue
    rule_base="$(basename "$rule_file")"
    if [[ -n "$PLUGIN_FILTER" ]]; then
      [[ "$rule_base" == "${PLUGIN_FILTER}--"* ]] || continue
    fi
    cp "$rule_file" "$RULES_DEST/$rule_base"
    rules_installed=$((rules_installed + 1))
  done
fi

# Summary
echo ""
if $GLOBAL; then
  echo "Installed $skills_installed skills  → $SKILLS_DEST"
  if [[ -n "$PLUGIN_FILTER" ]]; then echo "  (plugin filter: $PLUGIN_FILTER)"; fi
  echo ""
  echo "Note: Agent rules (always-on personas) are workspace-scoped."
  echo "  Run './install.sh /path/to/project' in each project to activate them."
else
  echo "Installed $skills_installed skills  → $SKILLS_DEST"
  echo "Installed $rules_installed rules    → $RULES_DEST"
  if [[ -n "$PLUGIN_FILTER" ]]; then echo "  (plugin filter: $PLUGIN_FILTER)"; fi
fi
echo ""
echo "Reload Windsurf (Developer: Reload Window) to pick up the new skills."
