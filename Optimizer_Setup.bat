<# :
@echo off
setlocal EnableDelayedExpansion
title Setup-Tools - Secret-Optimizer Installer
color 0B
mode con: cols=105 lines=55 >nul 2>&1

:: Auto-elevate to Administrator if not already elevated
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([ScriptBlock]::Create((Get-Content -LiteralPath '%~f0' -Raw)))"
exit /b %errorlevel%
#>

<#
.SYNOPSIS
    Secret-Optimizer Automated Installation & Management Package
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

$installDir = "$([Environment]::GetFolderPath('UserProfile'))\Tools"
$toolsDir = "$installDir\Tools"
$packagesDir = "$installDir\packages"
$versionFile = "$installDir\.version"
$mainBat = "$toolsDir\secret-tools.bat"
$mainOptBat = "$toolsDir\secret-optimizer.bat"
$rootLauncher = "$installDir\secret-optimizer.bat"
$rootLegacyLauncher = "$installDir\secret-tools.bat"
$repoApi = 'https://api.github.com/repos/MrSecret-Official/Secret-Tools-Win'
$desktop = [Environment]::GetFolderPath('Desktop')
$shortcutPath = "$desktop\Secret-Optimizer.lnk"
$legacyShortcutPath = "$desktop\Secret-Tools.lnk"

# -------------------------------------------------------------
# UNINSTALL
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
    if (Test-Path $legacyShortcutPath) {
        Remove-Item -Path $legacyShortcutPath -Force -ErrorAction SilentlyContinue
    }

    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath) {
        $cleaned = ($userPath -split ';' | Where-Object { $_ -ne '' -and $_ -ne $installDir -and $_ -ne $toolsDir }) -join ';'
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
        Write-Host "${creamyGreen}[OK] Secret-Optimizer has been fully removed. No files, PATH entries, or shortcuts remain.${reset}"
    } else {
        Write-Host "${creamyGreen}[OK] Nothing was installed - no changes were made to this computer.${reset}"
    }
}

# -------------------------------------------------------------
# STEP 1: CONSENT & TRANSPARENCY NOTICE
# -------------------------------------------------------------
Clear-Host
Show-Banner
Write-Host '============================================================================================='
Write-Host '                              AUTOMATED INSTALLATION WIZARD'
Write-Host '============================================================================================='
Write-Host ''
Write-Host "${dimText}Before anything is downloaded or changed, here is exactly what this does:${reset}"
Write-Host ''
Write-Host "${dimText}  - Network activity: downloads its own source files from the public GitHub${reset}"
Write-Host "${dimText}    repo MrSecret-Official/Secret-Tools-Win. That is the ONLY network activity${reset}"
Write-Host "${dimText}    this tool ever performs - no telemetry, no analytics, no personal data.${reset}"
Write-Host "${dimText}  - Privileges: requests Administrator rights next (Windows' own UAC prompt).${reset}"
Write-Host "${dimText}  - Capabilities: Intelligent RAM working set optimization, safe Windows debloat,${reset}"
Write-Host "${dimText}    system diagnostics, boot/SrtTrail repair, DISM/SFC, and system restore.${reset}"
Write-Host "${dimText}  - Install location: ${reset}${creamyCyan}$installDir${reset}"
Write-Host "${dimText}    (added to your user PATH; desktop shortcut is created: Secret-Optimizer.lnk).${reset}"
Write-Host ''
Write-Host "${dimText}Every line of source is on GitHub - read it before you trust it:${reset}"
Write-Host "${creamyCyan}https://github.com/MrSecret-Official/Secret-Tools-Win${reset}"
Write-Host ''
Write-Host '============================================================================================='
Write-Host ''
Write-Host "Continue with the download and installation? (Y/N)"
Write-Host "${dimText}  N = nothing is installed (and if already installed, it is removed completely).${reset}"
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
# STEP 2: ANTIVIRUS DETECTION & EXCLUSION NOTICE
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
Write-Host "${creamyYellow}[WARNING] Antivirus software may intercept, pause, or scan administrative scripts!${reset}"
Write-Host ''
Write-Host "${dimText}Because Secret-Optimizer contains administrative diagnostic, RAM optimization, repair,${reset}"
Write-Host "${dimText}and system management scripts, antivirus engines occasionally trigger false positives.${reset}"
Write-Host ''

