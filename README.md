# .NET Skills for Windsurf

[![Sync with dotnet/skills](https://github.com/AtanasSarafov/dotnet-skills-windsurf/actions/workflows/sync-upstream.yml/badge.svg)](https://github.com/AtanasSarafov/dotnet-skills-windsurf/actions/workflows/sync-upstream.yml)

All [official .NET skills](https://github.com/dotnet/skills) from the .NET team at Microsoft, packaged for [Windsurf](https://windsurf.com).

## What's included

| Plugin | Skills | Description |
|--------|--------|-------------|
| [dotnet](skills/dotnet/) | 3 | Core C# skills: scripts, P/Invoke, trusted NuGet publishing |
| [dotnet-ai](skills/dotnet-ai/) | 5 | Technology selection, MCP integration, AI/ML with .NET |
| [dotnet-aspnet](skills/dotnet-aspnet/) | 2 | ASP.NET Core middleware, endpoints, real-time communication |
| [dotnet-data](skills/dotnet-data/) | 1 | EF Core queries and data access |
| [dotnet-diag](skills/dotnet-diag/) | 7 | Performance investigations, debugging, incident analysis |
| [dotnet-experimental](skills/dotnet-experimental/) | 8 | Incubation skills (test quality, SIMD, mock analysis) |
| [dotnet-maui](skills/dotnet-maui/) | 8 | MAUI environment, navigation, data binding, theming |
| [dotnet-msbuild](skills/dotnet-msbuild/) | 14 | Build diagnostics, performance, code quality |
| [dotnet-nuget](skills/dotnet-nuget/) | 1 | Package management and dependency modernization |
| [dotnet-template-engine](skills/dotnet-template-engine/) | 4 | dotnet new, template discovery, scaffolding |
| [dotnet-test](skills/dotnet-test/) | 18 | Test execution, filtering, MSTest workflows |
| [dotnet-upgrade](skills/dotnet-upgrade/) | 6 | Framework/language migration, version targeting |

Skills are auto-invoked by Cascade when relevant, or invoke them explicitly with `@skill-name`.

Agent rules (in `rules/`) activate always-on .NET expert personas and are installed at workspace level.

## Install

### Prerequisites

- Git
- macOS, Linux, or Windows with PowerShell 5.1+

### Step 1 — Clone this repository

```bash
git clone https://github.com/AtanasSarafov/dotnet-skills-windsurf
```

### Step 2 — Run the install script

**Workspace install** — skills and rules active in one project:

```bash
# macOS / Linux
./dotnet-skills-windsurf/install.sh /path/to/your/project

# Windows (PowerShell)
.\dotnet-skills-windsurf\install.ps1 -TargetDir C:\path\to\your\project
```

**Global install** — skills active across all Windsurf projects:

```bash
# macOS / Linux
./dotnet-skills-windsurf/install.sh --global

# Windows (PowerShell)
.\dotnet-skills-windsurf\install.ps1 -Global
```

> **Agent rules are workspace-scoped.** Windsurf does not support global rule directories (only a single 6 KB global rules file). Run the workspace install in each project where you want the always-on .NET personas active.

**Install a single plugin:**

```bash
# macOS / Linux
./dotnet-skills-windsurf/install.sh --plugin dotnet-msbuild /path/to/your/project

# Windows (PowerShell)
.\dotnet-skills-windsurf\install.ps1 -Plugin dotnet-msbuild -TargetDir C:\path\to\your\project
```

### Step 3 — Reload Windsurf

Open the Command Palette → **Developer: Reload Window**. Cascade auto-discovers all installed skills.

### Keeping skills up to date

The install script checks whether your local clone is behind the remote and warns you if so:

```
⚠  Your local copy is 3 commit(s) behind (remote updated 2 days ago).
   Run: git -C "/path/to/dotnet-skills-windsurf" pull
```

To update, pull and re-run the install:

```bash
git -C dotnet-skills-windsurf pull
./dotnet-skills-windsurf/install.sh /path/to/your/project   # macOS/Linux
.\dotnet-skills-windsurf\install.ps1 -TargetDir C:\path\to\project   # Windows
```

## How it works

This repo tracks [dotnet/skills](https://github.com/dotnet/skills) as a git submodule (`upstream/`) and pre-generates Windsurf-ready files from it:

- **`skills/`** — skill directories copied verbatim from upstream. No conversion needed: Windsurf natively uses the same [agentskills.io](https://agentskills.io) SKILL.md format.
- **`rules/`** — Windsurf rule files generated from upstream agent definitions. Each gets `trigger: always_on` so Cascade loads it automatically.

> Do not edit `skills/` or `rules/` directly — they are overwritten on every sync.

A GitHub Actions workflow runs daily, pulls the latest `dotnet/skills`, regenerates both folders, and auto-merges the resulting PR. Your local clone is the only thing that can fall behind — hence the install-time warning.

## License

The .NET skills content is © Microsoft Corporation, licensed under the [MIT License](upstream/LICENSE).
The generator and install scripts are also released under the MIT License. See [NOTICE](NOTICE) for details.
