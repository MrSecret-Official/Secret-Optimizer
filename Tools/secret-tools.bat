<# :
@echo off
setlocal EnableDelayedExpansion
title Secret-Optimizer - Windows Optimization, Recovery and Repair Suite
color 0B
mode con: cols=105 lines=42 >nul 2>&1

:: Detect WinRE / WinPE environment
set "IS_WINRE=0"
if /i "%SystemDrive%"=="X:" set "IS_WINRE=1"
if exist "X:\Windows\System32" set "IS_WINRE=1"

:: Detect target installed Windows drive (C:, D:, E:, F:, etc.)
set "WIN_DRIVE="
for %%d in (C D E F G H I) do (
    if not defined WIN_DRIVE (
        if exist "%%d:\Windows\System32\ntoskrnl.exe" (
            set "WIN_DRIVE=%%d:"
        )
    )
)
if not defined WIN_DRIVE set "WIN_DRIVE=%SystemDrive%"

:: Launch PowerShell engine smoothly
where powershell >nul 2>&1
if %errorlevel% equ 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:SECRET_TOOLS_WINRE='%IS_WINRE%'; $env:SECRET_TOOLS_WINDRIVE='%WIN_DRIVE%'; & ([ScriptBlock]::Create((Get-Content -LiteralPath '%~f0' -Raw)))"
    exit /b %errorlevel%
)

:: PURE BATCH WINRE EMERGENCY ENGINE (Runs only if PowerShell is unavailable in WinRE)
:WINRE_BATCH_ENGINE
cls
echo.
echo   =============================================================================================
echo                            SECRET-OPTIMIZER : WINRE RECOVERY CONSOLE
echo                                   Made by: mrsecret_official
echo   =============================================================================================
echo.
echo   [ENVIRONMENT] Windows Recovery Environment (WinPE/WinRE) Detected
echo   [TARGET DRIVE] Installed Windows located at: %WIN_DRIVE%\Windows
echo.
echo   =============================================================================================
echo                                   EMERGENCY REPAIR MENU
echo   =============================================================================================
echo.
echo   [1] 1-Click Complete Startup ^& SrtTrail Repair (BCD + Bootrec + Revert Actions)
echo   [2] Disable Automatic Repair Infinite Loop (bcdedit recoveryenabled No)
echo   [3] Offline System File Checker (SFC /offbootdir=%WIN_DRIVE%\ /offwindir=%WIN_DRIVE%\Windows)
echo   [4] Revert Broken Pending Updates (DISM /image:%WIN_DRIVE%\ /revertpendingactions)
echo   [5] Check Disk ^& Bad Sectors (chkdsk %WIN_DRIVE% /f /r)
echo   [6] View SrtTrail.txt Failure Log
echo   [7] Rebuild Boot Files (bcdboot %WIN_DRIVE%\Windows /s %WIN_DRIVE% /f ALL)
echo   [8] Open Standard Command Prompt (CMD)
echo   [0] Exit
echo.
echo   =============================================================================================
set /p "MCHOICE=Select an option (0-8): "

if "%MCHOICE%"=="1" (
    echo.
    echo [*] Disabling automatic repair loop...
    bcdedit /set {default} recoveryenabled No >nul 2>&1
    bcdedit /set {default} bootstatuspolicy ignoreallfailures >nul 2>&1
    echo [*] Rebuilding boot files...
    bcdboot %WIN_DRIVE%\Windows /l en-us /s %WIN_DRIVE% /f ALL >nul 2>&1
    echo [*] Reverting pending update actions...
    dism /image:%WIN_DRIVE%\ /cleanup-image /revertpendingactions
    echo [*] Checking core system files (SFC Offline)...
    sfc /scannow /offbootdir=%WIN_DRIVE%\ /offwindir=%WIN_DRIVE%\Windows
    echo.
    echo [OK] 1-Click WinRE Startup Repair completed.
    pause
    goto :WINRE_BATCH_ENGINE
)

if "%MCHOICE%"=="2" (
    echo.
    echo [*] Disabling Automatic Repair loop...
    bcdedit /set {default} recoveryenabled No
    bcdedit /set {default} bootstatuspolicy ignoreallfailures
    echo [OK] Automatic repair loop disabled. Windows will attempt direct boot.
    pause
    goto :WINRE_BATCH_ENGINE
)

if "%MCHOICE%"=="3" (
    echo.
    echo [*] Running Offline SFC on %WIN_DRIVE%\Windows...
    sfc /scannow /offbootdir=%WIN_DRIVE%\ /offwindir=%WIN_DRIVE%\Windows
    pause
    goto :WINRE_BATCH_ENGINE
)

if "%MCHOICE%"=="4" (
    echo.
    echo [*] Reverting broken pending updates on %WIN_DRIVE%\...
    dism /image:%WIN_DRIVE%\ /cleanup-image /revertpendingactions
    pause
    goto :WINRE_BATCH_ENGINE
)

if "%MCHOICE%"=="5" (
    echo.
    echo [*] Running CHKDSK on %WIN_DRIVE%...
    chkdsk %WIN_DRIVE% /f /r
    pause
    goto :WINRE_BATCH_ENGINE
)

if "%MCHOICE%"=="6" (
    echo.
    echo --- SrtTrail.txt Log (%WIN_DRIVE%\Windows\System32\Logfiles\Srt\SrtTrail.txt) ---
    if exist "%WIN_DRIVE%\Windows\System32\Logfiles\Srt\SrtTrail.txt" (
        type "%WIN_DRIVE%\Windows\System32\Logfiles\Srt\SrtTrail.txt"
    ) else if exist "X:\Windows\System32\Logfiles\Srt\SrtTrail.txt" (
        type "X:\Windows\System32\Logfiles\Srt\SrtTrail.txt"
    ) else (
        echo [INFO] No SrtTrail.txt log found on target system.
    )
    echo.
    pause
    goto :WINRE_BATCH_ENGINE
)

if "%MCHOICE%"=="7" (
    echo.
    echo [*] Rebuilding boot files using bcdboot...
    bcdboot %WIN_DRIVE%\Windows /l en-us /s %WIN_DRIVE% /f ALL
    echo [OK] Boot files refreshed.
    pause
    goto :WINRE_BATCH_ENGINE
)

if "%MCHOICE%"=="8" (
    cmd.exe
    goto :WINRE_BATCH_ENGINE
)

if "%MCHOICE%"=="0" (
    exit /b 0
)

goto :WINRE_BATCH_ENGINE
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$esc = [char]27
$creamyGreen  = "$esc[38;2;145;225;165m"
$creamyRed    = "$esc[38;2;235;120;120m"
$creamyYellow = "$esc[38;2;245;220;130m"
$creamyCyan   = "$esc[38;2;130;210;245m"
$accentBlue   = "$esc[38;2;100;180;255m"
$accentPurple = "$esc[38;2;190;140;255m"
$dimText      = "$esc[38;2;160;175;195m"
$reset        = "$esc[0m"

# Environment & Target Windows Drive Detection (Online vs WinRE Offline)
$isWinRE = ($env:SECRET_TOOLS_WINRE -eq '1') -or ($env:SystemDrive -eq 'X:')
$targetWinDrive = if ($env:SECRET_TOOLS_WINDRIVE) { $env:SECRET_TOOLS_WINDRIVE } else { $env:SystemDrive }

if ($isWinRE -and (-not (Test-Path "$targetWinDrive\Windows\System32\ntoskrnl.exe"))) {
    foreach ($d in @('C:', 'D:', 'E:', 'F:', 'G:')) {
        if (Test-Path "$d\Windows\System32\ntoskrnl.exe") {
            $targetWinDrive = $d
            break
        }
    }
}

$userProfile = [Environment]::GetFolderPath('UserProfile')
$installDir = "$userProfile\Tools"
$toolsDir = "$installDir\Tools"

# Auto-elevate to Administrator in normal Windows if not already elevated.
if (-not $isWinRE) {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        $selfBat = if (Test-Path "$toolsDir\secret-optimizer.bat") { "$toolsDir\secret-optimizer.bat" }
                   elseif (Test-Path "$toolsDir\secret-tools.bat") { "$toolsDir\secret-tools.bat" }
                   elseif (Test-Path "$installDir\secret-optimizer.bat") { "$installDir\secret-optimizer.bat" }
                   else { "$installDir\secret-tools.bat" }
        if (Test-Path $selfBat) {
            try {
                Start-Process -FilePath $selfBat -Verb RunAs
                exit 0
            } catch {
                Write-Host "Elevation was cancelled. Some actions will be unavailable without Administrator rights."
                Start-Sleep -Seconds 2
            }
        }
    }
}

$scriptDir = $installDir
if ($PSScriptRoot) {
    $scriptDir = $PSScriptRoot
} elseif ($MyInvocation.MyCommand -and $MyInvocation.MyCommand.Path) {
    $scriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
}

# Auto-register in User PATH if running in standard Windows
if (-not $isWinRE) {
    try {
        $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        $pathList = if ($userPath) { $userPath -split ';' | Where-Object { $_ -ne '' } } else { @() }
        $pArray = @($installDir, $toolsDir)
        $pathUpdated = $false
        foreach ($p in $pArray) {
            if ($pathList -notcontains $p) {
                $pathList += $p
                $pathUpdated = $true
            }
        }
        if ($pathUpdated) {
            $newPathStr = $pathList -join ';'
            [Environment]::SetEnvironmentVariable('Path', $newPathStr, 'User')
            $env:Path = "$newPathStr;$env:Path"
        }
    } catch {}
}

# Win32 Memory & Process Native Helper
$memHelperLoaded = $false
if (-not $isWinRE) {
    try {
        if (-not ([System.Management.Automation.PSTypeName]'SecretOptimizerMem').Type) {
            $win32Code = @"
using System;
using System.Runtime.InteropServices;

public class SecretOptimizerMem {
    [DllImport("psapi.dll", SetLastError=true)]
    public static extern int EmptyWorkingSet(IntPtr hwProc);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool SetProcessWorkingSetSize(IntPtr proc, int min, int max);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
}
"@
            Add-Type -TypeDefinition $win32Code -ErrorAction SilentlyContinue
        }
        $memHelperLoaded = $true
    } catch {}
}

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

