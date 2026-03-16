$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

$rojo = Get-Command rojo -ErrorAction SilentlyContinue

if (-not $rojo) {
    Write-Host ""
    Write-Host "Rojo CLI was not found on this computer." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Install options:" -ForegroundColor Cyan
    Write-Host "  winget install Rojo.Rojo"
    Write-Host "  choco install rojo"
    Write-Host "  or install from the official Rojo docs / GitHub releases"
    Write-Host ""
    Write-Host "Then rerun:" -ForegroundColor Cyan
    Write-Host "  .\scripts\Serve-Rojo.cmd"
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "Starting Rojo server for Farm Mutation MMO..." -ForegroundColor Green
Write-Host "Project root: $projectRoot" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Next steps in Roblox Studio:" -ForegroundColor Cyan
Write-Host "  1. Open a Baseplate place"
Write-Host "  2. Open the Rojo plugin"
Write-Host "  3. Connect to the local server"
Write-Host "  4. Sync the project"
Write-Host ""

& rojo serve
