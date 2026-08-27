<# :
@echo off
setlocal EnableDelayedExpansion
title Optimizer_Setup - Secret-Optimizer Installer
color 0B
mode con: cols=105 lines=50 >nul 2>&1

:: Auto-elevate to Administrator if not already elevated
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "OPT_SOURCE_DIR=%~dp0"
if "%OPT_SOURCE_DIR:~-1%"=="\" set "OPT_SOURCE_DIR=%OPT_SOURCE_DIR:~0,-1%"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:OPT_SOURCE_DIR='%OPT_SOURCE_DIR%'; & ([ScriptBlock]::Create((Get-Content -LiteralPath '%~f0' -Raw)))"
exit /b %errorlevel%
#>

<#
.SYNOPSIS
    Secret-Optimizer Automated Setup & Management Package
.DESCRIPTION
    Official deployment and update wizard for Secret-Optimizer Windows Suite.
.AUTHOR
    mrsecret_official
#>

[CmdletBinding()]
param()

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$esc = [char]27
$creamyGreen = "$esc[38;2;145;225;165m"
$creamyRed   = "$esc[38;2;235;120;120m"
$creamyCyan  = "$esc[38;2;130;210;245m"
$creamyYellow= "$esc[38;2;240;220;140m"
$dimText     = "$esc[38;2;160;175;195m"
$reset       = "$esc[0m"

function Show-Banner {
    $lines = @(
        '   ____                      _          ___        _   _           _              ',
        '  / ___|  ___  ___ _ __ ___| |_       / _ \ _ __ | |_(_)_ __ ___ (_)_______ _ __  ',
        '  \___ \ / _ \/ __| ''__/ _ \ __|_____| | | | ''_ \| __| | ''_ ` _ \| |_  / _ \ ''__|',
        '   ___) |  __/ (__| | |  __/ |_|_____| |_| | |_) | |_| | | | | | | |/ /  __/ |    ',
        '  |____/ \___|\___|_|  \___|\__|      \___/| .__/ \__|_|_| |_| |_|_/___\___|_|    ',
        '                                           |_|                                    '
    )
    $colors = @(
        @(20,70,160),
        @(35,95,190),
        @(50,125,220),
        @(75,155,240),
        @(110,190,255),
        @(140,215,255)
    )
    Write-Host ''
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $c = $colors[$i]
        Write-Host ($esc + '[38;2;' + $c[0] + ';' + $c[1] + ';' + $c[2] + 'm' + $lines[$i] + $reset)
    }
    Write-Host ''
    Write-Host ($esc + '[38;2;120;200;255m                               Made by: mrsecret_official' + $reset)
    Write-Host ''
}

# -------------------------------------------------------------
# PATHS
# -------------------------------------------------------------
$headers = @{
    'Accept'     = 'application/vnd.github.v3+json'
    'User-Agent' = 'SecretOptimizer-Installer'
}

$userProfile = [Environment]::GetFolderPath('UserProfile')
$installDir = "$userProfile\Secret-Optimizer"
$toolsDir = "$installDir\Tools"
$packagesDir = "$installDir\packages"
$versionFile = "$installDir\.version"
$mainBat = "$toolsDir\secret-optimizer.bat"
$rootLauncher = "$installDir\secret-optimizer.bat"
$desktop = [Environment]::GetFolderPath('Desktop')
$shortcutPath = "$desktop\Secret-Optimizer.lnk"

# -------------------------------------------------------------
# UNINSTALL / CLEANUP OLD LEGACY
# -------------------------------------------------------------
function Uninstall-SecretOptimizer {
    $wasInstalled = Test-Path $installDir
    Write-Host "${creamyCyan}[*] Cleaning up...${reset}"

    if ($wasInstalled) {
        Remove-Item -Path $installDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $shortcutPath) {
        Remove-Item -Path $shortcutPath -Force -ErrorAction SilentlyContinue
    }
    # Clean old legacy shortcuts & dirs
    $legacyShortcut = "$desktop\Secret-Tools.lnk"
    if (Test-Path $legacyShortcut) { Remove-Item -Path $legacyShortcut -Force -ErrorAction SilentlyContinue }
    if (Test-Path "$userProfile\Tools\secret-tools.bat") { Remove-Item -Path "$userProfile\Tools" -Recurse -Force -ErrorAction SilentlyContinue }

    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath) {
        $cleaned = ($userPath -split ';' | Where-Object { $_ -ne '' -and $_ -ne $installDir -and $_ -ne $toolsDir -and $_ -notlike "*\Tools" }) -join ';'
        if ($cleaned -ne $userPath) {
            [Environment]::SetEnvironmentVariable('Path', $cleaned, 'User')
        }
    }

    try { cmd /c 'schtasks /delete /tn "SecretTools_Elevated" /f' >nul 2>&1 } catch {}
    if (Test-Path "$env:LOCALAPPDATA\Secret-Optimizer") {
        Remove-Item -Path "$env:LOCALAPPDATA\Secret-Optimizer" -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path "$env:LOCALAPPDATA\Secret-Tools") {
        Remove-Item -Path "$env:LOCALAPPDATA\Secret-Tools" -Recurse -Force -ErrorAction SilentlyContinue
    }

    if ($wasInstalled) {
        Write-Host "${creamyGreen}[OK] Secret-Optimizer has been fully removed.${reset}"
    } else {
        Write-Host "${creamyGreen}[OK] Cleanup complete.${reset}"
    }
}