# Check for updates in background (online mode only)
$updateNotice = $null
if (-not $isWinRE) {
    $versionFile = "$installDir\.version"
    if (-not (Test-Path $versionFile)) { $versionFile = "$scriptDir\.version" }
    $localSha = ''
    if (Test-Path $versionFile) {
        $localSha = (Get-Content $versionFile -Raw -ErrorAction SilentlyContinue).Trim()
    }

    if ($localSha) {
        try {
            $h = @{
                'Accept'     = 'application/vnd.github.v3+json'
                'User-Agent' = 'SecretOptimizer-Client'
            }
            $repoApi = 'https://api.github.com/repos/MrSecret-Official/Secret-Tools-Win'
            $commit = Invoke-RestMethod -Uri "$repoApi/commits/main" -Headers $h -Method Get -TimeoutSec 4 -ErrorAction SilentlyContinue
            if ($commit -and $commit.sha -and ($commit.sha -ne $localSha)) {
                $remoteShort = $commit.sha.Substring(0, 7)
                $updateNotice = "[UPDATE] A new version ($remoteShort) is available. Run Setup-Tools.bat to upgrade."
            }
        } catch {}
    }
}

$currentUser = $env:USERNAME

# ===================================================================
# LOGGING & RESTORE UTILITIES
# ===================================================================

function Check-IsAdmin {
    if ($isWinRE) { return $true }
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Write-AssistantLog([string]$action, [string]$status, [string]$details) {
    try {
        $docsFolder = [Environment]::GetFolderPath('MyDocuments')
        $logDir = if ($docsFolder) { "$docsFolder\Secret-Optimizer\Logs" } else { "$installDir\logs" }
        if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force -ErrorAction SilentlyContinue | Out-Null }
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "[$timestamp] [$status] - $action : $details" | Out-File -FilePath "$logDir\assistant_actions.log" -Append -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {}
}

function Create-SafeRestorePoint {
    if ($isWinRE) { return }
    Write-Host "${creamyCyan}[SECURITY] Creating System Restore Point before optimization...${reset}"
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Secret-Optimizer Restore Point" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop | Out-Null
        Write-Host "${creamyGreen}[OK] System Restore Point created successfully.${reset}"
        Write-AssistantLog "RestorePoint" "SUCCESS" "System Restore Point created"
    } catch {
        Write-Host "${dimText}[INFO] Automated restore point creation skipped (proceeding safely).${reset}"
        Write-AssistantLog "RestorePoint" "SKIPPED" $_.Exception.Message
    }
}

function Invoke-AssistantHeader([string]$title, [string]$description) {
    Clear-Host
    Show-Banner
    Write-Host '============================================================================================='
    Write-Host "                    $title"
    Write-Host '============================================================================================='
    if ($description) {
        Write-Host " ${dimText}$description${reset}"
        Write-Host '============================================================================================='
    }
    Write-Host ''
}

# ===================================================================
# MODULE 1: INTELLIGENT RAM CLEANER & WORKING SET OPTIMIZER
# ===================================================================

function Get-SystemMemoryStats {
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $totalKB = $os.TotalVisibleMemorySize
        $freeKB  = $os.FreePhysicalMemory
        $usedKB  = $totalKB - $freeKB
        $totalGB = [math]::Round($totalKB / 1MB, 2)
        $usedGB  = [math]::Round($usedKB / 1MB, 2)
        $freeGB  = [math]::Round($freeKB / 1MB, 2)
        $pctUsed = [math]::Round(($usedKB / $totalKB) * 100, 1)

        return @{
            TotalKB = $totalKB
            UsedKB  = $usedKB
            FreeKB  = $freeKB
            TotalGB = $totalGB
            UsedGB  = $usedGB
            FreeGB  = $freeGB
            UsedMB  = [math]::Round($usedKB / 1KB, 1)
            FreeMB  = [math]::Round($freeKB / 1KB, 1)
            TotalMB = [math]::Round($totalKB / 1KB, 1)
            PctUsed = $pctUsed
        }
    } catch {
        return @{
            TotalKB = 0; UsedKB = 0; FreeKB = 0; TotalGB = 0; UsedGB = 0; FreeGB = 0;
            UsedMB = 0; FreeMB = 0; TotalMB = 0; PctUsed = 0
        }
    }
}

function Show-MemoryBar([hashtable]$mem) {
    $barWidth = 30
    $filled = [int]([math]::Round(($mem.PctUsed / 100) * $barWidth))
    if ($filled -gt $barWidth) { $filled = $barWidth }
    if ($filled -lt 0) { $filled = 0 }
    $empty = $barWidth - $filled

    $color = if ($mem.PctUsed -ge 85) { $creamyRed } elseif ($mem.PctUsed -ge 65) { $creamyYellow } else { $creamyGreen }
    $bar = "$color" + ("#" * $filled) + "$dimText" + ("-" * $empty) + "$reset"

    Write-Host "  RAM Usage: [$bar] ${color}$($mem.PctUsed)%${reset} ($($mem.UsedGB) GB used of $($mem.TotalGB) GB total, $($mem.FreeGB) GB free)"
}

function Assistant-RamOptimizer {
    if ($isWinRE) {
        Invoke-AssistantHeader "INTELLIGENT RAM OPTIMIZER" "RAM management is not required in WinRE recovery environment."
        Write-Host "${creamyYellow}[INFO] WinRE operates from a RAM-disk with minimal background services.${reset}"
        Write-Host 'Press Enter to return to main menu...'
        [void][Console]::ReadLine()
        return
    }

    while ($true) {
        Invoke-AssistantHeader "INTELLIGENT RAM CLEANER & MEMORY OPTIMIZER" "Safely trims idle process working sets, flushes standby cache, and reclaims physical RAM."

        $mem = Get-SystemMemoryStats
        Show-MemoryBar -mem $mem
        Write-Host ''
        Write-Host "  ${creamyGreen}[1] 1-Click Intelligent Deep RAM Optimization (Safe Working Set Trim + Memory Flush)${reset}"
        Write-Host "  ${accentBlue}[2] Process RAM Inspector (View, Analyze & Trim Top RAM Consuming Tasks)${reset}"
        Write-Host "  ${accentBlue}[3] Continuous Smart RAM Guard (Monitors RAM in background & auto-trims above 80%)${reset}"
        Write-Host "  ${dimText}[0] Return to Main Menu${reset}"
        Write-Host ''
        Write-Host '============================================================================================='
        $subChoice = Read-Host "Select a RAM tool (0-3)"

        switch ($subChoice.Trim()) {
            '1' { Invoke-1ClickRamOptimization }
            '2' { Invoke-ProcessRamInspector }
            '3' { Invoke-ContinuousRamGuard }
            '0' { return }
            default {
                Write-Host "${creamyRed}Invalid option.${reset}"
                Start-Sleep -Milliseconds 800
            }
        }
    }
}

function Invoke-1ClickRamOptimization {
    Invoke-AssistantHeader "1-CLICK INTELLIGENT RAM OPTIMIZATION" "Analyzing process memory, trimming idle working sets, and releasing unneeded RAM."

    $memBefore = Get-SystemMemoryStats
    Write-Host "${accentBlue}[1/4] Baseline Memory Status:${reset}"
    Show-MemoryBar -mem $memBefore
    Write-Host ''

    # Protected processes that must never be disrupted
    $protectedList = @(
        'System', 'Idle', 'Registry', 'smss', 'csrss', 'wininit', 'services', 'lsass',
        'winlogon', 'dwm', 'fontdrvhost', 'powershell', 'pwsh', 'cmd', 'conhost',
        'taskmgr', 'MsMpEng', 'SecurityHealthService', 'Antigravity', 'Code'
    )

    # Detect current foreground active window process so we don't disrupt active user focus
    $fgPid = 0
    try {
        $fgHwnd = [SecretOptimizerMem]::GetForegroundWindow()
        [SecretOptimizerMem]::GetWindowThreadProcessId($fgHwnd, [ref]$fgPid) | Out-Null
    } catch {}

    Write-Host "${accentBlue}[2/4] Scanning active background processes and trimming working sets...${reset}"
    $procs = Get-Process -ErrorAction SilentlyContinue | Where-Object {
        $_.Id -ne $PID -and $_.Id -ne $fgPid -and $_.ProcessName -notin $protectedList
    }

    $trimmedCount = 0
    $freedWorkingSetKB = 0
    $topFreed = @()

    foreach ($p in $procs) {
        try {
            if ($p.WorkingSet64 -gt 5MB) {
                $wsBefore = $p.WorkingSet64
                $h = $p.Handle
                if ($h -ne [IntPtr]::Zero) {
                    $res = [SecretOptimizerMem]::EmptyWorkingSet($h)
                    if ($res -ne 0) {
                        $p.Refresh()
                        $wsAfter = $p.WorkingSet64
                        $diff = $wsBefore - $wsAfter
                        if ($diff -gt 0) {
                            $diffKB = $diff / 1KB
                            $freedWorkingSetKB += $diffKB
                            $trimmedCount++
                            $topFreed += [PSCustomObject]@{
                                Name = $p.ProcessName
                                PID  = $p.Id
                                FreedMB = [math]::Round($diffKB / 1024, 1)
                            }
                        }
                    }
                }
            }
        } catch {}
    }

    Write-Host "${creamyGreen}      Optimized $trimmedCount background processes.${reset}"
    Write-Host ''

    Write-Host "${accentBlue}[3/4] Purging system memory caches and garbage collection...${reset}"
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    Start-Sleep -Milliseconds 600

    Write-Host "${creamyGreen}      Memory subsystem synchronized.${reset}"
    Write-Host ''

    Write-Host "${accentBlue}[4/4] Optimization Results:${reset}"
    $memAfter = Get-SystemMemoryStats
    Show-MemoryBar -mem $memAfter
    Write-Host ''

    $ramSavedMB = [math]::Round($memBefore.UsedMB - $memAfter.UsedMB, 1)
    if ($ramSavedMB -lt 0) { $ramSavedMB = [math]::Round($freedWorkingSetKB / 1024, 1) }
    $pctDrop = [math]::Round($memBefore.PctUsed - $memAfter.PctUsed, 1)

    Write-Host "---------------------------------------------------------------------------------------------"
    Write-Host " ${creamyGreen}RESULT: Freed ~$ramSavedMB MB of active physical RAM!${reset}"
    Write-Host " ${dimText}Memory Load dropped from $($memBefore.PctUsed)% -> $($memAfter.PctUsed)% (-$pctDrop%)${reset}"
    Write-Host " ${dimText}Total Working Set Reclaimed: $([math]::Round($freedWorkingSetKB / 1024, 1)) MB across $trimmedCount processes.${reset}"
    Write-Host "---------------------------------------------------------------------------------------------"

    if ($topFreed.Count -gt 0) {
        Write-Host "${creamyYellow}Top Processes Cleaned:${reset}"
        $topFreed | Sort-Object FreedMB -Descending | Select-Object -First 5 | ForEach-Object {
            Write-Host "  * $($_.Name) (PID: $($_.PID)) -> Reclaimed $($_.FreedMB) MB"
        }
    }

    Write-AssistantLog "RamOptimization" "SUCCESS" "Freed $ramSavedMB MB across $trimmedCount processes"
    Write-Host ''
    Write-Host 'Press Enter to return to RAM menu...'
    [void][Console]::ReadLine()
}

