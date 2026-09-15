#Requires -Version 5.1
<#
.SYNOPSIS
  Host-side Windows bootstrap for dev_setup (WSL2 + Ubuntu).

.DESCRIPTION
  Enables WSL2 prerequisites where possible, ensures an Ubuntu distro is
  present, and prints next steps to clone/run the Linux installer inside WSL.
  Does NOT install the zsh/starship stack on native PowerShell — that lives
  in Ubuntu so Mac / Linux / Windows feel the same.

.EXAMPLE
  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
  .\windows\bootstrap.ps1
#>

$ErrorActionPreference = "Continue"

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "  [ok]  $msg" -ForegroundColor Green }
function Write-Info($msg) { Write-Host "  [info] $msg" -ForegroundColor Gray }
function Write-Warn($msg) { Write-Host "  [warn] $msg" -ForegroundColor Yellow }

Write-Host "dev_setup — Windows host bootstrap (WSL2)" -ForegroundColor Cyan

# ── WSL feature / version ───────────────────────────────────────────────────
Write-Step "Checking WSL"

$wsl = Get-Command wsl -ErrorAction SilentlyContinue
if (-not $wsl) {
  Write-Warn "wsl.exe not found. Install WSL from an elevated PowerShell:"
  Write-Host "    wsl --install -d Ubuntu"
  Write-Host "  Then reboot if prompted and re-run this script."
  exit 1
}

Write-Ok "wsl.exe found"

try {
  wsl --status 2>&1 | Out-Host
} catch {
  Write-Info "wsl --status not available on this build; continuing."
}

# Default to WSL2 for new distros when possible (needs admin for the service).
try {
  wsl --set-default-version 2 2>&1 | Out-Null
  Write-Ok "Default WSL version set to 2"
} catch {
  Write-Warn "Could not set default WSL version (may need elevation). Continuing."
}

# ── Ubuntu distro ───────────────────────────────────────────────────────────
Write-Step "Checking Ubuntu distro"

$distros = @()
try {
  $raw = wsl --list --quiet 2>$null
  if ($raw) {
    $distros = @($raw | ForEach-Object { ($_ -replace '\u0000', '').Trim() } | Where-Object { $_ })
  }
} catch {
  $distros = @()
}

$hasUbuntu = $false
foreach ($d in $distros) {
  if ($d -match '(?i)ubuntu') { $hasUbuntu = $true; break }
}

if ($hasUbuntu) {
  Write-Ok "Ubuntu distro already installed"
  Write-Info ("Distros: " + ($distros -join ", "))
} else {
  Write-Warn "No Ubuntu distro found."
  Write-Host "  Install with (may require elevation / reboot):"
  Write-Host "    wsl --install -d Ubuntu"
  Write-Host "  After Ubuntu finishes first-boot user setup, re-run this script."
  exit 0
}

# ── Terminal (WezTerm preferred for Mac-like Cmd/Super+C/V) ────────────────
Write-Step "Checking WezTerm (Mac-like copy/paste)"

$wez = Get-Command wezterm -ErrorAction SilentlyContinue
if ($wez) {
  Write-Ok "WezTerm found"
} else {
  Write-Warn "WezTerm not on PATH."
  Write-Host "  Install (recommended — Super+C/V matches macOS Cmd+C/V):"
  Write-Host "    winget install --id wez.wezterm -e"
  Write-Host "  Then inside WSL run: ./install.sh wezterm   # links shared wezterm.lua"
}

Write-Step "Checking Windows Terminal (optional fallback)"

$wt = Get-Command wt -ErrorAction SilentlyContinue
if ($wt) {
  Write-Ok "Windows Terminal found"
} else {
  Write-Info "Windows Terminal not on PATH (optional)."
  Write-Host "    winget install --id Microsoft.WindowsTerminal -e"
}

# ── Docker Desktop hint ─────────────────────────────────────────────────────
Write-Step "Docker Desktop (recommended for WSL)"

$dockerDesktop = Test-Path "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
if ($dockerDesktop) {
  Write-Ok "Docker Desktop appears installed"
  Write-Info "Enable: Settings -> Resources -> WSL Integration -> your Ubuntu distro"
} else {
  Write-Info "Optional but recommended for Mac-like Docker UX:"
  Write-Host "    winget install --id Docker.DockerDesktop -e"
  Write-Host "  Then enable WSL integration for Ubuntu."
}

# ── Next steps inside WSL ───────────────────────────────────────────────────
Write-Step "Next steps (inside Ubuntu)"

Write-Host @"
  1. Open Ubuntu (Windows Terminal profile, or: wsl -d Ubuntu)
  2. Install Linuxbrew build deps once:
       sudo apt update && sudo apt install -y build-essential curl file git
  3. Clone this repo (path is up to you), then:
       cd dev_setup   # or mac_setup until the folder is renamed
       ./install.sh all
       ./install.sh doctor
  4. Restart the shell: exec zsh

The shell stack (Starship, oh-my-zsh, sc, Helix, tmux) runs inside WSL so it
matches macOS and native Linux. This script only prepares the Windows host.
"@

Write-Host "`nBootstrap checks finished." -ForegroundColor Green
