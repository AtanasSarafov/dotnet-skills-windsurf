# .NET Skills for Windsurf

[![Sync with dotnet/skills](https://github.com/atanassarafov/dotnet-skills-windsurf/actions/workflows/sync-upstream.yml/badge.svg)](https://github.com/atanassarafov/dotnet-skills-windsurf/actions/workflows/sync-upstream.yml)

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

Skills are auto-invoked by Cascade when relevant, or call them explicitly with `@skill-name`.

Agent rules (in `rules/`) provide always-on .NET expert personas for workspace-level installs.

## Install

### Prerequisites

- Git
- macOS, Linux, or Windows with PowerShell 5.1+

### Step 1 — Clone this repository

```bash
git clone https://github.com/atanassarafov/dotnet-skills-windsurf
```

### Step 2 — Run the install script

**Workspace install** — skills active in one project:

```bash
# macOS / Linux
./dotnet-skills-windsurf/install.sh /path/to/your/project

# Windows (PowerShell)
.\dotnet-skills-windsurf\install.ps1 -TargetDir C:\path\to\your\project
```

**Global install** — skills active in all Windsurf projects:

```bash
# macOS / Linux
./dotnet-skills-windsurf/install.sh --global

# Windows (PowerShell)
.\dotnet-skills-windsurf\install.ps1 -Global
```

> **Note on agent rules:** Rules (always-on .NET expert personas) are workspace-scoped in Windsurf. They are installed with the workspace install, not the global install. Run the workspace install in each project where you want them active.

**Install a single plugin:**

```bash
# macOS / Linux
./dotnet-skills-windsurf/install.sh --plugin dotnet-msbuild /path/to/your/project

# Windows (PowerShell)
.\dotnet-skills-windsurf\install.ps1 -Plugin dotnet-msbuild -TargetDir C:\path\to\your\project
```

### Step 3 — Reload Windsurf

Open the Command Palette and run **Developer: Reload Window**. Cascade will auto-discover all installed skills.

### Update

Pull the latest skills and re-run the install script:

```bash
git -C dotnet-skills-windsurf pull
./dotnet-skills-windsurf/install.sh /path/to/your/project   # macOS/Linux
.\dotnet-skills-windsurf\install.ps1 -TargetDir C:\path\to\project   # Windows
```

## How it works

This repository wraps [dotnet/skills](https://github.com/dotnet/skills) as a git submodule and pre-generates Windsurf-ready files:

- **`skills/`** — skill directories copied verbatim from upstream. Windsurf natively supports the [agentskills.io](https://agentskills.io) SKILL.md format used by dotnet/skills.
- **`rules/`** — Windsurf rule files generated from upstream agent definitions. Each rule gets `trigger: always_on` so Cascade loads it automatically.

A GitHub Actions workflow runs every Monday to sync with upstream and open a PR when new skills are available.

## License

The .NET skills content is © Microsoft Corporation, licensed under the [MIT License](upstream/LICENSE).
The generator and install scripts are also released under the MIT License. See [NOTICE](NOTICE) for details.