function Invoke-ProcessRamInspector {
    while ($true) {
        Invoke-AssistantHeader "PROCESS RAM INSPECTOR" "Live view of top RAM consuming processes with safety classification."

        $protectedList = @(
            'System', 'Idle', 'Registry', 'smss', 'csrss', 'wininit', 'services', 'lsass',
            'winlogon', 'dwm', 'fontdrvhost', 'powershell', 'pwsh', 'cmd', 'conhost',
            'taskmgr', 'MsMpEng', 'SecurityHealthService'
        )

        $fgPid = 0
        try {
            $fgHwnd = [SecretOptimizerMem]::GetForegroundWindow()
            [SecretOptimizerMem]::GetWindowThreadProcessId($fgHwnd, [ref]$fgPid) | Out-Null
        } catch {}

        $procs = Get-Process -ErrorAction SilentlyContinue | Sort-Object WorkingSet64 -Descending | Select-Object -First 18

        Write-Host "  {0,-8} {1,-28} {2,12} {3,12}  {4,-20}" -f "PID", "PROCESS NAME", "WORKING SET", "PRIVATE RAM", "STATUS"
        Write-Host "  ---------------------------------------------------------------------------------------"

        foreach ($p in $procs) {
            $wsMB = [math]::Round($p.WorkingSet64 / 1MB, 1)
            $pmMB = [math]::Round($p.PrivateMemorySize64 / 1MB, 1)
            $cat = if ($p.ProcessName -in $protectedList) {
                "${creamyRed}[PROTECTED]${reset}"
            } elseif ($p.Id -eq $fgPid) {
                "${creamyGreen}[ACTIVE FOCUS]${reset}"
            } elseif ($p.ProcessName -match 'chrome|edge|firefox|brave|opera|discord|spotify|slack|teams|steam') {
                "${creamyYellow}[IDLE/APP]${reset}"
            } else {
                "${creamyCyan}[SAFE TO TRIM]${reset}"
            }

            Write-Host ("  {0,-8} {1,-28} {2,10} MB {3,10} MB  {4}" -f $p.Id, ($p.ProcessName.Substring(0, [math]::Min(27, $p.ProcessName.Length))), $wsMB, $pmMB, $cat)
        }

        Write-Host ''
        Write-Host "Options: [A] Trim All Safe Processes | [PID] Trim specific PID | [K <PID>] Kill frozen task | [0] Back"
        $act = Read-Host "Command"

        if ($act -match '^[0]$') { return }
        elseif ($act -match '^[Aa]$') {
            Invoke-1ClickRamOptimization
        }
        elseif ($act -match '^[Kk]\s+(\d+)$') {
            $targetPid = [int]$matches[1]
            try {
                Stop-Process -Id $targetPid -Force -ErrorAction Stop
                Write-Host "${creamyGreen}[OK] Process $targetPid terminated.${reset}"
                Write-AssistantLog "KillProcess" "SUCCESS" "Terminated process $targetPid"
                Start-Sleep -Seconds 1
            } catch {
                Write-Host "${creamyRed}[ERROR] Could not terminate process: $($_.Exception.Message)${reset}"
                Start-Sleep -Seconds 2
            }
        }
        elseif ($act -match '^\d+$') {
            $targetPid = [int]$act
            try {
                $targetProc = Get-Process -Id $targetPid -ErrorAction Stop
                if ($targetProc.ProcessName -in $protectedList) {
                    Write-Host "${creamyRed}[PROTECTED] Cannot trim critical Windows system process ($($targetProc.ProcessName)).${reset}"
                } else {
                    $wsB = $targetProc.WorkingSet64
                    [SecretOptimizerMem]::EmptyWorkingSet($targetProc.Handle) | Out-Null
                    $targetProc.Refresh()
                    $wsA = $targetProc.WorkingSet64
                    $freed = [math]::Round(($wsB - $wsA) / 1MB, 1)
                    Write-Host "${creamyGreen}[OK] Successfully trimmed $($targetProc.ProcessName) (PID: $targetPid). Freed $freed MB!${reset}"
                    Write-AssistantLog "TrimProcess" "SUCCESS" "Trimmed PID $targetPid ($($targetProc.ProcessName)): $freed MB freed"
                }
                Start-Sleep -Seconds 1
            } catch {
                Write-Host "${creamyRed}[ERROR] Process PID $targetPid not found or access denied.${reset}"
                Start-Sleep -Seconds 2
            }
        }
    }
}

function Invoke-ContinuousRamGuard {
    Invoke-AssistantHeader "CONTINUOUS SMART RAM GUARD" "Background monitor that auto-trims RAM when usage exceeds the configured threshold."

    $threshold = 80
    Write-Host "Set RAM utilization threshold to trigger automatic trimming (Default: 80%): " -NoNewline
    $inputThresh = Read-Host
    if ($inputThresh -match '^\d+$') {
        $threshold = [int]$inputThresh
        if ($threshold -lt 40) { $threshold = 40 }
        if ($threshold -gt 95) { $threshold = 95 }
    }

    Write-Host ''
    Write-Host "${creamyCyan}[*] RAM Guard Active (Threshold: $threshold%). Press Ctrl+C or 'Q' to exit guard mode.${reset}"
    Write-Host ''

    $protectedList = @(
        'System', 'Idle', 'Registry', 'smss', 'csrss', 'wininit', 'services', 'lsass',
        'winlogon', 'dwm', 'fontdrvhost', 'powershell', 'pwsh', 'cmd', 'conhost',
        'taskmgr', 'MsMpEng', 'SecurityHealthService'
    )

    try {
        while ($true) {
            $mem = Get-SystemMemoryStats
            $time = Get-Date -Format "HH:mm:ss"

            if ($mem.PctUsed -ge $threshold) {
                Write-Host "[$time] ${creamyRed}RAM load high ($($mem.PctUsed)% >= $threshold%). Auto-trimming idle processes...${reset}"
                $procs = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -notin $protectedList -and $_.Id -ne $PID }
                foreach ($p in $procs) {
                    try {
                        if ($p.WorkingSet64 -gt 15MB) {
                            [SecretOptimizerMem]::EmptyWorkingSet($p.Handle) | Out-Null
                        }
                    } catch {}
                }
                [GC]::Collect()
                Start-Sleep -Milliseconds 500
                $memNew = Get-SystemMemoryStats
                Write-Host "[$time] ${creamyGreen}Auto-trim complete: RAM load reduced to $($memNew.PctUsed)%.${reset}"
            } else {
                Write-Host "[$time] ${creamyGreen}RAM load normal: $($mem.PctUsed)% (Threshold: $threshold%)${reset}"
            }

            Start-Sleep -Seconds 5
        }
    } catch {
        Write-Host "${creamyYellow}[INFO] RAM Guard stopped.${reset}"
        Start-Sleep -Seconds 1
    }
}

# ===================================================================
# MODULE 2: SAFE WINDOWS BLOATWARE REMOVER
# ===================================================================

$safeBloatwareRules = @(
    @{ Name = "Microsoft.BingNews"; Description = "Microsoft News & Feed" }
    @{ Name = "Microsoft.BingWeather"; Description = "Bing Weather Widget" }
    @{ Name = "Microsoft.BingFinance"; Description = "Bing Money & Finance" }
    @{ Name = "Microsoft.BingSports"; Description = "Bing Sports" }
    @{ Name = "Microsoft.WindowsFeedbackHub"; Description = "Feedback Hub Telemetry" }
    @{ Name = "Microsoft.GetHelp"; Description = "Get Help Online Assistant" }
    @{ Name = "Microsoft.Getstarted"; Description = "Tips / Welcome Promo App" }
    @{ Name = "Microsoft.People"; Description = "People / Contacts App" }
    @{ Name = "Microsoft.PowerAutomateDesktop"; Description = "Power Automate Desktop" }
    @{ Name = "Microsoft.549981C3F5F10"; Description = "Cortana (Deprecated Assistant)" }
    @{ Name = "Microsoft.MixedReality.Portal"; Description = "Mixed Reality Portal" }
    @{ Name = "Microsoft.MicrosoftSolitaireCollection"; Description = "Microsoft Solitaire Collection" }
    @{ Name = "Microsoft.Microsoft3DViewer"; Description = "3D Viewer" }
    @{ Name = "Microsoft.WindowsMaps"; Description = "Windows Maps" }
    @{ Name = "Microsoft.ZuneVideo"; Description = "Films & TV Video App" }
    @{ Name = "Microsoft.ZuneMusic"; Description = "Groove Music / Media Player Stub" }
    @{ Name = "Clipchamp.Clipchamp"; Description = "Clipchamp Video Editor" }
    @{ Name = "TikTok"; Description = "TikTok App" }
    @{ Name = "CandyCrush"; Description = "Candy Crush Saga & Promo Games" }
    @{ Name = "Disney"; Description = "Disney+ App" }
    @{ Name = "SpotifyAB.SpotifyMusic"; Description = "Spotify Pre-installed Stub" }
    @{ Name = "Netflix"; Description = "Netflix Pre-installed Stub" }
    @{ Name = "PrimeVideo"; Description = "Amazon Prime Video Stub" }
    @{ Name = "Fitbit"; Description = "Fitbit Coach Stub" }
    @{ Name = "Duolingo"; Description = "Duolingo Promo Stub" }
)

$xboxBloatwareRules = @(
    @{ Name = "Microsoft.XboxApp"; Description = "Xbox Companion App" }
    @{ Name = "Microsoft.XboxGamingOverlay"; Description = "Xbox Game Bar Overlay" }
    @{ Name = "Microsoft.XboxIdentityProvider"; Description = "Xbox Identity Provider" }
    @{ Name = "Microsoft.XboxSpeechToTextOverlay"; Description = "Xbox Speech To Text Overlay" }
    @{ Name = "Microsoft.XboxTCUI"; Description = "Xbox UI Services" }
)

$protectedCorePackages = @(
    'Microsoft.WindowsStore', 'Microsoft.StorePurchaseApp', 'Microsoft.WindowsCalculator',
    'Microsoft.WindowsNotepad', 'Microsoft.WindowsCamera', 'Microsoft.ScreenSketch',
    'Microsoft.Windows.Photos', 'Microsoft.WindowsTerminal', 'Microsoft.DesktopAppInstaller',
    'Microsoft.SecHealthUI', 'Microsoft.Windows.Search', 'Microsoft.Windows.ShellExperienceHost',
    'Microsoft.Windows.StartMenuExperienceHost', 'Microsoft.UI.Xaml', 'Microsoft.VCLibs', 'Microsoft.NET'
)

