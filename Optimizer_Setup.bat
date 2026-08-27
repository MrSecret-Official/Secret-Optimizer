<# :
@echo off
setlocal EnableDelayedExpansion
title Optimizer_Setup - Secret-Optimizer Installer
color 0B
mode con: cols=105 lines=52 >nul 2>&1

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
# PATHS & GITHUB CONFIGURATION
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
$repoApi = 'https://api.github.com/repos/MrSecret-Official/Secret-Optimizer'
$repoWeb = 'https://github.com/MrSecret-Official/Secret-Optimizer'
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
Write-Host "${dimText}Before anything is downloaded or changed, here is exactly what this installer does:${reset}"
Write-Host ''
Write-Host "${dimText}  - Network activity: checks and downloads source files from the public repository:${reset}"
Write-Host "    ${creamyCyan}$repoWeb${reset}"
Write-Host "${dimText}    (No analytics, no personal data, no tracking of any kind).${reset}"
Write-Host "${dimText}  - Functions: Intelligent RAM cleaner, process booster, helper freezer, gaming turbo,${reset}"
Write-Host "${dimText}    controlled Windows bloatware remover, telemetry purge, and services optimizer.${reset}"
Write-Host "${dimText}  - Install location: ${reset}${creamyCyan}$installDir${reset}"
Write-Host "${dimText}    (added to user PATH; desktop shortcut is created: Secret-Optimizer.lnk).${reset}"
Write-Host ''
Write-Host '============================================================================================='
Write-Host ''
Write-Host "Proceed with Secret-Optimizer setup and download? (Y/N)"
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
# STEP 2: ANTIVIRUS DETECTION & WHITELIST NOTICE
# -------------------------------------------------------------
function Get-DetectedAntivirus {
    $results = @()
    try {
        $wmi = Get-CimInstance -Namespace 'root/SecurityCenter2' -ClassName 'AntiVirusProduct' -ErrorAction Stop
        foreach ($item in $wmi) {
            $hex = ([int]$item.productState).ToString('X6')
            $rtByte = if ($hex.Length -ge 4) { $hex.Substring(2,2) } else { '00' }
            $isActive = ($rtByte -in @('10', '11'))
            $results += [PSCustomObject]@{
                Name     = $item.displayName
                IsActive = $isActive
                Path     = $item.pathToSignedProductExe
            }
        }
    } catch {}

    if ($results.Count -eq 0) {
        $procMap = [ordered]@{
            'MsMpEng'     = 'Windows Defender'
            'AvastSvc'    = 'Avast Antivirus'
            'AvgSvc'      = 'AVG Antivirus'
            'avp'         = 'Kaspersky'
            'vsserv'      = 'Bitdefender'
            'ccSvcHst'    = 'Norton / Symantec'
            'mcshield'    = 'McAfee'
            'MBAMService' = 'Malwarebytes'
            'ekrn'        = 'ESET Security'
            'SophosEDR'   = 'Sophos'
        }
        foreach ($p in $procMap.Keys) {
            if (Get-Process -Name $p -ErrorAction SilentlyContinue) {
                $results += [PSCustomObject]@{
                    Name     = $procMap[$p]
                    IsActive = $true
                    Path     = ''
                }
            }
        }
    }
    return $results
}

Clear-Host
Show-Banner
Write-Host '============================================================================================='
Write-Host '                         ANTIVIRUS / SECURITY SOFTWARE NOTICE'
Write-Host '============================================================================================='
Write-Host ''
Write-Host "${creamyYellow}[NOTE] Diagnostic & optimization scripts may occasionally trigger antivirus warnings.${reset}"
Write-Host ''

# Ensure target directories exist
if (-not (Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir -Force | Out-Null }
if (-not (Test-Path $toolsDir)) { New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null }
if (-not (Test-Path $packagesDir)) { New-Item -ItemType Directory -Path $packagesDir -Force | Out-Null }
if (-not (Test-Path "$installDir\logs")) { New-Item -ItemType Directory -Path "$installDir\logs" -Force | Out-Null }

$detectedAVs = Get-DetectedAntivirus
Write-Host "${creamyCyan}Detected Security Engines on this PC:${reset}"
if ($detectedAVs.Count -gt 0) {
    foreach ($av in $detectedAVs) {
        $statusBadge = if ($av.IsActive) { "${creamyGreen}[ACTIVE]${reset}" } else { "${dimText}[INACTIVE]${reset}" }
        Write-Host "  * $($av.Name) $statusBadge"
    }
} else {
    Write-Host "  * Windows Defender ${creamyGreen}[ACTIVE]${reset}"
}
Write-Host ''
Write-Host "${creamyCyan}Installation Directory to Exclude (if needed):${reset}"
Write-Host "  ${creamyGreen}$installDir${reset}"
Write-Host ''
Write-Host '============================================================================================='
Write-Host ''
Write-Host 'Press Enter to continue with setup...'
[void][Console]::ReadLine()

# -------------------------------------------------------------
# STEP 3: CHECK REPOSITORY VERSION (GITHUB API)
# -------------------------------------------------------------
Write-Host ''
Write-Host "${creamyCyan}Checking GitHub repository version ($repoWeb)...${reset}"
$remoteSha = $null
try {
    $commitInfo = Invoke-RestMethod -Uri "$repoApi/commits/main" -Headers $headers -Method Get -TimeoutSec 10 -ErrorAction SilentlyContinue
    if ($commitInfo -and $commitInfo.sha) {
        $remoteSha = $commitInfo.sha
    }
} catch {}

$localSha = ''
if (Test-Path $versionFile) { $localSha = (Get-Content $versionFile -Raw -ErrorAction SilentlyContinue).Trim() }

$localScriptRoot = if ($env:OPT_SOURCE_DIR -and (Test-Path $env:OPT_SOURCE_DIR)) {
    $env:OPT_SOURCE_DIR
} elseif ($PSScriptRoot) {
    $PSScriptRoot
} elseif ($MyInvocation.MyCommand -and $MyInvocation.MyCommand.Path) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    (Get-Location).Path
}

