# generator

Produces Windsurf-ready files from the `upstream/` submodule (dotnet/skills).

## What it does

- **Skills** — copies each `plugins/<plugin>/skills/<name>/` directory verbatim to `skills/<plugin>/<name>/`. No conversion: Windsurf natively uses the same SKILL.md format (agentskills.io standard).
- **Rules** — converts each `plugins/<plugin>/agents/<name>.agent.md` file into a Windsurf rule markdown at `rules/<plugin>--<name>.md`. The agentskills.io frontmatter is stripped and replaced with `trigger: always_on`.

## Prerequisites

- Python 3.8 or later (stdlib only — no `pip install` required)
- `upstream/` submodule initialised: `git submodule update --init --recursive`

## Usage

```bash
# Regenerate everything (run from repo root)
python3 generator/generate.py

# Regenerate a single plugin
python3 generator/generate.py dotnet-msbuild
```

The generator is idempotent — re-running it produces the same output.

## When to run

Run after pulling upstream changes (`git submodule update --remote upstream`) and commit the updated `skills/` and `rules/` directories. The CI workflow (`sync-upstream.yml`) does this automatically each week.