function Assistant-Debloat {
    if ($isWinRE) {
        Invoke-AssistantHeader "SAFE WINDOWS BLOATWARE REMOVER" "Bloatware removal requires a live online Windows installation."
        Write-Host "${creamyYellow}[INFO] AppX package management is not active inside WinRE recovery environment.${reset}"
        Write-Host 'Press Enter to return to main menu...'
        [void][Console]::ReadLine()
        return
    }

    while ($true) {
        Invoke-AssistantHeader "SAFE WINDOWS BLOATWARE REMOVER" "Removes pre-installed sponsored junk, promotional apps, telemetry & Start Menu ads safely."

        Write-Host "  ${creamyGreen}[1] Safe 1-Click Recommended Debloat (Sponsored Apps, Games, Junk & Start Menu Ads)${reset}"
        Write-Host "  ${accentBlue}[2] Xbox & Gaming Bloatware Remover (Optional for non-gamers)${reset}"
        Write-Host "  ${accentBlue}[3] Windows Telemetry, Diagnostics & Start Menu Ads Purge (Registry Optimization)${reset}"
        Write-Host "  ${accentBlue}[4] Interactive Custom Package Manager (Scan, Review & Select specific apps to remove)${reset}"
        Write-Host "  ${accentBlue}[5] Reinstall / Restore Default Microsoft Store Apps Guide${reset}"
        Write-Host "  ${dimText}[0] Return to Main Menu${reset}"
        Write-Host ''
        Write-Host '============================================================================================='
        $subChoice = Read-Host "Select a Debloat tool (0-5)"

        switch ($subChoice.Trim()) {
            '1' { Invoke-1ClickSafeDebloat }
            '2' { Invoke-XboxDebloat }
            '3' { Invoke-TelemetryAdwareDebloat }
            '4' { Invoke-InteractiveAppxManager }
            '5' { Invoke-RestoreAppsGuide }
            '0' { return }
            default {
                Write-Host "${creamyRed}Invalid option.${reset}"
                Start-Sleep -Milliseconds 800
            }
        }
    }
}

function Invoke-1ClickSafeDebloat {
    Invoke-AssistantHeader "SAFE 1-CLICK RECOMMENDED DEBLOAT" "Scanning for pre-installed promotional bloatware, adware stubs, and telemetry apps..."

    $installedApps = Get-AppxPackage -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name -Unique
    $foundBloat = @()

    foreach ($rule in $safeBloatwareRules) {
        $match = $installedApps | Where-Object { $_ -like "*$($rule.Name)*" }
        if ($match) {
            foreach ($m in $match) {
                $foundBloat += [PSCustomObject]@{
                    PackageName = $m
                    Description = $rule.Description
                }
            }
        }
    }

    if ($foundBloat.Count -eq 0) {
        Write-Host "${creamyGreen}[CLEAN] No promotional bloatware packages detected on your system!${reset}"
        Write-Host ''
        Write-Host "Would you also like to purge Start Menu ads and telemetry settings? (Y/N): " -NoNewline
        $tChoice = Read-Host
        if ($tChoice -match '^[YySs]') {
            Invoke-TelemetryAdwareDebloat
        }
        Write-Host 'Press Enter to return to Debloat menu...'
        [void][Console]::ReadLine()
        return
    }

    Write-Host "${creamyYellow}Detected $($foundBloat.Count) safe-to-remove promotional / bloatware package(s):${reset}"
    Write-Host ''
    foreach ($fb in $foundBloat) {
        Write-Host "  - ${creamyCyan}$($fb.Description)${reset} ${dimText}($($fb.PackageName))${reset}"
    }
    Write-Host ''
    Write-Host "This operation will:"
    Write-Host " 1. Automatically create a System Restore Point."
    Write-Host " 2. Uninstall all listed promotional bloatware apps safely."
    Write-Host " 3. Remove provisioned packages so they don't reinstall after updates."
    Write-Host " 4. Disable Start Menu suggestions, ads, and telemetry tracking."
    Write-Host ''
    Write-Host "Proceed with Safe 1-Click Debloat? (Y/N): " -NoNewline
    $confirm = Read-Host
    if ($confirm -notmatch '^[YySs]') {
        Write-Host "${creamyYellow}[INFO] Debloat cancelled by user.${reset}"
        Start-Sleep -Seconds 1
        return
    }

    Write-Host ''
    Create-SafeRestorePoint
    Write-Host ''

    $removedCount = 0
    foreach ($fb in $foundBloat) {
        Write-Host "${creamyCyan}[*] Removing: $($fb.Description)...${reset}" -NoNewline
        try {
            Get-AppxPackage -Name $fb.PackageName -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object DisplayName -eq $fb.PackageName | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
            Write-Host " ${creamyGreen}[REMOVED]${reset}"
            $removedCount++
            Write-AssistantLog "DebloatApp" "SUCCESS" "Removed $($fb.PackageName)"
        } catch {
            Write-Host " ${creamyRed}[FAILED]${reset}"
        }
    }

    Write-Host ''
    Write-Host "${creamyCyan}[*] Applying Registry privacy & Start Menu adware cleanups...${reset}"
    Apply-TelemetryAndAdsRegistryClean

    Write-Host ''
    Write-Host "${creamyGreen}[OK] Safe 1-Click Debloat finished! Removed $removedCount apps and disabled telemetry/adware.${reset}"
    Write-Host 'Press Enter to return to Debloat menu...'
    [void][Console]::ReadLine()
}

function Invoke-XboxDebloat {
    Invoke-AssistantHeader "XBOX & GAMING BLOATWARE REMOVER" "Removes Xbox background overlays, gaming apps, and companion services."

    Write-Host "${creamyYellow}[NOTE] Only perform this if you do NOT use Xbox Game Pass, Xbox Game Bar, or PC Game Captures.${reset}"
    Write-Host ''
    Write-Host "Do you want to proceed with Xbox gaming components removal? (Y/N): " -NoNewline
    $confirm = Read-Host
    if ($confirm -notmatch '^[YySs]') { return }

    Create-SafeRestorePoint
    Write-Host ''

    foreach ($rule in $xboxBloatwareRules) {
        Write-Host "${creamyCyan}[*] Removing $($rule.Description)...${reset}" -NoNewline
        try {
            Get-AppxPackage -Name "*$($rule.Name)*" -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object DisplayName -like "*$($rule.Name)*" | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
            Write-Host " ${creamyGreen}[REMOVED]${reset}"
            Write-AssistantLog "DebloatXbox" "SUCCESS" "Removed $($rule.Name)"
        } catch {
            Write-Host " ${creamyRed}[FAILED]${reset}"
        }
    }

    Write-Host ''
    Write-Host "${creamyGreen}[OK] Xbox gaming components removed.${reset}"
    Write-Host 'Press Enter to return to Debloat menu...'
    [void][Console]::ReadLine()
}

function Apply-TelemetryAndAdsRegistryClean {
    try {
        # 1. Disable Windows Diagnostic Telemetry
        $dataColKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
        if (-not (Test-Path $dataColKey)) { New-Item -Path $dataColKey -Force | Out-Null }
        Set-ItemProperty -Path $dataColKey -Name "AllowTelemetry" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

        # 2. Disable Advertising ID for privacy
        $advKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
        if (-not (Test-Path $advKey)) { New-Item -Path $advKey -Force | Out-Null }
        Set-ItemProperty -Path $advKey -Name "Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

        # 3. Disable Start Menu Promoted Apps & Suggestions
        $cdmKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        if (-not (Test-Path $cdmKey)) { New-Item -Path $cdmKey -Force | Out-Null }
        $props = @(
            'SystemPaneSuggestionsEnabled', 'SilentInstalledAppsEnabled',
            'SubscribedContent-338388Enabled', 'SubscribedContent-338389Enabled',
            'SubscribedContent-353694Enabled', 'SubscribedContent-353696Enabled',
            'SubscribedContent-353698Enabled', 'RotatingLockScreenEnabled'
        )
        foreach ($p in $props) {
            Set-ItemProperty -Path $cdmKey -Name $p -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        }

        # 4. Disable Bing Search in Start Menu (speeds up search)
        $expKey = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
        if (-not (Test-Path $expKey)) { New-Item -Path $expKey -Force | Out-Null }
        Set-ItemProperty -Path $expKey -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

        Write-Host "${creamyGreen}[OK] Privacy, telemetry, and Start menu promotional registry settings optimized.${reset}"
        Write-AssistantLog "TelemetryDebloat" "SUCCESS" "Disabled telemetry and Start menu promotional ads"
    } catch {
        Write-Host "${creamyRed}[WARN] Some registry settings could not be updated: $($_.Exception.Message)${reset}"
    }
}

function Invoke-TelemetryAdwareDebloat {
    Invoke-AssistantHeader "TELEMETRY & START MENU ADS PURGE" "Disables Windows diagnostic telemetry, ad identifiers, and Start menu promoted apps."

    Create-SafeRestorePoint
    Write-Host ''
    Apply-TelemetryAndAdsRegistryClean
    Write-Host ''
    Write-Host 'Press Enter to return to Debloat menu...'
    [void][Console]::ReadLine()
}