$hasLocalFiles = ($localScriptRoot -and (Test-Path "$localScriptRoot\Tools\secret-optimizer.bat"))
$needsDownload = ($null -ne $remoteSha -and $localSha -ne $remoteSha) -or (-not (Test-Path $mainBat))

if ($needsDownload -and $remoteSha) {
    if ($localSha -eq '') {
        Write-Host "${creamyGreen}[INFO] Components ready for installation from GitHub ($($remoteSha.Substring(0,7))).${reset}"
    } else {
        Write-Host "${creamyGreen}[INFO] Update available on GitHub ($($remoteSha.Substring(0,7))).${reset}"
    }
} elseif (-not $needsDownload) {
    Write-Host "${creamyGreen}[INFO] Secret-Optimizer is up to date ($($localSha.Substring(0,7))).${reset}"
}

# -------------------------------------------------------------
# STEP 4: DOWNLOAD / SYNC COMPONENTS
# -------------------------------------------------------------
Write-Host ''
$deployedSuccessfully = $false

# 1. Try GitHub Download if update needed
if ($needsDownload -and $remoteSha) {
    Write-Host "${creamyGreen}[DOWNLOAD] Fetching latest release from GitHub...${reset}"
    $targetZip = "$packagesDir\SecretOptimizer_Package.zip"
    $targetExtract = "$packagesDir\SecretOptimizer_Extract"
    try {
        Invoke-RestMethod -Uri "$repoApi/zipball/main" -Headers $headers -OutFile $targetZip -TimeoutSec 30
        if (Test-Path $targetExtract) { Remove-Item $targetExtract -Recurse -Force -ErrorAction SilentlyContinue }
        Expand-Archive -Path $targetZip -DestinationPath $targetExtract -Force
        $extractedRoot = (Get-ChildItem -Path $targetExtract -Directory | Select-Object -First 1).FullName
        if ($extractedRoot -and (Test-Path "$extractedRoot\Tools")) {
            Copy-Item -Path "$extractedRoot\Tools\*" -Destination $toolsDir -Recurse -Force
            if (Test-Path "$extractedRoot\README.md") { Copy-Item -Path "$extractedRoot\README.md" -Destination $installDir -Force }
            if (Test-Path "$extractedRoot\LICENSE") { Copy-Item -Path "$extractedRoot\LICENSE" -Destination $installDir -Force }
            Set-Content -Path $versionFile -Value $remoteSha -Force
            Write-Host "${creamyGreen}[OK] Package successfully downloaded and deployed from GitHub.${reset}"
            $deployedSuccessfully = $true
        }
    } catch {
        Write-Host "${creamyYellow}[WARN] GitHub download failed: $($_.Exception.Message)${reset}"
    } finally {
        if (Test-Path $targetZip) { Remove-Item $targetZip -Force -ErrorAction SilentlyContinue }
        if (Test-Path $targetExtract) { Remove-Item $targetExtract -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

# 2. Synchronize Local Workspace Files (Guarantee local availability)
if ($hasLocalFiles) {
    Write-Host "${creamyCyan}[*] Synchronizing local component files...${reset}"
    Copy-Item -Path "$localScriptRoot\Tools\*" -Destination $toolsDir -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path "$localScriptRoot\README.md") { Copy-Item -Path "$localScriptRoot\README.md" -Destination $installDir -Force -ErrorAction SilentlyContinue }
    if (Test-Path "$localScriptRoot\LICENSE") { Copy-Item -Path "$localScriptRoot\LICENSE" -Destination $installDir -Force -ErrorAction SilentlyContinue }
    if ($remoteSha) { Set-Content -Path $versionFile -Value $remoteSha -Force -ErrorAction SilentlyContinue }
    $deployedSuccessfully = $true
    Write-Host "${creamyGreen}[OK] Local component files synchronized.${reset}"
}

if (-not (Test-Path $mainBat)) {
    Write-Host "${creamyRed}[ERROR] secret-optimizer.bat could not be located or installed.${reset}"
    Write-Host 'Press Enter to exit...'
    [void][Console]::ReadLine()
    exit 1
}

# Root launcher forwarder
$rootForwarderContent = "@echo off`r`nsetlocal`r`nset `"SD=%~dp0`"`r`ncall `"%SD%Tools\secret-optimizer.bat`" %*`r`nexit /b %errorlevel%"
Set-Content -Path $rootLauncher -Value $rootForwarderContent -Force

# Register in User PATH
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$pArray = @($installDir, $toolsDir)
$pathList = if ($userPath) { $userPath -split ';' | Where-Object { $_ -ne '' } } else { @() }
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

Write-Host "${creamyGreen}[OK] Desktop shortcut created: Secret-Optimizer.lnk${reset}"

# -------------------------------------------------------------
# STEP 5: WELCOME & DIRECT ELEVATED LAUNCH
# -------------------------------------------------------------
Write-Host ''
Write-Host '====================================================================='
Write-Host " Welcome, $env:USERNAME."
Write-Host ' Status: Secret-Optimizer installed and verified successfully.'
Write-Host ' Launching Secret-Optimizer...'
Write-Host '====================================================================='
Write-Host ''
Start-Sleep -Milliseconds 800

if (Test-Path $mainBat) {
    cmd /c "`"$mainBat`""
}
exit 0
