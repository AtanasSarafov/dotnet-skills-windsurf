# install.ps1 — Install .NET skills and agent rules for Windsurf.
# Works on Windows (PowerShell 5.1+) and macOS/Linux (PowerShell 7+).
#
# Skill source (first available wins):
#   1. skills/           — pre-generated copy committed to this repo (fastest)
#   2. upstream/plugins/ — live from the git submodule (fallback)
#
# Usage:
#   .\install.ps1                                   # workspace install (current directory)
#   .\install.ps1 -TargetDir C:\Projects\myapp      # workspace install (specified directory)
#   .\install.ps1 -Global                           # global install
#   .\install.ps1 -Plugin dotnet-msbuild            # one plugin, workspace (current dir)

param(
    [switch]$Global,
    [string]$Plugin = "",
    [string]$TargetDir = $PWD.Path
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillsSrc = Join-Path $ScriptDir "skills"
$RulesSrc  = Join-Path $ScriptDir "rules"
$UpstreamPlugins = Join-Path $ScriptDir "upstream" "plugins"

# Resolve global skills path cross-platform
if ($IsWindows -or $env:OS -eq "Windows_NT") {
    $HomeDir = $env:USERPROFILE
} else {
    $HomeDir = $HOME
}
$GlobalSkillsDir = Join-Path $HomeDir ".codeium" "windsurf" "skills"

# Determine skill source
if (Test-Path $SkillsSrc -PathType Container) {
    $SkillSource = "pregenerated"
} elseif (Test-Path $UpstreamPlugins -PathType Container) {
    $SkillSource = "upstream"
    Write-Host "Note: skills/ not found, reading directly from upstream submodule."
} else {
    Write-Error "No skill source found.`nEither the skills/ directory or the upstream/ submodule must be present.`nRun: git submodule update --init --recursive"
    exit 1
}

# Determine rules source — generate if missing and Python available
$ResolvedRulesSrc = $null
if (Test-Path $RulesSrc -PathType Container) {
    $ResolvedRulesSrc = $RulesSrc
} elseif ($SkillSource -eq "upstream") {
    $Python = Get-Command python3 -ErrorAction SilentlyContinue
    if (-not $Python) { $Python = Get-Command python -ErrorAction SilentlyContinue }
    if ($Python) {
        Write-Host "Note: rules/ not found — generating from upstream agent definitions..."
        & $Python.Source (Join-Path $ScriptDir "generator" "generate.py") | Out-Null
        if (Test-Path $RulesSrc -PathType Container) { $ResolvedRulesSrc = $RulesSrc }
    }
}

# Determine install targets
if ($Global) {
    $SkillsDest = $GlobalSkillsDir
    $RulesDest  = $null
} else {
    New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
    $TargetDir  = (Resolve-Path $TargetDir).Path
    $SkillsDest = Join-Path $TargetDir ".windsurf" "skills"
    $RulesDest  = Join-Path $TargetDir ".windsurf" "rules"
}

$SkillsInstalled = 0
$RulesInstalled  = 0

New-Item -ItemType Directory -Force -Path $SkillsDest | Out-Null

# Install skills — handle both source layouts
if ($SkillSource -eq "pregenerated") {
    # Layout: skills/<plugin>/<skill-name>/SKILL.md
    Get-ChildItem -Path $SkillsSrc -Directory | ForEach-Object {
        $PluginName = $_.Name
        if ($Plugin -and $PluginName -ne $Plugin) { return }
        Get-ChildItem -Path $_.FullName -Directory | ForEach-Object {
            if (-not (Test-Path (Join-Path $_.FullName "SKILL.md"))) { return }
            $Dest = Join-Path $SkillsDest $_.Name
            if (Test-Path $Dest) { Remove-Item $Dest -Recurse -Force }
            Copy-Item -Path $_.FullName -Destination $Dest -Recurse -Force
            $SkillsInstalled++
        }
    }
} else {
    # Layout: upstream/plugins/<plugin>/skills/<skill-name>/SKILL.md
    Get-ChildItem -Path $UpstreamPlugins -Directory | ForEach-Object {
        $PluginDir = $_
        $ManifestPath = Join-Path $PluginDir.FullName "plugin.json"
        if (-not (Test-Path $ManifestPath)) { return }
        $PluginName = (Get-Content $ManifestPath | ConvertFrom-Json).name
        if ($Plugin -and $PluginName -ne $Plugin) { return }
        $SkillsDir = Join-Path $PluginDir.FullName "skills"
        if (-not (Test-Path $SkillsDir -PathType Container)) { return }
        Get-ChildItem -Path $SkillsDir -Directory | ForEach-Object {
            if (-not (Test-Path (Join-Path $_.FullName "SKILL.md"))) { return }
            $Dest = Join-Path $SkillsDest $_.Name
            if (Test-Path $Dest) { Remove-Item $Dest -Recurse -Force }
            Copy-Item -Path $_.FullName -Destination $Dest -Recurse -Force
            $SkillsInstalled++
        }
    }
}

# Install rules (workspace only)
if ($RulesDest -and $ResolvedRulesSrc -and (Test-Path $ResolvedRulesSrc -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $RulesDest | Out-Null
    Get-ChildItem -Path $ResolvedRulesSrc -Filter "*.md" | ForEach-Object {
        if ($Plugin -and -not $_.Name.StartsWith("$Plugin--")) { return }
        Copy-Item -Path $_.FullName -Destination (Join-Path $RulesDest $_.Name) -Force
        $RulesInstalled++
    }
}

# Summary
Write-Host ""
if ($Global) {
    Write-Host "Installed $SkillsInstalled skills  -> $SkillsDest"
    if ($Plugin) { Write-Host "  (plugin filter: $Plugin)" }
    Write-Host ""
    Write-Host "Note: Agent rules (always-on personas) are workspace-scoped."
    Write-Host "  Run '.\install.ps1 -TargetDir <project>' in each project to activate them."
} else {
    Write-Host "Installed $SkillsInstalled skills  -> $SkillsDest"
    Write-Host "Installed $RulesInstalled rules    -> $RulesDest"
    if ($Plugin) { Write-Host "  (plugin filter: $Plugin)" }
}
Write-Host ""
Write-Host "Reload Windsurf (Developer: Reload Window) to pick up the new skills."