# -------------------------------------------------------------
# STEP 1: CONSENT & TRANSPARENCY NOTICE
# -------------------------------------------------------------
Clear-Host
Show-Banner
Write-Host '============================================================================================='
Write-Host '                         SECRET-OPTIMIZER INSTALLATION WIZARD'
Write-Host '============================================================================================='
Write-Host ''
Write-Host "${dimText}This installer deploys Secret-Optimizer to your system:${reset}"
Write-Host ''
Write-Host "${dimText}  - Functions: Intelligent RAM & process optimization, helper sleeping, gaming boost,${reset}"
Write-Host "${dimText}    controlled bloatware removal, telemetry & ads purge, and performance tuning.${reset}"
Write-Host "${dimText}  - Install location: ${reset}${creamyCyan}$installDir${reset}"
Write-Host "${dimText}    (added to your user PATH; desktop shortcut: Secret-Optimizer.lnk).${reset}"
Write-Host "${dimText}  - Local & Secure: 100% local scripts. No tracking, no external telemetry.${reset}"
Write-Host ''
Write-Host '============================================================================================='
Write-Host ''
Write-Host "Proceed with Secret-Optimizer setup? (Y/N)"
Write-Host "${dimText}  N = Cancel (removes previous versions if installed).${reset}"
Write-Host ''
$consent = Read-Host "Your choice"
if ($consent -notmatch '^[YySs]') {
    Write-Host ''
    Uninstall-SecretOptimizer
    Write-Host ''
    Write-Host 'Press Enter to exit...'
    [void][Console]::ReadLine()
    exit 0
}

# -------------------------------------------------------------
# STEP 2: SETUP DIRECTORIES & LOCAL DEPLOYMENT
# -------------------------------------------------------------
Write-Host ''
Write-Host "${creamyCyan}[*] Preparing local installation directory...${reset}"

if (-not (Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir -Force | Out-Null }
if (-not (Test-Path $toolsDir)) { New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null }
if (-not (Test-Path "$installDir\logs")) { New-Item -ItemType Directory -Path "$installDir\logs" -Force | Out-Null }

$localScriptRoot = if ($env:OPT_SOURCE_DIR -and (Test-Path $env:OPT_SOURCE_DIR)) {
    $env:OPT_SOURCE_DIR
} elseif ($PSScriptRoot) {
    $PSScriptRoot
} elseif ($MyInvocation.MyCommand -and $MyInvocation.MyCommand.Path) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    (Get-Location).Path
}

# Copy files from current project folder to installDir if different
if ($localScriptRoot -and (Test-Path "$localScriptRoot\Tools\secret-optimizer.bat")) {
    Copy-Item -Path "$localScriptRoot\Tools\*" -Destination $toolsDir -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path "$localScriptRoot\README.md") { Copy-Item -Path "$localScriptRoot\README.md" -Destination $installDir -Force -ErrorAction SilentlyContinue }
    if (Test-Path "$localScriptRoot\LICENSE") { Copy-Item -Path "$localScriptRoot\LICENSE" -Destination $installDir -Force -ErrorAction SilentlyContinue }
}

# Create root launcher forwarder
$rootForwarderContent = "@echo off`r`nsetlocal`r`nset `"SD=%~dp0`"`r`ncall `"%SD%Tools\secret-optimizer.bat`" %*`r`nexit /b %errorlevel%"
Set-Content -Path $rootLauncher -Value $rootForwarderContent -Force

# Register in User PATH
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$pArray = @($installDir, $toolsDir)
$pathList = if ($userPath) { $userPath -split ';' | Where-Object { $_ -ne '' -and $_ -notlike "*\Tools\Tools" } } else { @() }
$pathUpdated = $false
foreach ($p in $pArray) {
    if ($pathList -notcontains $p) { $pathList += $p; $pathUpdated = $true }
}
if ($pathUpdated) {
    $newPathStr = ($pathList | Where-Object { $_ -ne '' }) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $newPathStr, 'User')
    Write-Host "${creamyGreen}[OK] Added to User PATH (command: secret-optimizer).${reset}"
}

# Desktop shortcut (Secret-Optimizer.lnk)
$ws = New-Object -ComObject WScript.Shell
$shortcut = $ws.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $mainBat
$shortcut.WorkingDirectory = $toolsDir
$shortcut.Description = 'Secret-Optimizer Advanced Process & Performance Suite'
$shortcut.Save()

try {
    $lnkBytes = [System.IO.File]::ReadAllBytes($shortcutPath)
    $lnkBytes[0x15] = $lnkBytes[0x15] -bor 0x20
    [System.IO.File]::WriteAllBytes($shortcutPath, $lnkBytes)
} catch {}

# Clean old legacy shortcut
$legacyShortcut = "$desktop\Secret-Tools.lnk"
if (Test-Path $legacyShortcut) { Remove-Item $legacyShortcut -Force -ErrorAction SilentlyContinue }

Write-Host "${creamyGreen}[OK] Desktop shortcut created (Secret-Optimizer.lnk).${reset}"

# -------------------------------------------------------------
# STEP 3: WELCOME & DIRECT ELEVATED LAUNCH
# -------------------------------------------------------------
Write-Host ''
Write-Host '====================================================================='
Write-Host " Welcome, $env:USERNAME."
Write-Host ' Status: Secret-Optimizer deployed successfully.'
Write-Host ' Launching Secret-Optimizer...'
Write-Host '====================================================================='
Write-Host ''
Start-Sleep -Milliseconds 800

if (Test-Path $mainBat) {
    cmd /c "`"$mainBat`""
} elseif (Test-Path "$localScriptRoot\Tools\secret-optimizer.bat") {
    cmd /c "`"$localScriptRoot\Tools\secret-optimizer.bat`""
}
exit 0
