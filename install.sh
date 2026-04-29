#!/usr/bin/env bash
# install.sh — Install .NET skills and agent rules for Windsurf.
#
# Usage:
#   ./install.sh                            # workspace install (current directory)
#   ./install.sh /path/to/project           # workspace install (specified directory)
#   ./install.sh --global                   # global install (~/.codeium/windsurf/skills/)
#   ./install.sh --plugin dotnet-msbuild    # one plugin, workspace (current dir)
#   ./install.sh --plugin dotnet-msbuild /path/to/project

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/skills"
RULES_SRC="$SCRIPT_DIR/rules"

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

# Resolve install targets
if $GLOBAL; then
  SKILLS_DEST="$HOME/.codeium/windsurf/skills"
  RULES_DEST=""   # global rules is a single file — not suitable for 18 rule files
else
  mkdir -p "$TARGET_DIR"
  TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
  SKILLS_DEST="$TARGET_DIR/.windsurf/skills"
  RULES_DEST="$TARGET_DIR/.windsurf/rules"
fi

# Validate source directories
if [[ ! -d "$SKILLS_SRC" ]]; then
  echo "ERROR: skills/ directory not found at $SKILLS_SRC" >&2
  echo "Make sure you cloned the full repository (not just the script)." >&2
  exit 1
fi

skills_installed=0
rules_installed=0

# Install skills
mkdir -p "$SKILLS_DEST"
for plugin_dir in "$SKILLS_SRC"/*/; do
  plugin_name="$(basename "$plugin_dir")"
  [[ -n "$PLUGIN_FILTER" && "$plugin_name" != "$PLUGIN_FILTER" ]] && continue

  for skill_dir in "$plugin_dir"*/; do
    [[ -f "$skill_dir/SKILL.md" ]] || continue
    skill_name="$(basename "$skill_dir")"
    dest="$SKILLS_DEST/$skill_name"
    rm -rf "$dest"
    cp -r "$skill_dir" "$dest"
    skills_installed=$((skills_installed + 1))
  done
done

# Install rules (workspace only)
if [[ -n "$RULES_DEST" && -d "$RULES_SRC" ]]; then
  mkdir -p "$RULES_DEST"
  for rule_file in "$RULES_SRC"/*.md; do
    [[ -f "$rule_file" ]] || continue
    rule_base="$(basename "$rule_file")"
    # Honour --plugin filter: rule files are named <plugin>--<agent>.md
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
  echo "Installed $skills_installed skills to: $SKILLS_DEST"
  if [[ -n "$PLUGIN_FILTER" ]]; then echo "  (plugin filter: $PLUGIN_FILTER)"; fi
  echo ""
  echo "Note: Agent rules (always-on personas) are workspace-scoped."
  echo "  Run './install.sh $TARGET_DIR' in each project to activate them."
else
  echo "Installed $skills_installed skills  → $SKILLS_DEST"
  echo "Installed $rules_installed rules    → $RULES_DEST"
  if [[ -n "$PLUGIN_FILTER" ]]; then echo "  (plugin filter: $PLUGIN_FILTER)"; fi
fi
echo ""
echo "Reload Windsurf (Developer: Reload Window) to pick up the new skills."