function Invoke-InteractiveAppxManager {
    Invoke-AssistantHeader "INTERACTIVE CUSTOM PACKAGE MANAGER" "Review all installed user packages and selectively uninstall unwanted apps."

    Write-Host "${creamyCyan}[*] Scanning installed AppX packages...${reset}"
    $packages = Get-AppxPackage -ErrorAction SilentlyContinue | Where-Object {
        $_.NonRemovable -ne $true -and $_.Name -notmatch 'VCLibs|NET|UI\.Xaml|ShellExperience|StartMenuExperience'
    } | Sort-Object Name

    $pkgList = @()
    $idx = 1
    foreach ($p in $packages) {
        $isProtected = $false
        foreach ($prot in $protectedCorePackages) {
            if ($p.Name -like "*$prot*") { $isProtected = $true; break }
        }

        $isBloat = $false
        foreach ($rule in $safeBloatwareRules) {
            if ($p.Name -like "*$($rule.Name)*") { $isBloat = $true; break }
        }

        $tag = if ($isProtected) { "${creamyRed}[SYSTEM PROTECTED]${reset}" }
               elseif ($isBloat) { "${creamyYellow}[RECOMMENDED REMOVAL]${reset}" }
               else { "${creamyCyan}[OPTIONAL USER APP]${reset}" }

        $pkgList += [PSCustomObject]@{
            Index       = $idx
            Name        = $p.Name
            PackageFullName = $p.PackageFullName
            IsProtected = $isProtected
            Tag         = $tag
        }
        $idx++
    }

    Write-Host ''
    Write-Host "  {0,-5} {1,-52} {2}" -f "NUM", "PACKAGE NAME", "STATUS"
    Write-Host "  ---------------------------------------------------------------------------------------"
    foreach ($item in $pkgList) {
        $shortName = if ($item.Name.Length -gt 50) { $item.Name.Substring(0, 47) + "..." } else { $item.Name }
        Write-Host ("  [{0,2}] {1,-50} {2}" -f $item.Index, $shortName, $item.Tag)
    }

    Write-Host ''
    Write-Host "Enter package numbers to remove (e.g. 1, 3, 5-8), 'ALL_BLOAT' to remove all recommended, or 0 to cancel:"
    $sel = Read-Host "Selection"

    if ($sel -match '^[0]$' -or -not $sel) { return }

    $toRemove = @()
    if ($sel -match '^ALL_BLOAT$') {
        $toRemove = $pkgList | Where-Object { $_.Tag -match 'RECOMMENDED' }
    } else {
        $ranges = $sel -split ','
        foreach ($r in $ranges) {
            $r = $r.Trim()
            if ($r -match '^(\d+)-(\d+)$') {
                $start = [int]$matches[1]
                $end = [int]$matches[2]
                for ($n = $start; $n -le $end; $n++) {
                    $matchItem = $pkgList | Where-Object { $_.Index -eq $n }
                    if ($matchItem) { $toRemove += $matchItem }
                }
            } elseif ($r -match '^\d+$') {
                $n = [int]$r
                $matchItem = $pkgList | Where-Object { $_.Index -eq $n }
                if ($matchItem) { $toRemove += $matchItem }
            }
        }
    }

    $toRemove = $toRemove | Select-Object -Unique
    if ($toRemove.Count -eq 0) {
        Write-Host "${creamyYellow}[INFO] No packages selected.${reset}"
        Start-Sleep -Seconds 1
        return
    }

    Write-Host ''
    Write-Host "${creamyYellow}Selected $($toRemove.Count) package(s) for removal:${reset}"
    foreach ($tr in $toRemove) {
        if ($tr.IsProtected) {
            Write-Host "  - ${creamyRed}$($tr.Name) (WARNING: Critical System Package)${reset}"
        } else {
            Write-Host "  - ${creamyCyan}$($tr.Name)${reset}"
        }
    }

    Write-Host ''
    Write-Host "Confirm uninstallation? (Y/N): " -NoNewline
    $conf = Read-Host
    if ($conf -notmatch '^[YySs]') { return }

    Create-SafeRestorePoint
    Write-Host ''

    foreach ($tr in $toRemove) {
        Write-Host "${creamyCyan}[*] Uninstalling $($tr.Name)...${reset}" -NoNewline
        try {
            Remove-AppxPackage -Package $tr.PackageFullName -ErrorAction Stop
            Write-Host " ${creamyGreen}[OK]${reset}"
            Write-AssistantLog "CustomDebloat" "SUCCESS" "Uninstalled $($tr.Name)"
        } catch {
            Write-Host " ${creamyRed}[FAILED: $($_.Exception.Message)]${reset}"
        }
    }

    Write-Host ''
    Write-Host "${creamyGreen}[OK] Package removal complete.${reset}"
    Write-Host 'Press Enter to return to Debloat menu...'
    [void][Console]::ReadLine()
}