if (-not (Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir -Force | Out-Null }
if (-not (Test-Path $toolsDir)) { New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null }
if (-not (Test-Path $packagesDir)) { New-Item -ItemType Directory -Path $packagesDir -Force | Out-Null }
if (-not (Test-Path "$toolsDir\Access")) { New-Item -ItemType Directory -Path "$toolsDir\Access" -Force | Out-Null }
if (-not (Test-Path "$toolsDir\logs")) { New-Item -ItemType Directory -Path "$toolsDir\logs" -Force | Out-Null }

$detectedAVs = Get-DetectedAntivirus
Write-Host "${creamyCyan}Detected Security & Antivirus Engines on this PC:${reset}"
if ($detectedAVs.Count -gt 0) {
    foreach ($av in $detectedAVs) {
        $statusBadge = if ($av.IsActive) { "${creamyGreen}[ACTIVE / IN USE]${reset}" } else { "${dimText}[INACTIVE / SECONDARY]${reset}" }
        Write-Host "  * $($av.Name) $statusBadge"
    }
} else {
    Write-Host "  * Windows Security / Microsoft Defender ${creamyGreen}[ACTIVE / IN USE]${reset}"
}
Write-Host ''

Write-Host "${creamyCyan}Target Directory to Exclude:${reset}"
Write-Host "  ${creamyGreen}$installDir${reset}"
Write-Host ''

$activeNames = ($detectedAVs | Where-Object { $_.IsActive } | Select-Object -ExpandProperty Name) -join ' '
if (-not $activeNames) { $activeNames = ($detectedAVs | Select-Object -ExpandProperty Name) -join ' ' }

$isThirdParty = ($activeNames -match 'Avast|AVG|Kaspersky|Bitdefender|Norton|Symantec|McAfee|ESET|Malwarebytes|Sophos')

if ($isThirdParty) {
    Write-Host "${creamyYellow}[!] Note: Third-party antivirus software detected ($activeNames).${reset}"
    Write-Host "${dimText}    Please open your antivirus control panel and add the folder exception if needed:${reset}"
    Write-Host "    ${creamyCyan}$installDir${reset}"
    Write-Host ''
}

Write-Host '============================================================================================='
Write-Host ''
Write-Host 'Press Enter to proceed with download and installation...'
[void][Console]::ReadLine()

# -------------------------------------------------------------
# STEP 3: CHECK REPOSITORY VERSION
# -------------------------------------------------------------
Write-Host ''
Write-Host "${creamyCyan}Checking repository update status...${reset}"
$remoteSha = $null
try {
    $commitInfo = Invoke-RestMethod -Uri "$repoApi/commits/main" -Headers $headers -Method Get -TimeoutSec 10 -ErrorAction SilentlyContinue
    $remoteSha = $commitInfo.sha
} catch {}

if (-not $remoteSha) {
    Write-Host "${creamyRed}[WARN] Could not reach GitHub. Check your internet connection.${reset}"
}

$localSha = ''
if (Test-Path $versionFile) { $localSha = (Get-Content $versionFile -Raw -ErrorAction SilentlyContinue).Trim() }
$needsDownload = ($null -ne $remoteSha -and $localSha -ne $remoteSha) -or (-not (Test-Path $mainBat))

if ($needsDownload -and $remoteSha) {
    if ($localSha -eq '') {
        Write-Host "${creamyGreen}[INFO] Components ready for initial installation.${reset}"
    } else {
        Write-Host "${creamyGreen}[INFO] Update available ($($remoteSha.Substring(0,7))).${reset}"
    }
} elseif (-not $needsDownload) {
    Write-Host "${creamyGreen}[INFO] System is up to date ($($localSha.Substring(0,7))).${reset}"
}

# -------------------------------------------------------------
# STEP 4: PERFORM DOWNLOAD / UPDATE & DEPLOYMENT
# -------------------------------------------------------------
Write-Host ''
if ($needsDownload) {
    if (-not $remoteSha) {
        if (-not (Test-Path $mainBat)) {
            Write-Host "${creamyRed}[ERROR] Unable to connect to GitHub for initial installation.${reset}"
            Write-Host 'Press Enter to exit...'
            [void][Console]::ReadLine()
            exit 1
        } else {
            Write-Host "${creamyYellow}[OFFLINE] Could not reach GitHub. Using existing installation.${reset}"
        }
    } else {
        if ($localSha -eq '') {
            Write-Host "${creamyGreen}[DOWNLOAD] Downloading and installing Secret-Optimizer components...${reset}"
        } else {
            Write-Host "${creamyGreen}[UPDATE] Deploying update ($($remoteSha.Substring(0,7)))...${reset}"
        }
        $targetZip = "$packagesDir\SecretOptimizer_Package.zip"
        $targetExtract = "$packagesDir\SecretOptimizer_Extract"
        try {
            Invoke-RestMethod -Uri "$repoApi/zipball/main" -Headers $headers -OutFile $targetZip -TimeoutSec 30
            if (Test-Path $targetExtract) { Remove-Item $targetExtract -Recurse -Force -ErrorAction SilentlyContinue }
            Expand-Archive -Path $targetZip -DestinationPath $targetExtract -Force
            $extractedRoot = (Get-ChildItem -Path $targetExtract -Directory | Select-Object -First 1).FullName
            Copy-Item -Path "$extractedRoot\*" -Destination $installDir -Recurse -Force
            Set-Content -Path $versionFile -Value $remoteSha -Force
            Write-Host "${creamyGreen}[OK] Components successfully deployed.${reset}"
        } catch {
            Write-Host "${creamyRed}[ERROR] Download failed: $($_.Exception.Message)${reset}"
            if (-not (Test-Path $mainBat)) {
                Write-Host 'Press Enter to exit...'
                [void][Console]::ReadLine()
                exit 1
            }
        } finally {
            if (Test-Path $targetZip) { Remove-Item $targetZip -Force -ErrorAction SilentlyContinue }
            if (Test-Path $targetExtract) { Remove-Item $targetExtract -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }
} else {
    Write-Host "${creamyGreen}[OK] Components already deployed and verified.${reset}"
}

# Root launcher forwarders for secret-optimizer and secret-tools
$rootForwarderContent = "@echo off`r`nsetlocal`r`nset `"SD=%~dp0`"`r`nif exist `"%SD%Tools\secret-tools.bat`" (`r`n    call `"%SD%Tools\secret-tools.bat`" %*`r`n) else (`r`n    powershell -NoProfile -ExecutionPolicy Bypass -File `"%SD%Tools\Access\Password_manager.ps1`" %*`r`n)`r`nexit /b %errorlevel%"
Set-Content -Path $rootLauncher -Value $rootForwarderContent -Force
Set-Content -Path $rootLegacyLauncher -Value $rootForwarderContent -Force

# Register in User PATH
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$pArray = @($installDir, $toolsDir)
$pathList = if ($userPath) { $userPath -split ';' } else { @() }
$pathUpdated = $false
foreach ($p in $pArray) {
    if ($pathList -notcontains $p) { $pathList += $p; $pathUpdated = $true }
}
if ($pathUpdated) {
    $newPathStr = ($pathList | Where-Object { $_ -ne '' }) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $newPathStr, 'User')
    Write-Host "${creamyGreen}[OK] Added to User PATH (commands: secret-optimizer, secret-tools).${reset}"
}

# Desktop shortcut (Secret-Optimizer.lnk)
$ws = New-Object -ComObject WScript.Shell
$shortcut = $ws.CreateShortcut($shortcutPath)
$shortcut.TargetPath = if (Test-Path $mainOptBat) { $mainOptBat } else { $mainBat }
$shortcut.WorkingDirectory = $toolsDir
$shortcut.Description = 'Secret-Optimizer System Optimization, RAM Cleaner and Repair Suite'
$shortcut.Save()

try {
    $lnkBytes = [System.IO.File]::ReadAllBytes($shortcutPath)
    $lnkBytes[0x15] = $lnkBytes[0x15] -bor 0x20
    [System.IO.File]::WriteAllBytes($shortcutPath, $lnkBytes)
} catch {}

if (Test-Path $legacyShortcutPath) {
    Remove-Item $legacyShortcutPath -Force -ErrorAction SilentlyContinue
}

Write-Host "${creamyGreen}[OK] Desktop shortcut created (Secret-Optimizer.lnk).${reset}"

# -------------------------------------------------------------
# STEP 5: FORMAL WELCOME & DIRECT ELEVATED LAUNCH
# -------------------------------------------------------------
Write-Host ''
Write-Host '====================================================================='
Write-Host " Welcome, $env:USERNAME."
Write-Host ' Status: Secret-Optimizer installed and verified successfully.'
Write-Host ' Launching Secret-Optimizer (it will request Administrator elevation once)...'
Write-Host '====================================================================='
Write-Host ''
Start-Sleep -Milliseconds 800

if (Test-Path $mainBat) {
    cmd /c "`"$mainBat`""
} elseif (Test-Path "$toolsDir\Access\Password_manager.ps1") {
    & "$toolsDir\Access\Password_manager.ps1"
}
exit 0
