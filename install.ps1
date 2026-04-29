# install.ps1 — Install .NET skills and agent rules for Windsurf.
# Works on Windows (PowerShell 5.1+) and macOS/Linux (PowerShell 7+).
#
# Usage:
#   .\install.ps1                                   # workspace install (current directory)
#   .\install.ps1 -TargetDir C:\Projects\myapp      # workspace install (specified directory)
#   .\install.ps1 -Global                           # global install
#   .\install.ps1 -Plugin dotnet-msbuild            # one plugin, workspace (current dir)
#   .\install.ps1 -Plugin dotnet-msbuild -TargetDir C:\Projects\myapp

param(
    [switch]$Global,
    [string]$Plugin = "",
    [string]$TargetDir = $PWD.Path
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillsSrc = Join-Path $ScriptDir "skills"
$RulesSrc  = Join-Path $ScriptDir "rules"

# Resolve global skills path — ~/.codeium/windsurf/skills on all platforms
if ($IsWindows -or $env:OS -eq "Windows_NT") {
    $HomeDir = $env:USERPROFILE
    $Sep = "\"
} else {
    $HomeDir = $HOME
    $Sep = "/"
}
$GlobalSkillsDir = Join-Path $HomeDir ".codeium" "windsurf" "skills"

# Determine install targets
if ($Global) {
    $SkillsDest = $GlobalSkillsDir
    $RulesDest  = $null   # global rules = single 6KB file; not suitable for 18 rule files
} else {
    New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
    $TargetDir  = (Resolve-Path $TargetDir).Path
    $SkillsDest = Join-Path $TargetDir ".windsurf" "skills"
    $RulesDest  = Join-Path $TargetDir ".windsurf" "rules"
}

# Validate source
if (-not (Test-Path $SkillsSrc -PathType Container)) {
    Write-Error "skills/ directory not found at $SkillsSrc`nMake sure you cloned the full repository."
    exit 1
}

$SkillsInstalled = 0
$RulesInstalled  = 0

# Install skills
New-Item -ItemType Directory -Force -Path $SkillsDest | Out-Null

Get-ChildItem -Path $SkillsSrc -Directory | ForEach-Object {
    $PluginName = $_.Name
    if ($Plugin -and $PluginName -ne $Plugin) { return }

    Get-ChildItem -Path $_.FullName -Directory | ForEach-Object {
        $SkillDir = $_
        if (-not (Test-Path (Join-Path $SkillDir.FullName "SKILL.md"))) { return }

        $Dest = Join-Path $SkillsDest $SkillDir.Name
        if (Test-Path $Dest) { Remove-Item $Dest -Recurse -Force }
        Copy-Item -Path $SkillDir.FullName -Destination $Dest -Recurse -Force
        $SkillsInstalled++
    }
}

# Install rules (workspace only)
if ($RulesDest -and (Test-Path $RulesSrc -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $RulesDest | Out-Null

    Get-ChildItem -Path $RulesSrc -Filter "*.md" | ForEach-Object {
        $RuleFile = $_
        if ($Plugin -and -not $RuleFile.Name.StartsWith("$Plugin--")) { return }

        Copy-Item -Path $RuleFile.FullName -Destination (Join-Path $RulesDest $RuleFile.Name) -Force
        $RulesInstalled++
    }
}

# Summary
Write-Host ""
if ($Global) {
    Write-Host "Installed $SkillsInstalled skills -> $SkillsDest"
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
