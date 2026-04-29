#!/usr/bin/env python3
"""
generate.py — Prepares Windsurf-ready skill and rule files from dotnet/skills upstream.

Skills: copied verbatim from upstream (Windsurf natively supports SKILL.md format).
Rules:  generated from .agent.md files — frontmatter stripped, trigger: manual added.

Usage:
    python3 generator/generate.py                  # all plugins
    python3 generator/generate.py dotnet-msbuild   # single plugin
"""

import json
import re
import shutil
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent
UPSTREAM = REPO_ROOT / "upstream"
SKILLS_OUT = REPO_ROOT / "skills"
RULES_OUT = REPO_ROOT / "rules"


def strip_frontmatter(text: str) -> tuple[dict, str]:
    """Split YAML frontmatter and body. Returns ({key: value, ...}, body_text)."""
    stripped = text.lstrip()
    if not stripped.startswith("---"):
        return {}, text
    # Find closing ---
    rest = stripped[3:]
    end = re.search(r"\n---\s*\n", rest)
    if not end:
        return {}, text
    fm_text = rest[: end.start()]
    body = rest[end.end():]
    # Parse just name from frontmatter (simple key: value scan — no yaml dep needed)
    fields: dict = {}
    for line in fm_text.splitlines():
        m = re.match(r"^(\w[\w-]*):\s*(.*)", line)
        if m:
            fields[m.group(1)] = m.group(2).strip().strip('"')
    return fields, body


def copy_skill(skill_dir: Path, plugin_name: str) -> None:
    """Copy a skill directory tree to skills/<plugin>/<skill-name>/."""
    dest = SKILLS_OUT / plugin_name / skill_dir.name
    if dest.exists():
        shutil.rmtree(dest)
    shutil.copytree(skill_dir, dest)


_SUBAGENT_NOTE = (
    "> **Note:** This rule was converted from a [dotnet/skills](https://github.com/dotnet/skills) "
    "agent definition. Windsurf has no sub-agent spawning — Cascade executes the described "
    "workflow steps directly. `runSubagent` calls are guidance for how to approach the task, "
    "not literal sub-agent invocations.\n\n"
)


def generate_rule(agent_file: Path, plugin_name: str) -> None:
    """Generate a Windsurf rule file from a .agent.md file."""
    text = agent_file.read_text(encoding="utf-8")
    fields, body = strip_frontmatter(text)
    agent_name = fields.get("name", agent_file.stem.replace(".agent", ""))
    rule_name = f"{plugin_name}--{agent_name}.md"
    dest = RULES_OUT / rule_name
    note = _SUBAGENT_NOTE if "runSubagent" in body else ""
    content = "---\ntrigger: manual\n---\n" + note + body
    dest.write_text(content, encoding="utf-8")


def process_plugin(plugin_dir: Path) -> tuple[int, int]:
    """Process one plugin. Returns (skills_copied, rules_generated)."""
    manifest_path = plugin_dir / "plugin.json"
    if not manifest_path.exists():
        return 0, 0
    with manifest_path.open(encoding="utf-8") as f:
        manifest = json.load(f)
    plugin_name = manifest.get("name", plugin_dir.name)

    skills_copied = 0
    rules_generated = 0

    skills_dir = plugin_dir / "skills"
    if skills_dir.is_dir():
        for skill_dir in sorted(skills_dir.iterdir()):
            if skill_dir.is_dir() and (skill_dir / "SKILL.md").exists():
                copy_skill(skill_dir, plugin_name)
                skills_copied += 1

    agents_dir = plugin_dir / "agents"
    if agents_dir.is_dir():
        for agent_file in sorted(agents_dir.glob("*.agent.md")):
            generate_rule(agent_file, plugin_name)
            rules_generated += 1

    return skills_copied, rules_generated


def main() -> None:
    if not UPSTREAM.exists() or not (UPSTREAM / "plugins").exists():
        print(
            "ERROR: upstream/ submodule is not initialised.\n"
            "Run: git submodule update --init --recursive",
            file=sys.stderr,
        )
        sys.exit(1)

    # Determine which plugins to process
    filter_name = sys.argv[1] if len(sys.argv) > 1 else None

    SKILLS_OUT.mkdir(exist_ok=True)
    RULES_OUT.mkdir(exist_ok=True)

    total_skills = total_rules = 0
    for plugin_dir in sorted((UPSTREAM / "plugins").iterdir()):
        if not plugin_dir.is_dir():
            continue
        if filter_name and plugin_dir.name != filter_name:
            continue
        s, r = process_plugin(plugin_dir)
        if s or r:
            print(f"  {plugin_dir.name}: {s} skills, {r} rules")
        total_skills += s
        total_rules += r

    print(f"\nDone. Copied {total_skills} skills, generated {total_rules} rules.")


if __name__ == "__main__":
    main()