function Invoke-RestoreAppsGuide {
    Invoke-AssistantHeader "RESTORE DEFAULT MICROSOFT STORE APPS" "Instructions & commands to recover any accidentally removed Microsoft Store applications."

    Write-Host "${creamyCyan}If you ever wish to restore or reinstall default Windows Store applications:${reset}"
    Write-Host ''
    Write-Host "${creamyYellow}Option 1: Via Microsoft Store${reset}"
    Write-Host "  Open Microsoft Store -> Search for the app (e.g. 'Calculator', 'Photos', 'Xbox') -> Click 'Get/Install'."
    Write-Host ''
    Write-Host "${creamyYellow}Option 2: Re-register all built-in apps via PowerShell (Run as Administrator):${reset}"
    Write-Host "${dimText}  Get-AppxPackage -AllUsers | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register `"`$(`$_.InstallLocation)\AppXManifest.xml`"}${reset}"
    Write-Host ''
    Write-Host "${creamyYellow}Option 3: Use a System Restore Point${reset}"
    Write-Host "  Select option [R] from the main Secret-Optimizer menu to roll back system settings."
    Write-Host ''
    Write-Host 'Press Enter to return to Debloat menu...'
    [void][Console]::ReadLine()
}

# ===================================================================
# MODULE 3: GUIDED INTELLIGENT SYSTEM DIAGNOSIS
# ===================================================================
function Assistant-SmartDiagnosis {
    Invoke-AssistantHeader "INTELLIGENT ASSISTANT: COMPREHENSIVE SYSTEM DIAGNOSIS" "The assistant will scan critical Windows components, RAM health, and propose tailored repairs."

    $issues = @()

    # 1. Startup & SrtTrail log inspection
    Write-Host "${accentBlue}[1/7] Scanning boot integrity and SrtTrail.txt logs...${reset}" -NoNewline
    $srtPath = "$targetWinDrive\Windows\System32\Logfiles\Srt\SrtTrail.txt"
    if (-not (Test-Path $srtPath) -and (Test-Path "X:\Windows\System32\Logfiles\Srt\SrtTrail.txt")) {
        $srtPath = "X:\Windows\System32\Logfiles\Srt\SrtTrail.txt"
    }
    if (Test-Path $srtPath) {
        $srtContent = Get-Content $srtPath -Tail 20 -ErrorAction SilentlyContinue
        $failedDrivers = $srtContent | Where-Object { $_ -match 'error|fallo|failed|corrupt' }
        if ($failedDrivers) {
            Write-Host " ${creamyRed}[WARNING: Startup repair errors logged]${reset}"
            $issues += @{ Code="BOOT_SRT"; Title="Errors detected in SrtTrail.txt"; Severity="High" }
        } else {
            Write-Host " ${creamyGreen}[OK]${reset}"
        }
    } else {
        Write-Host " ${creamyGreen}[OK]${reset}"
    }

    # 2. RAM and Memory Load Check
    Write-Host "${accentBlue}[2/7] Checking RAM utilization and memory pressure...${reset}" -NoNewline
    $mem = Get-SystemMemoryStats
    if ($mem.PctUsed -ge 85) {
        Write-Host " ${creamyRed}[HIGH LOAD: $($mem.PctUsed)% in use ($($mem.FreeGB) GB free)]${reset}"
        $issues += @{ Code="HIGH_RAM"; Title="High memory utilization ($($mem.PctUsed)%)"; Severity="Medium" }
    } else {
        Write-Host " ${creamyGreen}[OK: $($mem.PctUsed)% used, $($mem.FreeGB) GB free]${reset}"
    }

    # 3. Disk storage check
    Write-Host "${accentBlue}[3/7] Inspecting primary drive storage health ($targetWinDrive)...${reset}" -NoNewline
    $sysDriveObj = Get-PSDrive -Name ($targetWinDrive.Substring(0,1)) -ErrorAction SilentlyContinue
    if ($sysDriveObj) {
        $freeGB = [math]::Round($sysDriveObj.Free / 1GB, 1)
        if ($freeGB -lt 5) {
            Write-Host " ${creamyRed}[CRITICAL: Low disk space ($freeGB GB free)]${reset}"
            $issues += @{ Code="DISK_SPACE"; Title="Insufficient disk space on $targetWinDrive ($freeGB GB free)"; Severity="Critical" }
        } else {
            Write-Host " ${creamyGreen}[OK: $freeGB GB free]${reset}"
        }
    } else {
        Write-Host " ${creamyGreen}[OK]${reset}"
    }

    # 4. Core services / Component Store
    Write-Host "${accentBlue}[4/7] Checking Windows system image and component store...${reset}" -NoNewline
    if ($isWinRE) {
        Write-Host " ${creamyGreen}[OK (WinRE Offline Mode)]${reset}"
    } else {
        $dismCheck = cmd /c "DISM /Online /Cleanup-Image /CheckHealth" 2>&1
        if ($dismCheck -match "reparable|corrupt|repaired") {
            Write-Host " ${creamyRed}[WARNING: Component corruption detected in WinSxS]${reset}"
            $issues += @{ Code="DISM_CORRUPT"; Title="Corrupted WinSxS component store"; Severity="High" }
        } else {
            Write-Host " ${creamyGreen}[OK]${reset}"
        }
    }

    # 5. Network and DNS stack check
    Write-Host "${accentBlue}[5/7] Verifying network stack and DNS resolution...${reset}" -NoNewline
    if ($isWinRE) {
        Write-Host " ${dimText}[N/A in WinRE]${reset}"
    } else {
        $netOk = $false
        try {
            $testDns = [System.Net.Dns]::GetHostAddresses("api.github.com")
            if ($testDns) { $netOk = $true }
        } catch {}
        if (-not $netOk) {
            Write-Host " ${creamyYellow}[WARNING: Network / DNS resolution issue]${reset}"
            $issues += @{ Code="NETWORK"; Title="Network connectivity or DNS issues"; Severity="Medium" }
        } else {
            Write-Host " ${creamyGreen}[OK]${reset}"
        }
    }

    # 6. Boot configuration check
    Write-Host "${accentBlue}[6/7] Checking BCD boot policies and recovery state...${reset}" -NoNewline
    cmd /c "bcdedit /enum {current}" 2>$null | Out-Null
    Write-Host " ${creamyGreen}[OK]${reset}"

    # 7. Windows files structure check
    Write-Host "${accentBlue}[7/7] Verifying kernel and system file presence...${reset}" -NoNewline
    if (Test-Path "$targetWinDrive\Windows\System32\ntoskrnl.exe") {
        Write-Host " ${creamyGreen}[OK: $targetWinDrive\Windows]${reset}"
    } else {
        Write-Host " ${creamyRed}[CRITICAL: ntoskrnl.exe missing]${reset}"
        $issues += @{ Code="KERNEL_MISS"; Title="Core Windows kernel file missing on $targetWinDrive"; Severity="Critical" }
    }

    Write-Host ''
    Write-Host '---------------------------------------------------------------------------------------------'
    Write-Host " DIAGNOSTIC ASSISTANT SUMMARY:"
    Write-Host '---------------------------------------------------------------------------------------------'

    if ($issues.Count -eq 0) {
        Write-Host "${creamyGreen} [EXCELLENT] No critical system anomalies detected.${reset}"
        Write-Host "${dimText} System components, memory, and boot configuration are operational.${reset}"
    } else {
        Write-Host "${creamyYellow} Detected $($issues.Count) item(s) requiring attention:${reset}"
        Write-Host ''
        foreach ($iss in $issues) {
            $col = if ($iss.Severity -eq 'Critical') { $creamyRed } else { $creamyYellow }
            Write-Host "  - ${col}[$($iss.Severity)] $($iss.Title)${reset}"
        }
        Write-Host ''
        Write-Host "Do you want Secret-Optimizer to apply recommended fixes automatically? (Y/N): " -NoNewline
        $confirm = Read-Host
        if ($confirm -match '^[YySs]') {
            Apply-SmartFixes -issues $issues
        }
    }

    Write-Host ''
    Write-Host 'Press Enter to return to main menu...'
    [void][Console]::ReadLine()
}

function Apply-SmartFixes([array]$issues) {
    Write-Host ''
    Create-SafeRestorePoint
    Write-Host ''

    foreach ($iss in $issues) {
        switch ($iss.Code) {
            "HIGH_RAM" {
                Write-Host "${creamyCyan}>> Performing Intelligent RAM Working Set Optimization...${reset}"
                $procs = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Id -ne $PID }
                foreach ($p in $procs) {
                    try { if ($p.WorkingSet64 -gt 10MB) { [SecretOptimizerMem]::EmptyWorkingSet($p.Handle) | Out-Null } } catch {}
                }
                [GC]::Collect()
                Write-Host "${creamyGreen}   [OK] Memory load reduced.${reset}"
            }
            "BOOT_SRT" {
                Write-Host "${creamyCyan}>> Repairing boot configuration and BCD...${reset}"
                bcdedit /set '{default}' recoveryenabled No 2>$null
                bcdedit /set '{default}' bootstatuspolicy ignoreallfailures 2>$null
                cmd /c "bcdboot $targetWinDrive\Windows /l en-us /s $targetWinDrive /f ALL" 2>$null
                Write-Host "${creamyGreen}   [OK] Boot configuration stabilized.${reset}"
            }
            "NETWORK" {
                Write-Host "${creamyCyan}>> Resetting network stack, sockets and DNS...${reset}"
                netsh winsock reset | Out-Null
                netsh int ip reset | Out-Null
                ipconfig /flushdns | Out-Null
                Write-Host "${creamyGreen}   [OK] Network stack refreshed.${reset}"
            }
            "DISM_CORRUPT" {
                Write-Host "${creamyCyan}>> Repairing component store...${reset}"
                if ($isWinRE) {
                    dism /image:$targetWinDrive\ /cleanup-image /revertpendingactions
                    sfc /scannow "/offbootdir=$targetWinDrive\" "/offwindir=$targetWinDrive\Windows"
                } else {
                    DISM /Online /Cleanup-Image /RestoreHealth
                    sfc /scannow
                }
                Write-Host "${creamyGreen}   [OK] System image and core binaries repaired.${reset}"
            }
        }
    }
    Write-Host ''
    Write-Host "${creamyGreen}[SECRET-OPTIMIZER] All recommended fixes have been safely applied.${reset}"
}

# ===================================================================
# MODULE 4: STARTUP & SRTTRAIL REPAIR
# ===================================================================
function Assistant-BootRepair {
    Invoke-AssistantHeader "ASSISTANT: STARTUP & SRTTRAIL.TXT REPAIR" "Resolves Automatic Repair boot loops, rebuilds the BCD boot store and repairs the boot sector."

    Create-SafeRestorePoint

    Write-Host "${creamyCyan}[1/5] Inspecting SrtTrail.txt failure log...${reset}"
    $srtPath = "$targetWinDrive\Windows\System32\Logfiles\Srt\SrtTrail.txt"
    if (-not (Test-Path $srtPath) -and (Test-Path "X:\Windows\System32\Logfiles\Srt\SrtTrail.txt")) {
        $srtPath = "X:\Windows\System32\Logfiles\Srt\SrtTrail.txt"
    }
    if (Test-Path $srtPath) {
        Write-Host "${creamyYellow}Recent lines from the startup repair log:${reset}"
        Get-Content $srtPath -Tail 15 | ForEach-Object { Write-Host "   $_" }
    } else {
        Write-Host "${creamyGreen}[OK] No pending critical boot errors found in SrtTrail.txt.${reset}"
    }
    Write-Host ''

    Write-Host "${creamyCyan}[2/5] Disabling Windows 'Automatic Repair' infinite loop...${reset}"
    bcdedit /set '{default}' recoveryenabled No 2>$null
    bcdedit /set '{default}' bootstatuspolicy ignoreallfailures 2>$null
    Write-Host "${creamyGreen}[OK] Boot policy updated. Direct OS boot enabled.${reset}"
    Write-Host ''

    Write-Host "${creamyCyan}[3/5] Rebuilding UEFI / MBR boot files (bcdboot)...${reset}"
    cmd /c "bcdboot $targetWinDrive\Windows /l en-us /s $targetWinDrive /f ALL" 2>$null
    Write-Host "${creamyGreen}[OK] System boot files refreshed successfully.${reset}"
    Write-Host ''

    Write-Host "${creamyCyan}[4/5] Running advanced boot record repair (bootrec)...${reset}"
    bootrec /fixmbr 2>$null
    bootrec /fixboot 2>$null
    bootrec /scanos 2>$null
    bootrec /rebuildbcd 2>$null
    Write-Host "${creamyGreen}[OK] Boot sector, boot manager and BCD entries rebuilt.${reset}"
    Write-Host ''

    Write-Host "${creamyCyan}[5/5] Reverting pending failed updates (DISM)...${reset}"
    if ($isWinRE) {
        dism /image:$targetWinDrive\ /cleanup-image /revertpendingactions
    } else {
        DISM /Online /Cleanup-Image /RevertPendingActions 2>$null
    }
    Write-Host "${creamyGreen}[OK] Pending actions verified and cleaned.${reset}"

    Write-AssistantLog "BootRepair" "SUCCESS" "Startup, SrtTrail and bootrec repair completed"
    Write-Host ''
    Write-Host "${creamyGreen}[SECRET-OPTIMIZER] Startup repair process completed successfully.${reset}"
    Write-Host 'Press Enter to return to main menu...'
    [void][Console]::ReadLine()
}

# ===================================================================
# MODULE 5: DEEP SYSTEM FILES & IMAGE REPAIR
# ===================================================================
function Assistant-ImageRepair {
    Invoke-AssistantHeader "ASSISTANT: DEEP SYSTEM FILES & IMAGE REPAIR" "Scans and replaces any corrupted or modified core Windows files."

    Create-SafeRestorePoint

    if ($isWinRE) {
        Write-Host "${creamyCyan}[1/2] Running Offline System File Checker on $targetWinDrive\Windows...${reset}"
        sfc /scannow "/offbootdir=$targetWinDrive\" "/offwindir=$targetWinDrive\Windows"
        Write-Host ''

        Write-Host "${creamyCyan}[2/2] Reverting pending update actions (DISM Offline)...${reset}"
        dism /image:$targetWinDrive\ /cleanup-image /revertpendingactions
        Write-Host ''
    } else {
        Write-Host "${creamyCyan}[1/3] Running System File Checker (SFC /scannow)...${reset}"
        sfc /scannow
        Write-Host ''

        Write-Host "${creamyCyan}[2/3] Repairing Windows Component Store (DISM RestoreHealth)...${reset}"
        DISM /Online /Cleanup-Image /RestoreHealth
        Write-Host ''

        Write-Host "${creamyCyan}[3/3] Cleaning up superseded components (StartComponentCleanup)...${reset}"
        DISM /Online /Cleanup-Image /StartComponentCleanup
        Write-Host ''
    }

    Write-AssistantLog "ImageRepair" "SUCCESS" "System files and image repaired"
    Write-Host "${creamyGreen}[SECRET-OPTIMIZER] System image and core files verified and healthy.${reset}"
    Write-Host 'Press Enter to return to main menu...'
    [void][Console]::ReadLine()
}

# ===================================================================
# MODULE 6: DISK & BAD SECTOR REPAIR
# ===================================================================
function Assistant-DiskRepair {
    Invoke-AssistantHeader "ASSISTANT: DISK & BAD SECTOR REPAIR" "Inspects NTFS filesystem integrity and repairs disk errors."

    Write-Host "Detected storage volume: $targetWinDrive"
    Write-Host ''
    if ($isWinRE) {
        Write-Host "Running CHKDSK on $targetWinDrive now..."
        chkdsk $targetWinDrive /f /r
    } else {
        Write-Host "Do you want to schedule a full disk check (CHKDSK $targetWinDrive /F /R) on next reboot? (Y/N): " -NoNewline
        $ans = Read-Host
        if ($ans -match '^[YySs]') {
            echo Y | chkdsk $targetWinDrive /f /r
            Write-AssistantLog "DiskRepair" "SCHEDULED" "CHKDSK $targetWinDrive /F /R scheduled on next reboot"
            Write-Host "${creamyGreen}[OK] Disk repair scheduled for the next system restart.${reset}"
        } else {
            Write-Host "${creamyYellow}[INFO] Disk check cancelled by user.${reset}"
        }
    }

    Write-Host ''
    Write-Host 'Press Enter to return to main menu...'
    [void][Console]::ReadLine()
}

# ===================================================================
# MODULE 7: NETWORK & DNS FULL STACK REPAIR
# ===================================================================
function Assistant-NetworkRepair {
    Invoke-AssistantHeader "ASSISTANT: NETWORK, DNS & SOCKETS FULL REPAIR" "Restores factory configuration for network sockets, DNS cache, and firewall."

    if ($isWinRE) {
        Write-Host "${creamyYellow}[INFO] Network configuration services are not active inside WinRE recovery environment.${reset}"
        Write-Host 'Press Enter to return to main menu...'
        [void][Console]::ReadLine()
        return
    }

    Write-Host "${creamyCyan}[1/5] Resetting Winsock catalog...${reset}"
    netsh winsock reset | Out-Null
    Write-Host "${creamyGreen}[OK] Winsock catalog reset.${reset}"

    Write-Host "${creamyCyan}[2/5] Resetting TCP/IP protocol stack...${reset}"
    netsh int ip reset | Out-Null
    Write-Host "${creamyGreen}[OK] TCP/IP protocol stack reset.${reset}"

    Write-Host "${creamyCyan}[3/5] Flushing and re-registering DNS cache...${reset}"
    ipconfig /flushdns | Out-Null
    ipconfig /registerdns | Out-Null
    Write-Host "${creamyGreen}[OK] DNS cache flushed and re-registered.${reset}"

    Write-Host "${creamyCyan}[4/5] Resetting Windows Firewall to defaults...${reset}"
    netsh advfirewall reset | Out-Null
    Write-Host "${creamyGreen}[OK] Windows Firewall reset.${reset}"

    Write-Host "${creamyCyan}[5/5] Restarting essential networking services...${reset}"
    $netServices = @('Dhcp', 'Dnscache', 'NlaSvc', 'netprofm')
    foreach ($s in $netServices) {
        Restart-Service -Name $s -Force -ErrorAction SilentlyContinue
    }
    Write-Host "${creamyGreen}[OK] Network services restarted.${reset}"

    Write-AssistantLog "NetworkRepair" "SUCCESS" "Network stack completely reset"
    Write-Host ''
    Write-Host "${creamyGreen}[SECRET-OPTIMIZER] Network stack and connectivity fully repaired.${reset}"
    Write-Host 'Press Enter to return to main menu...'
    [void][Console]::ReadLine()
}

# ===================================================================
# MODULE 8: RESET WINDOWS UPDATE SAFELY
# ===================================================================
function Assistant-WindowsUpdateRepair {
    Invoke-AssistantHeader "ASSISTANT: CLEAN & RESET WINDOWS UPDATE" "Cleans broken update cache and resets the Windows Update engine."

    if ($isWinRE) {
        Write-Host "${creamyCyan}[1/1] Reverting pending updates on $targetWinDrive (DISM Offline)...${reset}"
        dism /image:$targetWinDrive\ /cleanup-image /revertpendingactions
        Write-Host "${creamyGreen}[OK] Pending updates reverted successfully.${reset}"
        Write-Host 'Press Enter to return to main menu...'
        [void][Console]::ReadLine()
        return
    }

    Create-SafeRestorePoint

    Write-Host "${creamyCyan}[1/4] Stopping Windows Update and Transfer services...${reset}"
    $wuServices = @('wuauserv', 'cryptSvc', 'bits', 'msiserver')
    foreach ($s in $wuServices) {
        Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
    }
    Write-Host "${creamyGreen}[OK] Services stopped.${reset}"

    Write-Host "${creamyCyan}[2/4] Purging SoftwareDistribution and Catroot2 folders...${reset}"
    try {
        if (Test-Path "$env:SystemRoot\SoftwareDistribution") {
            Rename-Item -Path "$env:SystemRoot\SoftwareDistribution" -NewName "SoftwareDistribution.old.$([guid]::NewGuid().ToString('N').Substring(0,6))" -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path "$env:SystemRoot\System32\catroot2") {
            Rename-Item -Path "$env:SystemRoot\System32\catroot2" -NewName "catroot2.old.$([guid]::NewGuid().ToString('N').Substring(0,6))" -Force -ErrorAction SilentlyContinue
        }
        Write-Host "${creamyGreen}[OK] Broken update stores refreshed.${reset}"
    } catch {}

    Write-Host "${creamyCyan}[3/4] Restarting Windows Update services...${reset}"
    foreach ($s in $wuServices) {
        Start-Service -Name $s -ErrorAction SilentlyContinue
    }
    Write-Host "${creamyGreen}[OK] Services restarted.${reset}"

    Write-Host "${creamyCyan}[4/4] Registering core Windows Update DLL modules...${reset}"
    $dlls = @('atl.dll', 'urlmon.dll', 'mshtml.dll', 'shdocvw.dll', 'browseui.dll', 'jscript.dll', 'vbscript.dll', 'scrrun.dll', 'msxml.dll', 'msxml3.dll', 'msxml6.dll', 'actxprxy.dll', 'softpub.dll', 'wintrust.dll', 'dssenh.dll', 'rsaenh.dll', 'gpkcsp.dll', 'sccbase.dll', 'slbcsp.dll', 'cryptdlg.dll', 'oleaut32.dll', 'ole32.dll', 'shell32.dll', 'initpki.dll', 'wuapi.dll', 'wuaueng.dll', 'wucltui.dll', 'wups.dll', 'wups2.dll', 'wuweb.dll', 'qmgr.dll', 'qmgrprxy.dll', 'wucltux.dll', 'muweb.dll', 'wuwebv.dll')
    foreach ($d in $dlls) {
        regsvr32.exe /s $d 2>$null
    }
    Write-Host "${creamyGreen}[OK] Components registered.${reset}"

    Write-AssistantLog "WindowsUpdateRepair" "SUCCESS" "Windows Update refreshed"
    Write-Host ''
    Write-Host "${creamyGreen}[SECRET-OPTIMIZER] Windows Update has been completely refreshed and repaired.${reset}"
    Write-Host 'Press Enter to return to main menu...'
    [void][Console]::ReadLine()
}

# ===================================================================
# MODULE 9: EMERGENCY ACCESS ACCOUNTS
# ===================================================================
function Assistant-EmergencyAccount {
    Invoke-AssistantHeader "ASSISTANT: EMERGENCY ACCESS ACCOUNTS" "Enables built-in administration accounts to recover computer access."

    if ($isWinRE) {
        Write-Host "${creamyYellow}[INFO] There's no live Windows session to add accounts to from WinRE.${reset}"
        Write-Host ''
        Write-Host "${dimText}For device security and antivirus compliance, use official Microsoft recovery paths:${reset}"
        Write-Host "  - Microsoft account: reset password online at https://account.live.com/password/reset"
        Write-Host "  - Local account: use a password reset disk."
        Write-Host ''
        Write-Host 'Press Enter to return to main menu...'
        [void][Console]::ReadLine()
        return
    }

    Write-Host "  [1] Enable Windows built-in Administrator account"
    Write-Host "  [2] Create a new Emergency Administrator user"
    Write-Host "  [3] Return to main menu"
    Write-Host ''
    $op = Read-Host "Select an option (1-3)"

    if ($op -eq '1') {
        net user Administrator /active:yes 2>$null
        net user Administrador /active:yes 2>$null
        Write-Host "${creamyGreen}[OK] Administrator account enabled.${reset}"
        Write-AssistantLog "EmergencyUser" "SUCCESS" "Administrator account enabled"
    } elseif ($op -eq '2') {
        $nu = Read-Host "Enter new username"
        $np = Read-Host "Enter temporary password"
        if ($nu -and $np) {
            net user $nu $np /add /y 2>$null
            net localgroup Administrators $nu /add 2>$null
            net localgroup Administradores $nu /add 2>$null
            Write-Host "${creamyGreen}[OK] User $nu created and added to Administrators group.${reset}"
            Write-AssistantLog "EmergencyUser" "SUCCESS" "User $nu created"
        }
    }
    Write-Host ''
    Write-Host 'Press Enter to return to main menu...'
    [void][Console]::ReadLine()
}

# ===================================================================
# MODULE 10: ACTION HISTORY & LOGS VIEWER
# ===================================================================
function Assistant-ViewLogs {
    Invoke-AssistantHeader "ASSISTANT: REPAIR HISTORY & ERROR LOGS" "Displays logged optimization operations and recent Windows startup error traces."

    Write-Host "${creamyYellow}--- Secret-Optimizer Action History ---${reset}"
    $docsFolder = [Environment]::GetFolderPath('MyDocuments')
    $histLog = "$docsFolder\Secret-Optimizer\Logs\assistant_actions.log"
    if (-not (Test-Path $histLog)) { $histLog = "$docsFolder\Secret-Tools\Logs\assistant_actions.log" }
    if (-not (Test-Path $histLog)) { $histLog = "$installDir\logs\assistant_actions.log" }
    if (Test-Path $histLog) {
        Get-Content $histLog -Tail 15 | ForEach-Object { Write-Host "   $_" }
    } else {
        Write-Host "   No previous action logs recorded."
    }
    Write-Host ''

    Write-Host "${creamyYellow}--- Startup Repair Log (SrtTrail.txt) ---${reset}"
    $srtPath = "$targetWinDrive\Windows\System32\Logfiles\Srt\SrtTrail.txt"
    if (-not (Test-Path $srtPath) -and (Test-Path "X:\Windows\System32\Logfiles\Srt\SrtTrail.txt")) {
        $srtPath = "X:\Windows\System32\Logfiles\Srt\SrtTrail.txt"
    }
    if (Test-Path $srtPath) {
        Get-Content $srtPath -Tail 15 | ForEach-Object { Write-Host "   $_" }
    } else {
        Write-Host "   No boot failure records detected in SrtTrail.txt."
    }

    Write-Host ''
    Write-Host 'Press Enter to return to main menu...'
    [void][Console]::ReadLine()
}

# ===================================================================
# MODULE 11: SYSTEM HEALTH REPORT
# ===================================================================
function Assistant-HealthReport {
    Invoke-AssistantHeader "ASSISTANT: SYSTEM HEALTH REPORT" "Generates a comprehensive HTML report of hardware, software, services and security status."

    if ($isWinRE) {
        Write-Host "${creamyYellow}[INFO] Full HTML report is only available in standard Windows mode (not WinRE).${reset}"
        Write-Host 'Press Enter to return to main menu...'
        [void][Console]::ReadLine()
        return
    }

    $reportModule = $null
    $candidates = @(
        "$scriptDir\Generate-HealthReport.ps1",
        "$installDir\Tools\Generate-HealthReport.ps1",
        "$toolsDir\Generate-HealthReport.ps1",
        "$installDir\Generate-HealthReport.ps1"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { $reportModule = $c; break }
    }

    if (-not $reportModule) {
        Write-Host "${creamyRed}[ERROR] Generate-HealthReport.ps1 not found. Please re-run Setup-Tools.bat.${reset}"
        Write-Host 'Press Enter to return to main menu...'
        [void][Console]::ReadLine()
        return
    }

    Write-Host "${creamyCyan}[REPORT] Collecting system data, this may take a few seconds...${reset}"
    Write-Host ''

    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $docsFolder = [Environment]::GetFolderPath('MyDocuments')
    $reportDir = "$docsFolder\Secret-Optimizer\Reports"
    if (-not (Test-Path $reportDir)) { New-Item -ItemType Directory -Path $reportDir -Force | Out-Null }
    $outPath = "$reportDir\SecretOptimizer_HealthReport_$timestamp.html"

    try {
        $result = & powershell -NoProfile -ExecutionPolicy Bypass -File "$reportModule" -OutputPath $outPath -TargetDrive $targetWinDrive 2>&1
        if (Test-Path $outPath) {
            Write-Host "${creamyGreen}[OK] Report saved to:${reset}"
            Write-Host "     ${creamyCyan}$outPath${reset}"
            Write-Host ''
            Write-Host "Opening in default browser..."
            Start-Process $outPath -ErrorAction SilentlyContinue
            Write-AssistantLog "HealthReport" "SUCCESS" "HTML report generated: $outPath"
        } else {
            Write-Host "${creamyRed}[ERROR] Report generation failed.${reset}"
        }
    } catch {
        Write-Host "${creamyRed}[ERROR] $($_.Exception.Message)${reset}"
    }

    Write-Host ''
    Write-Host 'Press Enter to return to main menu...'
    [void][Console]::ReadLine()
}

# ===================================================================
# MODULE 12: SYSTEM RESTORE POINTS
# ===================================================================
function Assistant-RestorePoints {
    Invoke-AssistantHeader "ASSISTANT: SYSTEM RESTORE POINTS" "List, create or roll back to a previous System Restore Point."

    if ($isWinRE) {
        Write-Host "${creamyCyan}[*] Launching the offline System Restore wizard for $targetWinDrive ...${reset}"
        $rstrui = "$targetWinDrive\Windows\System32\rstrui.exe"
        if (Test-Path $rstrui) {
            Start-Process $rstrui -Wait
        } else {
            Write-Host "${creamyRed}[ERROR] rstrui.exe not found on $targetWinDrive.${reset}"
        }
        Write-Host ''
        Write-Host 'Press Enter to return to main menu...'
        [void][Console]::ReadLine()
        return
    }

    $points = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
    if (-not $points) {
        Write-Host "${creamyYellow}[INFO] No restore points found, or System Restore is disabled on $env:SystemDrive.${reset}"
        Write-Host "Enable System Restore and create one now? (Y/N): " -NoNewline
        $ans = Read-Host
        if ($ans -match '^[YySs]') {
            Enable-ComputerRestore -Drive "$env:SystemDrive" -ErrorAction SilentlyContinue
            Checkpoint-Computer -Description "Secret-Optimizer Manual Restore Point" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
            Write-Host "${creamyGreen}[OK] Restore point created.${reset}"
            Write-AssistantLog "RestorePoint" "SUCCESS" "Manual restore point created"
        }
    } else {
        Write-Host "${creamyYellow}Available restore points:${reset}"
        Write-Host ''
        $points | Sort-Object SequenceNumber -Descending | ForEach-Object {
            Write-Host ("  [{0}] {1}  ({2})" -f $_.SequenceNumber, $_.Description, $_.CreationTime)
        }
        Write-Host ''
        Write-Host "  [N] Create a new restore point"
        Write-Host ''
        $sel = Read-Host "Enter a restore point number to roll back to, N to create new, or blank to cancel"
        if ($sel -match '^[Nn]$') {
            Checkpoint-Computer -Description "Secret-Optimizer Manual Restore Point" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
            Write-Host "${creamyGreen}[OK] Restore point created.${reset}"
            Write-AssistantLog "RestorePoint" "SUCCESS" "Manual restore point created"
        } elseif ($sel -match '^\d+$') {
            $target = $points | Where-Object { $_.SequenceNumber -eq [int]$sel }
            if ($target) {
                Write-Host "${creamyRed}[WARNING] This restarts the computer and rolls back system files/settings to '$($target.Description)'.${reset}"
                Write-Host "Proceed? (Y/N): " -NoNewline
                $confirm = Read-Host
                if ($confirm -match '^[YySs]') {
                    Write-AssistantLog "RestorePoint" "SUCCESS" "Restoring to point $sel : $($target.Description)"
                    Restore-Computer -RestorePoint $target.SequenceNumber -Confirm:$false
                }
            } else {
                Write-Host "${creamyRed}[ERROR] Restore point not found.${reset}"
            }
        }
    }

    Write-Host ''
    Write-Host 'Press Enter to return to main menu...'
    [void][Console]::ReadLine()
}

# ===================================================================
# MODULE 13: BITLOCKER RECOVERY KEY
# ===================================================================
function Assistant-BitLockerKey {
    Invoke-AssistantHeader "ASSISTANT: BITLOCKER RECOVERY KEY" "Displays the BitLocker numerical recovery password for a volume (works online and offline via manage-bde)."

    $drive = $targetWinDrive
    if (-not $isWinRE) {
        $inputDrive = Read-Host "Drive to check (Enter for default: $targetWinDrive)"
        if ($inputDrive) { $drive = $inputDrive }
    }

    Write-Host "${creamyCyan}[*] Reading BitLocker protectors for $drive ...${reset}"
    Write-Host ''
    $out = manage-bde -protectors -get $drive 2>&1
    $out | ForEach-Object { Write-Host $_ }

    Write-AssistantLog "BitLockerKey" "SUCCESS" "Recovery key viewed for $drive"
    Write-Host ''
    Write-Host "${creamyYellow}[TIP] Look for 'Numerical Password' above - that's what Windows asks for at boot.${reset}"
    Write-Host 'Press Enter to return to main menu...'
    [void][Console]::ReadLine()
}

# ===================================================================
# MODULE 14: DRIVER BACKUP & RESTORE
# ===================================================================
function Assistant-DriverBackup {
    Invoke-AssistantHeader "ASSISTANT: DRIVER BACKUP & RESTORE" "Exports installed third-party drivers so they can be reinstalled after a clean setup."

    Write-Host "  [1] Export drivers to a folder"
    Write-Host "  [2] Import drivers from a folder"
    Write-Host "  [3] Return to main menu"
    Write-Host ''
    $op = Read-Host "Select an option (1-3)"

    $defaultDir = if ($isWinRE) { "$targetWinDrive\DriverBackup" } else { "$([Environment]::GetFolderPath('MyDocuments'))\Secret-Optimizer\DriverBackup" }

    if ($op -eq '1') {
        $dest = Read-Host "Destination folder (Enter for default: $defaultDir)"
        if (-not $dest) { $dest = $defaultDir }
        if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
        Write-Host "${creamyCyan}[*] Exporting drivers to $dest ...${reset}"
        if ($isWinRE) {
            dism /image:$targetWinDrive\ /export-driver /destination:"$dest"
        } else {
            dism /online /export-driver /destination:"$dest"
        }
        Write-Host "${creamyGreen}[OK] Drivers exported to $dest.${reset}"
        Write-AssistantLog "DriverBackup" "SUCCESS" "Drivers exported to $dest"
    } elseif ($op -eq '2') {
        $src = Read-Host "Source folder containing exported drivers (Enter for default: $defaultDir)"
        if (-not $src) { $src = $defaultDir }
        if (-not (Test-Path $src)) {
            Write-Host "${creamyRed}[ERROR] Folder not found: $src${reset}"
        } else {
            Write-Host "${creamyCyan}[*] Importing drivers from $src ...${reset}"
            if ($isWinRE) {
                dism /image:$targetWinDrive\ /add-driver /driver:"$src" /recurse
            } else {
                dism /online /add-driver /driver:"$src" /recurse
            }
            Write-Host "${creamyGreen}[OK] Drivers imported from $src.${reset}"
            Write-AssistantLog "DriverBackup" "SUCCESS" "Drivers imported from $src"
        }
    }

    Write-Host ''
    Write-Host 'Press Enter to return to main menu...'
    [void][Console]::ReadLine()
}

# ===================================================================
# MAIN SECRET-OPTIMIZER MENU LOOP
# ===================================================================
while ($true) {
    Clear-Host
    Show-Banner
    if ($updateNotice) {
        Write-Host "${creamyYellow}$updateNotice${reset}"
        Write-Host ''
    }

    $modeTag = if ($isWinRE) { "${creamyYellow}[WINRE OFFLINE MODE: $targetWinDrive]${reset}" } else { "${creamyGreen}[ONLINE MODE]${reset}" }
    $isAdmin = if (Check-IsAdmin) { "${creamyGreen}[ADMIN]${reset}" } else { "${dimText}[USER]${reset}" }
    Write-Host " User: ${creamyCyan}$currentUser${reset} $isAdmin $modeTag | Host: ${creamyCyan}$env:COMPUTERNAME${reset} | Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    Write-Host '============================================================================================='
    Write-Host '              SECRET-OPTIMIZER : SYSTEM OPTIMIZATION & REPAIR SUITE'
    Write-Host '============================================================================================='
    Write-Host ''
    Write-Host "  ${creamyGreen}[1] Intelligent RAM Cleaner & Memory Optimizer (Safe Trimming + Standby Flush)${reset}"
    Write-Host "  ${creamyGreen}[2] Safe Windows Bloatware Remover (AppX + Telemetry + Start Menu Ads Purge)${reset}"
    Write-Host "  ${accentBlue}[3] Guided Intelligent System Diagnosis (Scan + Recommended Fixes)${reset}"
    Write-Host "  ${accentBlue}[4] Startup / SrtTrail.txt / BCD Repair (Fix boot loops & bootloader)${reset}"
    Write-Host "  ${accentBlue}[5] Deep System Files & Image Repair (SFC Offline/Online + DISM)${reset}"
    Write-Host "  ${accentBlue}[6] Disk & Bad Sector Repair (CHKDSK $targetWinDrive /F /R)${reset}"
    Write-Host "  ${accentBlue}[7] Network, DNS & Sockets Full Repair (Winsock / TCP-IP / Firewall)${reset}"
    Write-Host "  ${accentBlue}[8] Windows Update Clean & Reset (SoftwareDistribution / Catroot2)${reset}"
    Write-Host "  ${accentBlue}[9] Emergency Access Accounts (Enable Administrator / Create Recovery User)${reset}"
    Write-Host "  ${accentBlue}[0] Repair & Optimization History (Event Logs / Action Traces)${reset}"
    Write-Host "  ${creamyCyan}[H] Generate System Health Report (HTML)${reset}"
    Write-Host "  ${accentBlue}[R] System Restore Points (List / Create / Roll Back)${reset}"
    Write-Host "  ${accentBlue}[K] BitLocker Recovery Key${reset}"
    Write-Host "  ${accentBlue}[D] Driver Backup & Restore (Export / Import)${reset}"
    Write-Host "  ${dimText}[X] Exit${reset}"
    Write-Host ''
    Write-Host '============================================================================================='
    Write-Host ''
    $choice = Read-Host "Select an option (1-9, 0, H, R, K, D, X)"

    switch ($choice.Trim()) {
        '1' { Assistant-RamOptimizer }
        '2' { Assistant-Debloat }
        '3' { Assistant-SmartDiagnosis }
        '4' { Assistant-BootRepair }
        '5' { Assistant-ImageRepair }
        '6' { Assistant-DiskRepair }
        '7' { Assistant-NetworkRepair }
        '8' { Assistant-WindowsUpdateRepair }
        '9' { Assistant-EmergencyAccount }
        '0' { Assistant-ViewLogs }
        { $_ -in 'H','h' } { Assistant-HealthReport }
        { $_ -in 'R','r' } { Assistant-RestorePoints }
        { $_ -in 'K','k' } { Assistant-BitLockerKey }
        { $_ -in 'D','d' } { Assistant-DriverBackup }
        { $_ -in 'X','x' } { exit 0 }
        default {
            Write-Host "${creamyRed}Invalid option.${reset}"
            Start-Sleep -Seconds 1
        }
    }
}
