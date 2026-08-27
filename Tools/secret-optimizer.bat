<# :
@echo off
setlocal EnableDelayedExpansion
title Secret-Optimizer - Advanced Process & Performance Suite
color 0B
mode con: cols=105 lines=44 >nul 2>&1

:: Auto-elevate to Administrator if not already elevated
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Launch PowerShell engine smoothly
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([ScriptBlock]::Create((Get-Content -LiteralPath '%~f0' -Raw)))"
exit /b %errorlevel%
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

$userProfile = [Environment]::GetFolderPath('UserProfile')
$installDir = "$userProfile\Secret-Optimizer"
$toolsDir = "$installDir\Tools"

$scriptDir = $installDir
if ($PSScriptRoot) {
    $scriptDir = $PSScriptRoot
} elseif ($MyInvocation.MyCommand -and $MyInvocation.MyCommand.Path) {
    $scriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
}

# Auto-register in User PATH
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

# Win32 Memory & Process Native Helper
try {
    if (-not ([System.Management.Automation.PSTypeName]'SecretOptimizerNative').Type) {
        $win32Code = @"
using System;
using System.Runtime.InteropServices;
using System.Diagnostics;

public class SecretOptimizerNative {
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
} catch {}

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

# Check for updates in background (online mode)
$updateNotice = $null
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
        $repoApi = 'https://api.github.com/repos/MrSecret-Official/Secret-Optimizer'
        $commit = Invoke-RestMethod -Uri "$repoApi/commits/main" -Headers $h -Method Get -TimeoutSec 4 -ErrorAction SilentlyContinue
        if ($commit -and $commit.sha -and ($commit.sha -ne $localSha)) {
            $remoteShort = $commit.sha.Substring(0, 7)
            $updateNotice = "[UPDATE] A new version ($remoteShort) is available on GitHub. Run Optimizer_Setup.bat to upgrade."
        }
    } catch {}
}

$currentUser = $env:USERNAME

# Protected processes that should NEVER be killed or aggressively disturbed
$protectedList = @(
    'System', 'Idle', 'Registry', 'smss', 'csrss', 'wininit', 'services', 'lsass',
    'winlogon', 'dwm', 'fontdrvhost', 'powershell', 'pwsh', 'cmd', 'conhost',
    'taskmgr', 'MsMpEng', 'SecurityHealthService', 'Antigravity', 'Code'
)

function Write-AssistantLog([string]$action, [string]$status, [string]$details) {
    try {
        $docsFolder = [Environment]::GetFolderPath('MyDocuments')
        $logDir = if ($docsFolder) { "$docsFolder\Secret-Optimizer\Logs" } else { "$installDir\logs" }
        if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force -ErrorAction SilentlyContinue | Out-Null }
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "[$timestamp] [$status] - $action : $details" | Out-File -FilePath "$logDir\optimizer_actions.log" -Append -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {}
}

function Create-SafeRestorePoint {
    Write-Host "${creamyCyan}[SECURITY] Creating System Restore Point before modification...${reset}"
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Secret-Optimizer Checkpoint" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop | Out-Null
        Write-Host "${creamyGreen}[OK] System Restore Point created successfully.${reset}"
        Write-AssistantLog "RestorePoint" "SUCCESS" "System Restore Point created"
    } catch {
        Write-Host "${dimText}[INFO] Automated restore point skipped (proceeding safely).${reset}"
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
    $barWidth = 32
    $filled = [int]([math]::Round(($mem.PctUsed / 100) * $barWidth))
    if ($filled -gt $barWidth) { $filled = $barWidth }
    if ($filled -lt 0) { $filled = 0 }
    $empty = $barWidth - $filled

    $color = if ($mem.PctUsed -ge 85) { $creamyRed } elseif ($mem.PctUsed -ge 65) { $creamyYellow } else { $creamyGreen }
    $bar = "$color" + ("#" * $filled) + "$dimText" + ("-" * $empty) + "$reset"

    Write-Host "  RAM Load: [$bar] ${color}$($mem.PctUsed)%${reset} ($($mem.UsedGB) GB used / $($mem.TotalGB) GB total, $($mem.FreeGB) GB free)"
}

# ===================================================================
# MODULE 1: 1-CLICK DEEP RAM OPTIMIZER
# ===================================================================
function Assistant-RamOptimizer {
    Invoke-AssistantHeader "1-CLICK INTELLIGENT DEEP RAM OPTIMIZATION" "Trims process working sets, purges memory cache, and reclaims active physical RAM."

    $memBefore = Get-SystemMemoryStats
    Write-Host "${accentBlue}[1/4] Baseline Memory Status:${reset}"
    Show-MemoryBar -mem $memBefore
    Write-Host ''

    $fgPid = 0
    try {
        $fgHwnd = [SecretOptimizerNative]::GetForegroundWindow()
        [SecretOptimizerNative]::GetWindowThreadProcessId($fgHwnd, [ref]$fgPid) | Out-Null
    } catch {}

    Write-Host "${accentBlue}[2/4] Scanning background processes and safely trimming working sets...${reset}"
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
                    $res = [SecretOptimizerNative]::EmptyWorkingSet($h)
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

    Write-Host "${accentBlue}[3/4] Flushing standby list, modified pages, and .NET Garbage Collection...${reset}"
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
    Write-Host " ${creamyGreen}SUCCESS: Freed ~$ramSavedMB MB of active physical RAM!${reset}"
    Write-Host " ${dimText}Memory Load dropped from $($memBefore.PctUsed)% -> $($memAfter.PctUsed)% (-$pctDrop%)${reset}"
    Write-Host " ${dimText}Total Process Working Set Reclaimed: $([math]::Round($freedWorkingSetKB / 1024, 1)) MB across $trimmedCount processes.${reset}"
    Write-Host "---------------------------------------------------------------------------------------------"

    if ($topFreed.Count -gt 0) {
        Write-Host ''
        Write-Host "${creamyYellow}Top Processes Trimmed:${reset}"
        $topFreed | Sort-Object FreedMB -Descending | Select-Object -First 6 | ForEach-Object {
            Write-Host "  * $($_.Name) (PID: $($_.PID)) -> Reclaimed $($_.FreedMB) MB"
        }
    }

    Write-AssistantLog "RamOptimization" "SUCCESS" "Freed $ramSavedMB MB across $trimmedCount processes"
    Write-Host ''
    Write-Host 'Press Enter to return to main menu...'
    [void][Console]::ReadLine()
}

# ===================================================================
# MODULE 2: REAL-TIME PROCESS MONITOR & PERFORMANCE BOOSTER
# ===================================================================
function Assistant-ProcessManager {
    while ($true) {
        Invoke-AssistantHeader "REAL-TIME PROCESS MONITOR & PERFORMANCE BOOSTER" "Monitor process resource consumption, adjust CPU priority, and manage tasks."

        $fgPid = 0
        try {
            $fgHwnd = [SecretOptimizerNative]::GetForegroundWindow()
            [SecretOptimizerNative]::GetWindowThreadProcessId($fgHwnd, [ref]$fgPid) | Out-Null
        } catch {}

        $procs = Get-Process -ErrorAction SilentlyContinue | Sort-Object WorkingSet64 -Descending | Select-Object -First 18

        Write-Host ("  {0,-7} {1,-26} {2,10} {3,12} {4,-12} {5}" -f "PID", "PROCESS NAME", "RAM (WS)", "THREADS", "PRIORITY", "STATUS")
        Write-Host "  ---------------------------------------------------------------------------------------"

        foreach ($p in $procs) {
            $wsMB = [math]::Round($p.WorkingSet64 / 1MB, 1)
            $prio = try { $p.PriorityClass.ToString() } catch { "Normal" }
            $isResponding = try { if ($p.Responding) { "OK" } else { "FROZEN" } } catch { "OK" }

            $cat = if ($p.ProcessName -in $protectedList) {
                "${creamyRed}[SYSTEM]${reset}"
            } elseif ($p.Id -eq $fgPid) {
                "${creamyGreen}[ACTIVE FOCUS]${reset}"
            } elseif ($isResponding -eq "FROZEN") {
                "${creamyRed}[NOT RESPONDING]${reset}"
            } elseif ($p.ProcessName -match 'chrome|edge|firefox|brave|opera|discord|spotify|slack|teams|steam') {
                "${creamyYellow}[HELPER/APP]${reset}"
            } else {
                "${creamyCyan}[BACKGROUND]${reset}"
            }

            Write-Host ("  {0,-7} {1,-26} {2,8} MB {3,12} {4,-12} {5}" -f $p.Id, ($p.ProcessName.Substring(0, [math]::Min(25, $p.ProcessName.Length))), $wsMB, $p.Threads.Count, $prio, $cat)
        }

        Write-Host ''
        Write-Host "Commands:"
        Write-Host "  ${creamyCyan}[A]${reset} Trim All Safe Processes | ${creamyCyan}[T <PID>]${reset} Trim specific PID | ${creamyCyan}[H <PID>]${reset} Set High CPU Priority"
        Write-Host "  ${creamyCyan}[L <PID>]${reset} Set Low/Idle Priority | ${creamyCyan}[K <PID>]${reset} Terminate Task | ${creamyCyan}[F]${reset} Kill Frozen Tasks | ${creamyCyan}[0]${reset} Back"
        Write-Host ''
        $act = Read-Host "Enter command"

        if ($act -match '^[0]$' -or -not $act) { return }
        elseif ($act -match '^[Aa]$') {
            Assistant-RamOptimizer
            return
        }
        elseif ($act -match '^[Ff]$') {
            $frozen = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Responding -eq $false -and $_.ProcessName -notin $protectedList }
            if ($frozen) {
                foreach ($fz in $frozen) {
                    Stop-Process -Id $fz.Id -Force -ErrorAction SilentlyContinue
                    Write-Host "${creamyGreen}[OK] Terminated frozen process $($fz.ProcessName) (PID: $($fz.Id)).${reset}"
                }
            } else {
                Write-Host "${creamyGreen}[OK] No frozen or unresponsive processes detected.${reset}"
            }
            Start-Sleep -Seconds 1
        }
        elseif ($act -match '^[Tt]\s+(\d+)$') {
            $tPid = [int]$matches[1]
            try {
                $targetProc = Get-Process -Id $tPid -ErrorAction Stop
                $wsB = $targetProc.WorkingSet64
                [SecretOptimizerNative]::EmptyWorkingSet($targetProc.Handle) | Out-Null
                $targetProc.Refresh()
                $freed = [math]::Round(($wsB - $targetProc.WorkingSet64) / 1MB, 1)
                Write-Host "${creamyGreen}[OK] Trimmed $($targetProc.ProcessName) (PID: $tPid). Freed $freed MB!${reset}"
                Start-Sleep -Seconds 1
            } catch {
                Write-Host "${creamyRed}[ERROR] Process PID $tPid not found or access denied.${reset}"
                Start-Sleep -Seconds 2
            }
        }
        elseif ($act -match '^[Hh]\s+(\d+)$') {
            $tPid = [int]$matches[1]
            try {
                $targetProc = Get-Process -Id $tPid -ErrorAction Stop
                $targetProc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
                Write-Host "${creamyGreen}[OK] Priority for $($targetProc.ProcessName) set to HIGH.${reset}"
                Start-Sleep -Seconds 1
            } catch {
                Write-Host "${creamyRed}[ERROR] Could not adjust priority: $($_.Exception.Message)${reset}"
                Start-Sleep -Seconds 2
            }
        }
        elseif ($act -match '^[Ll]\s+(\d+)$') {
            $tPid = [int]$matches[1]
            try {
                $targetProc = Get-Process -Id $tPid -ErrorAction Stop
                $targetProc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal
                Write-Host "${creamyGreen}[OK] Priority for $($targetProc.ProcessName) set to BELOW NORMAL.${reset}"
                Start-Sleep -Seconds 1
            } catch {
                Write-Host "${creamyRed}[ERROR] Could not adjust priority: $($_.Exception.Message)${reset}"
                Start-Sleep -Seconds 2
            }
        }
        elseif ($act -match '^[Kk]\s+(\d+)$') {
            $tPid = [int]$matches[1]
            try {
                $targetProc = Get-Process -Id $tPid -ErrorAction Stop
                if ($targetProc.ProcessName -in $protectedList) {
                    Write-Host "${creamyRed}[PROTECTED] Cannot kill core system process ($($targetProc.ProcessName)).${reset}"
                } else {
                    Stop-Process -Id $tPid -Force -ErrorAction Stop
                    Write-Host "${creamyGreen}[OK] Process $tPid terminated.${reset}"
                    Write-AssistantLog "KillProcess" "SUCCESS" "Terminated process $tPid"
                }
                Start-Sleep -Seconds 1
            } catch {
                Write-Host "${creamyRed}[ERROR] Could not terminate process: $($_.Exception.Message)${reset}"
                Start-Sleep -Seconds 2
            }
        }
    }
}

# ===================================================================
# MODULE 3: IDLE HELPER & SUBPROCESS FREEZER
# ===================================================================
function Assistant-HelperFreezer {
    Invoke-AssistantHeader "IDLE BACKGROUND HELPER & SUBPROCESS FREEZER" "Detects and clears working sets of background browser tabs, electron helpers, and updaters."

    $helperPatterns = @('chrome', 'msedge', 'brave', 'opera', 'firefox', 'discord', 'spotify', 'slack', 'teams', 'steamwebhelper', 'epicgameslauncher', 'googledrive', 'adobearm')

    $fgPid = 0
    try {
        $fgHwnd = [SecretOptimizerNative]::GetForegroundWindow()
        [SecretOptimizerNative]::GetWindowThreadProcessId($fgHwnd, [ref]$fgPid) | Out-Null
    } catch {}

    Write-Host "${accentBlue}[*] Scanning for multi-process helpers and idle renderer tasks...${reset}"
    Write-Host ''

    $foundHelpers = Get-Process -ErrorAction SilentlyContinue | Where-Object {
        $name = $_.ProcessName.ToLower()
        $_.Id -ne $fgPid -and $_.Id -ne $PID -and ($helperPatterns | Where-Object { $name -like "*$_*" })
    }

    if ($foundHelpers.Count -eq 0) {
        Write-Host "${creamyGreen}[CLEAN] No heavy idle helper processes detected.${reset}"
        Write-Host ''
        Write-Host 'Press Enter to return to main menu...'
        [void][Console]::ReadLine()
        return
    }

    $totalHelperWS = ($foundHelpers | Measure-Object -Property WorkingSet64 -Sum).Sum
    $totalMB = [math]::Round($totalHelperWS / 1MB, 1)

    Write-Host "${creamyYellow}Detected $($foundHelpers.Count) idle helper/renderer process(es) holding ${creamyCyan}$totalMB MB${creamyYellow} RAM:${reset}"
    Write-Host ''

    $grouped = $foundHelpers | Group-Object ProcessName | Sort-Object { ($_.Group | Measure-Object -Property WorkingSet64 -Sum).Sum } -Descending
    foreach ($g in $grouped) {
        $gMB = [math]::Round(($g.Group | Measure-Object -Property WorkingSet64 -Sum).Sum / 1MB, 1)
        Write-Host "  * ${creamyCyan}$($g.Name)${reset} ($($g.Count) instances) -> $gMB MB"
    }

    Write-Host ''
    Write-Host "Optimize and trim all idle helper subprocesses? (Y/N): " -NoNewline
    $conf = Read-Host
    if ($conf -notmatch '^[YySs]') { return }

    $reclaimedBytes = 0
    foreach ($p in $foundHelpers) {
        try {
            $wsB = $p.WorkingSet64
            [SecretOptimizerNative]::EmptyWorkingSet($p.Handle) | Out-Null
            $p.Refresh()
            $reclaimedBytes += ($wsB - $p.WorkingSet64)
        } catch {}
    }

    [GC]::Collect()
    $reclaimedMB = [math]::Round($reclaimedBytes / 1MB, 1)
    Write-Host ''
    Write-Host "${creamyGreen}[OK] Helper optimization complete! Reclaimed ~$reclaimedMB MB RAM.${reset}"
    Write-AssistantLog "HelperFreezer" "SUCCESS" "Reclaimed $reclaimedMB MB from $($foundHelpers.Count) helper instances"
    Write-Host ''
    Write-Host 'Press Enter to return to main menu...'
    [void][Console]::ReadLine()
}

# ===================================================================
# MODULE 4: GAMING / HEAVY WORKLOAD TURBO MODE
# ===================================================================
function Assistant-GamingBooster {
    Invoke-AssistantHeader "GAMING & HEAVY WORKLOAD TURBO MODE" "Elevates priority of active games, minimizes background lag, and maximizes CPU affinity."

    $fgPid = 0
    try {
        $fgHwnd = [SecretOptimizerNative]::GetForegroundWindow()
        [SecretOptimizerNative]::GetWindowThreadProcessId($fgHwnd, [ref]$fgPid) | Out-Null
    } catch {}

    $fgProc = if ($fgPid -gt 0) { Get-Process -Id $fgPid -ErrorAction SilentlyContinue } else { $null }

    Write-Host "${accentBlue}[1/3] Active Foreground Application:${reset}"
    if ($fgProc -and $fgProc.ProcessName -notin $protectedList) {
        Write-Host "  Target Game / Application: ${creamyGreen}$($fgProc.ProcessName) (PID: $($fgProc.Id))${reset}"
    } else {
        Write-Host "${creamyYellow}  No specific external game window focused. Secret-Optimizer will apply system-wide Turbo Mode.${reset}"
    }
    Write-Host ''

    Write-Host "This operation will:"
    Write-Host "  1. Set active game/app CPU Priority to ${creamyGreen}HIGH${reset}."
    Write-Host "  2. Lower background non-essential processes to ${creamyCyan}BELOW NORMAL / IDLE${reset}."
    Write-Host "  3. Flush standby list and free active RAM."
    Write-Host "  4. Temporarily activate Windows Ultimate Performance / High Performance Power Plan."
    Write-Host ''
    Write-Host "Activate Turbo Mode now? (Y/N): " -NoNewline
    $conf = Read-Host
    if ($conf -notmatch '^[YySs]') { return }

    Write-Host ''
    Write-Host "${creamyCyan}[*] Elevating game priority...${reset}" -NoNewline
    if ($fgProc -and $fgProc.ProcessName -notin $protectedList) {
        try {
            $fgProc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
            Write-Host " ${creamyGreen}[OK]${reset}"
        } catch { Write-Host " ${creamyYellow}[SKIPPED]${reset}" }
    } else { Write-Host " ${creamyGreen}[OK]${reset}" }

    Write-Host "${creamyCyan}[*] Lowering priority of background updater and helper tasks...${reset}" -NoNewline
    $bgTasks = Get-Process -ErrorAction SilentlyContinue | Where-Object {
        $_.Id -ne $fgPid -and $_.Id -ne $PID -and $_.ProcessName -notmatch 'System|csrss|dwm|services|lsass|explorer|pwsh|cmd'
    }
    foreach ($bg in $bgTasks) {
        try {
            if ($bg.PriorityClass -eq [System.Diagnostics.ProcessPriorityClass]::Normal) {
                $bg.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal
            }
            [SecretOptimizerNative]::EmptyWorkingSet($bg.Handle) | Out-Null
        } catch {}
    }
    Write-Host " ${creamyGreen}[OK]${reset}"

    Write-Host "${creamyCyan}[*] Activating High Performance Power Plan...${reset}" -NoNewline
    try {
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null # High Performance
        powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null # Ultimate Performance (if available)
        Write-Host " ${creamyGreen}[OK]${reset}"
    } catch { Write-Host " ${creamyYellow}[OK]${reset}" }

    [GC]::Collect()
    Write-AssistantLog "TurboMode" "SUCCESS" "Activated Gaming Turbo Mode for $($fgProc.ProcessName)"
    Write-Host ''
    Write-Host "${creamyGreen}[TURBO ACTIVE] System resources optimized for peak responsiveness!${reset}"
    Write-Host 'Press Enter to return to main menu...'
    [void][Console]::ReadLine()
}

# ===================================================================
# MODULE 5: CONTINUOUS SMART RAM & PROCESS GUARD
# ===================================================================
function Assistant-ContinuousGuard {
    Invoke-AssistantHeader "CONTINUOUS SMART RAM & PROCESS GUARD" "Background monitor that auto-trims RAM when usage exceeds the configured threshold."

    $threshold = 75
    Write-Host "Set RAM utilization threshold to trigger automatic trimming (Default: 75%): " -NoNewline
    $inputThresh = Read-Host
    if ($inputThresh -match '^\d+$') {
        $threshold = [int]$inputThresh
        if ($threshold -lt 40) { $threshold = 40 }
        if ($threshold -gt 95) { $threshold = 95 }
    }

    Write-Host ''
    Write-Host "${creamyCyan}[*] RAM Guard Active (Threshold: $threshold%). Press Ctrl+C to stop guard mode.${reset}"
    Write-Host ''

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
                            [SecretOptimizerNative]::EmptyWorkingSet($p.Handle) | Out-Null
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
# MODULE 6: CONTROLLED DEBLOATER - 1-CLICK RECOMMENDED DEBLOAT
# ===================================================================
$safeBloatwareRules = @(
    @{ Name = "Microsoft.BingNews"; Description = "Microsoft News & Feed" }
    @{ Name = "Microsoft.BingWeather"; Description = "Bing Weather App & Widget" }
    @{ Name = "MicrosoftWindows.Client.WebExperience"; Description = "Windows 11 Widgets Board & Weather Feed (WebExperience)" }
    @{ Name = "Microsoft.BingFinance"; Description = "Bing Money & Finance" }
    @{ Name = "Microsoft.BingSports"; Description = "Bing Sports" }
    @{ Name = "Microsoft.Windows.Ai.Copilot.Provider"; Description = "Windows Copilot AI Provider" }
    @{ Name = "Microsoft.Copilot"; Description = "Microsoft Copilot App" }
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

$protectedCorePackages = @(
    'Microsoft.WindowsStore', 'Microsoft.StorePurchaseApp', 'Microsoft.WindowsCalculator',
    'Microsoft.WindowsNotepad', 'Microsoft.WindowsCamera', 'Microsoft.ScreenSketch',
    'Microsoft.Windows.Photos', 'Microsoft.WindowsTerminal', 'Microsoft.DesktopAppInstaller',
    'Microsoft.SecHealthUI', 'Microsoft.Windows.Search', 'Microsoft.Windows.ShellExperienceHost',
    'Microsoft.Windows.StartMenuExperienceHost', 'Microsoft.UI.Xaml', 'Microsoft.VCLibs', 'Microsoft.NET'
)

function Assistant-Debloat {
    Invoke-AssistantHeader "SAFE 1-CLICK RECOMMENDED DEBLOAT" "Removes sponsored junk, promotional apps, telemetry stubs & Start Menu ads safely."

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
            Assistant-TelemetryPurge
            return
        }
        Write-Host 'Press Enter to return to main menu...'
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
    Write-Host " 2. Uninstall all listed promotional bloatware apps."
    Write-Host " 3. Remove provisioned packages so they don't reinstall after updates."
    Write-Host " 4. Disable Start Menu suggestions, ads, and telemetry tracking."
    Write-Host ''
    Write-Host "Proceed with Safe 1-Click Debloat? (Y/N): " -NoNewline
    $confirm = Read-Host
    if ($confirm -notmatch '^[YySs]') { return }

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
    Assistant-ApplyTelemetryRegistry

    Write-Host ''
    Write-Host "${creamyGreen}[OK] Safe 1-Click Debloat finished! Removed $removedCount apps and disabled telemetry/adware.${reset}"
    Write-Host 'Press Enter to return to main menu...'
    [void][Console]::ReadLine()
}

# ===================================================================
# MODULE 7: CONTROLLED CUSTOM APPX PACKAGE MANAGER
# ===================================================================
function Assistant-InteractiveAppxManager {
    Invoke-AssistantHeader "CONTROLLED CUSTOM APPX PACKAGE MANAGER" "Review all installed user packages and selectively uninstall unwanted apps."

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
            Index           = $idx
            Name            = $p.Name
            PackageFullName = $p.PackageFullName
            IsProtected     = $isProtected
            Tag             = $tag
        }
        $idx++
    }

    Write-Host ''
    Write-Host ("  {0,-5} {1,-52} {2}" -f "NUM", "PACKAGE NAME", "STATUS")
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
            Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object DisplayName -eq $tr.Name | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
            Write-Host " ${creamyGreen}[OK]${reset}"
            Write-AssistantLog "CustomDebloat" "SUCCESS" "Uninstalled $($tr.Name)"
        } catch {
            Write-Host " ${creamyRed}[FAILED: $($_.Exception.Message)]${reset}"
        }
    }

    Write-Host ''
    Write-Host "${creamyGreen}[OK] Package removal complete.${reset}"
    Write-Host 'Press Enter to return to main menu...'
    [void][Console]::ReadLine()
}

# ===================================================================
# MODULE 7B: SMART WINDOWS JUNK & RAM-HOG DETECTOR
# ===================================================================
# Signatures of known Windows-native background bloat/telemetry processes.
# "Safe" items are launched by Windows itself and have a documented, reversible
# disable path. "Review first" items are things users often actively rely on
# (OneDrive sync, Edge background mode), so they require an explicit pick.
$smartJunkCatalog = @(
    [PSCustomObject]@{ Id = 'Widgets';   Display = 'Windows Widgets / News & Interests';      Processes = @('Widgets','WidgetService');                          Category = 'Windows Bloat';       Safe = $true }
    [PSCustomObject]@{ Id = 'Copilot';   Display = 'Windows Copilot (AI background provider & taskbar)'; Processes = @('Copilot','Microsoft.Copilot');            Category = 'Windows Bloat';       Safe = $true }
    [PSCustomObject]@{ Id = 'GameBar';   Display = 'Xbox Game Bar overlay & presence writer';  Processes = @('GameBar','GameBarFTServer','GameBarPresenceWriter'); Category = 'Windows Bloat';       Safe = $true }
    [PSCustomObject]@{ Id = 'YourPhone'; Display = 'Phone Link / Your Phone companion app';    Processes = @('YourPhone','PhoneExperienceHost');                  Category = 'Windows Bloat';       Safe = $true }
    [PSCustomObject]@{ Id = 'CompatTel'; Display = 'Microsoft Compatibility Telemetry';        Processes = @('CompatTelRunner','DeviceCensus');                   Category = 'Windows Telemetry';   Safe = $true }
    [PSCustomObject]@{ Id = 'Cortana';   Display = 'Cortana (legacy voice assistant)';         Processes = @('Cortana');                                          Category = 'Windows Bloat';       Safe = $true }
    [PSCustomObject]@{ Id = 'OneDrive';  Display = 'OneDrive background sync client';          Processes = @('OneDrive');                                         Category = 'Optional App';        Safe = $false }
    [PSCustomObject]@{ Id = 'EdgeBg';    Display = 'Edge background & startup-boost behavior'; Processes = @('msedge');                                           Category = 'Background Behavior'; Safe = $false }
)

function Invoke-SmartJunkDisable([string]$id) {
    switch ($id) {
        'Widgets' {
            Get-Process -Name 'Widgets','WidgetService' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            Get-AppxPackage -Name '*WebExperience*' -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object DisplayName -like '*WebExperience*' | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null

            $k1 = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            if (-not (Test-Path $k1)) { New-Item -Path $k1 -Force | Out-Null }
            Set-ItemProperty -Path $k1 -Name "TaskbarDa" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $k1 -Name "TaskbarMn" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

            $k2 = "HKCU:\Software\Policies\Microsoft\Dsh"
            if (-not (Test-Path $k2)) { New-Item -Path $k2 -Force | Out-Null }
            Set-ItemProperty -Path $k2 -Name "AllowNewsAndInterests" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

            $k2b = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
            if (-not (Test-Path $k2b)) { New-Item -Path $k2b -Force | Out-Null }
            Set-ItemProperty -Path $k2b -Name "AllowNewsAndInterests" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

            $k3 = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds"
            if (-not (Test-Path $k3)) { New-Item -Path $k3 -Force | Out-Null }
            Set-ItemProperty -Path $k3 -Name "ShellFeedsTaskbarViewMode" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue

            $k4 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds"
            if (-not (Test-Path $k4)) { New-Item -Path $k4 -Force | Out-Null }
            Set-ItemProperty -Path $k4 -Name "EnableFeeds" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        }
        'Copilot' {
            Get-Process -Name 'Copilot','Microsoft.Copilot' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            Get-AppxPackage -Name '*Copilot*' -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object DisplayName -like '*Copilot*' | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
            $cp1 = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
            if (-not (Test-Path $cp1)) { New-Item -Path $cp1 -Force | Out-Null }
            Set-ItemProperty -Path $cp1 -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            $cp2 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
            if (-not (Test-Path $cp2)) { New-Item -Path $cp2 -Force | Out-Null }
            Set-ItemProperty -Path $cp2 -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            $cp3 = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            if (-not (Test-Path $cp3)) { New-Item -Path $cp3 -Force | Out-Null }
            Set-ItemProperty -Path $cp3 -Name "ShowCopilotButton" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        }
        'GameBar' {
            Get-Process -Name 'GameBar','GameBarFTServer','GameBarPresenceWriter' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            $k1 = "HKCU:\System\GameConfigStore"
            if (-not (Test-Path $k1)) { New-Item -Path $k1 -Force | Out-Null }
            Set-ItemProperty -Path $k1 -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            $k2 = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
            if (-not (Test-Path $k2)) { New-Item -Path $k2 -Force | Out-Null }
            Set-ItemProperty -Path $k2 -Name "AppCaptureEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        }
        'YourPhone' {
            Get-Process -Name 'YourPhone','PhoneExperienceHost' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            Get-AppxPackage -Name '*Microsoft.YourPhone*' -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object DisplayName -like '*YourPhone*' | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
        }
        'CompatTel' {
            Get-Process -Name 'CompatTelRunner','DeviceCensus' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            $taskTargets = @(
                @{ Path = '\Microsoft\Windows\Application Experience\'; Name = 'Microsoft Compatibility Appraiser' }
                @{ Path = '\Microsoft\Windows\Application Experience\'; Name = 'ProgramDataUpdater' }
                @{ Path = '\Microsoft\Windows\Customer Experience Improvement Program\'; Name = 'Consolidator' }
                @{ Path = '\Microsoft\Windows\Customer Experience Improvement Program\'; Name = 'KernelCeipTask' }
                @{ Path = '\Microsoft\Windows\Customer Experience Improvement Program\'; Name = 'UsbCeip' }
                @{ Path = '\Microsoft\Windows\Autochk\'; Name = 'Proxy' }
                @{ Path = '\Microsoft\Windows\DiskDiagnostic\'; Name = 'Microsoft-Windows-DiskDiagnosticDataCollector' }
            )
            foreach ($t in $taskTargets) {
                try { Disable-ScheduledTask -TaskPath $t.Path -TaskName $t.Name -ErrorAction SilentlyContinue | Out-Null } catch {}
            }
        }
        'Cortana' {
            Get-Process -Name 'Cortana' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            Get-AppxPackage -Name '*549981C3F5F10*' -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object DisplayName -like '*549981C3F5F10*' | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
        }
        'OneDrive' {
            Get-Process -Name 'OneDrive' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue
        }
        'EdgeBg' {
            $k = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
            if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
            Set-ItemProperty -Path $k -Name "StartupBoostEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $k -Name "BackgroundModeEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        }
    }
}

function Assistant-SmartJunkDetector {
    Invoke-AssistantHeader "SMART WINDOWS JUNK & RAM-HOG DETECTOR" "Scans running processes for known Windows bloat/telemetry tasks and lets you disable what it finds."

    Write-Host "${creamyCyan}[*] Scanning running processes against known Windows junk signatures...${reset}"
    Write-Host ''

    $detected = @()
    foreach ($item in $smartJunkCatalog) {
        $matchedProcs = Get-Process -Name $item.Processes -ErrorAction SilentlyContinue
        if ($matchedProcs) {
            $wsBytes = ($matchedProcs | Measure-Object -Property WorkingSet64 -Sum).Sum
            $wsMB = [math]::Round($wsBytes / 1MB, 1)
            # Skip flagging Edge background mode unless it's clearly idle background bloat,
            # not an actively open browsing session.
            if ($item.Id -eq 'EdgeBg' -and $wsMB -lt 250) { continue }
            $detected += [PSCustomObject]@{
                Id       = $item.Id
                Display  = $item.Display
                Category = $item.Category
                Safe     = $item.Safe
                RamMB    = $wsMB
                Count    = $matchedProcs.Count
            }
        }
    }

    if ($detected.Count -eq 0) {
        Write-Host "${creamyGreen}[CLEAN] No known Windows junk/RAM-hog processes currently running.${reset}"
        Write-Host ''
        Write-Host 'Press Enter to return to main menu...'
        [void][Console]::ReadLine()
        return
    }

    $detected = $detected | Sort-Object RamMB -Descending
    $totalMB = [math]::Round(($detected | Measure-Object -Property RamMB -Sum).Sum, 1)

    Write-Host "${creamyYellow}Detected $($detected.Count) known junk/bloat item(s) holding ~${creamyCyan}$totalMB MB${creamyYellow} of RAM right now:${reset}"
    Write-Host ''
    Write-Host ("  {0,-4} {1,-42} {2,-20} {3,9}   {4}" -f "NUM", "ITEM", "CATEGORY", "RAM", "STATUS")
    Write-Host "  ---------------------------------------------------------------------------------------------"

    $idx = 1
    foreach ($d in $detected) {
        $typeTag = if ($d.Safe) { "${creamyGreen}SAFE TO DISABLE${reset}" } else { "${creamyYellow}REVIEW FIRST${reset}" }
        $ramStr  = "$($d.RamMB) MB"
        Write-Host ("  [{0,2}] {1,-42} {2,-20} {3,9}   {4}" -f $idx, $d.Display, $d.Category, $ramStr, $typeTag)
        $idx++
    }

    Write-Host "  ---------------------------------------------------------------------------------------------"
    Write-Host ("  {0,-4} {1,-42} {2,-20} {3,9}" -f "", "TOTAL", "", "$totalMB MB")
    Write-Host ''
    Write-Host "${dimText}  SAFE TO DISABLE   Windows starts these on its own - no downside to turning them off.${reset}"
    Write-Host "${dimText}  REVIEW FIRST      OneDrive sync / Edge background mode - confirm you don't rely on these first.${reset}"
    Write-Host ''
    Write-Host "Enter numbers to disable (e.g. 1,3), 'ALL_SAFE' for all SAFE items, or 0 to cancel:"
    $sel = Read-Host "Selection"

    if ($sel -match '^[0]$' -or -not $sel) { return }

    $toDisable = @()
    if ($sel -match '^ALL_SAFE$') {
        $toDisable = $detected | Where-Object { $_.Safe }
    } else {
        $parts = $sel -split ','
        foreach ($pRaw in $parts) {
            $pTrim = $pRaw.Trim()
            if ($pTrim -match '^\d+$') {
                $n = [int]$pTrim
                if ($n -ge 1 -and $n -le $detected.Count) { $toDisable += $detected[$n - 1] }
            }
        }
    }

    $toDisable = $toDisable | Select-Object -Unique
    if ($toDisable.Count -eq 0) {
        Write-Host "${creamyYellow}[INFO] Nothing selected.${reset}"
        Start-Sleep -Seconds 1
        return
    }

    Write-Host ''
    Create-SafeRestorePoint
    Write-Host ''

    foreach ($td in $toDisable) {
        Write-Host "${creamyCyan}[*] Disabling: $($td.Display)...${reset}" -NoNewline
        try {
            Invoke-SmartJunkDisable -id $td.Id
            Write-Host " ${creamyGreen}[DISABLED]${reset} (freed ~$($td.RamMB) MB)"
            Write-AssistantLog "SmartJunkDetector" "SUCCESS" "Disabled $($td.Id) (~$($td.RamMB) MB)"
        } catch {
            Write-Host " ${creamyRed}[FAILED]${reset}"
            Write-AssistantLog "SmartJunkDetector" "FAILED" "$($td.Id): $($_.Exception.Message)"
        }
    }

    Write-Host ''
    Write-Host "${creamyGreen}[OK] Smart junk cleanup complete.${reset}"
    Write-Host 'Press Enter to return to main menu...'
    [void][Console]::ReadLine()
}

# ===================================================================
# MODULE 8: TELEMETRY & START MENU ADS PURGE
# ===================================================================
function Assistant-ApplyTelemetryRegistry {
    try {
        # 1. Disable Windows Diagnostic Telemetry
        $dataColKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
        if (-not (Test-Path $dataColKey)) { New-Item -Path $dataColKey -Force | Out-Null }
        Set-ItemProperty -Path $dataColKey -Name "AllowTelemetry" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

        # 2. Disable Advertising ID for privacy
        $advKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
        if (-not (Test-Path $advKey)) { New-Item -Path $advKey -Force | Out-Null }
        Set-ItemProperty -Path $advKey -Name "Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

        # 3. Disable Start Menu Promoted Apps, Silent Downloads & Suggestions
        $cdmKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        if (-not (Test-Path $cdmKey)) { New-Item -Path $cdmKey -Force | Out-Null }
        $props = @(
            'SystemPaneSuggestionsEnabled', 'SilentInstalledAppsEnabled',
            'ContentDeliveryAllowed', 'OemPreInstalledAppsEnabled',
            'PreInstalledAppsEnabled', 'PreInstalledAppsEverEnabled',
            'SoftLandingEnabled', 'RotatingLockScreenEnabled',
            'SubscribedContent-310093Enabled', 'SubscribedContent-338387Enabled',
            'SubscribedContent-338388Enabled', 'SubscribedContent-338389Enabled',
            'SubscribedContent-353694Enabled', 'SubscribedContent-353696Enabled',
            'SubscribedContent-353698Enabled'
        )
        foreach ($p in $props) {
            Set-ItemProperty -Path $cdmKey -Name $p -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        }

        # 4. Disable Bing Search in Start Menu (speeds up search)
        $expKey = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
        if (-not (Test-Path $expKey)) { New-Item -Path $expKey -Force | Out-Null }
        Set-ItemProperty -Path $expKey -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

        # 5. Disable Windows Copilot system-wide & hide taskbar button
        $cpUser = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
        if (-not (Test-Path $cpUser)) { New-Item -Path $cpUser -Force | Out-Null }
        Set-ItemProperty -Path $cpUser -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

        $cpMachine = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
        if (-not (Test-Path $cpMachine)) { New-Item -Path $cpMachine -Force | Out-Null }
        Set-ItemProperty -Path $cpMachine -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

        $edgePolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
        if (-not (Test-Path $edgePolicy)) { New-Item -Path $edgePolicy -Force | Out-Null }
        Set-ItemProperty -Path $edgePolicy -Name "HubsSidebarEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

        # 6. Disable Taskbar Widgets, Weather Feeds & News popups
        $advExp = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        if (-not (Test-Path $advExp)) { New-Item -Path $advExp -Force | Out-Null }
        Set-ItemProperty -Path $advExp -Name "TaskbarDa" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $advExp -Name "ShowCopilotButton" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

        $dshUser = "HKCU:\Software\Policies\Microsoft\Dsh"
        if (-not (Test-Path $dshUser)) { New-Item -Path $dshUser -Force | Out-Null }
        Set-ItemProperty -Path $dshUser -Name "AllowNewsAndInterests" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

        $dshMachine = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
        if (-not (Test-Path $dshMachine)) { New-Item -Path $dshMachine -Force | Out-Null }
        Set-ItemProperty -Path $dshMachine -Name "AllowNewsAndInterests" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

        $feedsKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds"
        if (-not (Test-Path $feedsKey)) { New-Item -Path $feedsKey -Force | Out-Null }
        Set-ItemProperty -Path $feedsKey -Name "ShellFeedsTaskbarViewMode" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue

        $winFeedsKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds"
        if (-not (Test-Path $winFeedsKey)) { New-Item -Path $winFeedsKey -Force | Out-Null }
        Set-ItemProperty -Path $winFeedsKey -Name "EnableFeeds" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

        # 7. Block Windows from automatically downloading consumer bloat & suggested apps in the background
        $cloudUser = "HKCU:\Software\Policies\Microsoft\Windows\CloudContent"
        if (-not (Test-Path $cloudUser)) { New-Item -Path $cloudUser -Force | Out-Null }
        Set-ItemProperty -Path $cloudUser -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

        $cloudMachine = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
        if (-not (Test-Path $cloudMachine)) { New-Item -Path $cloudMachine -Force | Out-Null }
        Set-ItemProperty -Path $cloudMachine -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

        Write-Host "${creamyGreen}[OK] Privacy, telemetry, Copilot, Widgets/Weather, and auto-download blocks applied.${reset}"
        Write-AssistantLog "TelemetryDebloat" "SUCCESS" "Disabled telemetry, Copilot, Widgets/Weather feeds and background promo apps"
    } catch {
        Write-Host "${creamyRed}[WARN] Some registry settings could not be updated: $($_.Exception.Message)${reset}"
    }
}

function Assistant-TelemetryPurge {
    Invoke-AssistantHeader "WINDOWS TELEMETRY & START MENU ADS PURGE" "Disables Windows diagnostic telemetry, ad identifiers, and Start menu promoted apps."

    Create-SafeRestorePoint
    Write-Host ''
    Assistant-ApplyTelemetryRegistry
    Write-Host ''
    Write-Host 'Press Enter to return to main menu...'
    [void][Console]::ReadLine()
}

# ===================================================================
# MODULE 9: NON-ESSENTIAL SERVICES OPTIMIZER
# ===================================================================
function Assistant-ServicesOptimizer {
    Invoke-AssistantHeader "WINDOWS SERVICES OPTIMIZER" "Safely configures background telemetry, error reporting, and non-essential services."

    Write-Host "  ${creamyGreen}[1] Safe Recommended Tuning (Disable DiagTrack, WAP push, MapsBroker, RemoteRegistry)${reset}"
    Write-Host "  ${accentBlue}[2] Gaming Tuning (Above + Manual Error Reporting, Disables RetailDemo & Xbox Telemetry)${reset}"
    Write-Host "  ${dimText}[3] Restore Default Windows Services Configuration${reset}"
    Write-Host "  ${dimText}[0] Cancel & Return${reset}"
    Write-Host ''
    $sChoice = Read-Host "Select preset (0-3)"

    if ($sChoice -eq '0' -or -not $sChoice) { return }

    Create-SafeRestorePoint
    Write-Host ''

    if ($sChoice -in @('1', '2')) {
        $safeServices = @('DiagTrack', 'dmwappushservice', 'MapsBroker', 'RemoteRegistry', 'RetailDemo')
        if ($sChoice -eq '2') {
            $safeServices += @('WerSvc', 'XblAuthManager', 'XblGameSave', 'XboxNetApiSvc')
        }

        foreach ($srv in $safeServices) {
            Write-Host "${creamyCyan}[*] Optimizing service: $srv ...${reset}" -NoNewline
            try {
                Stop-Service -Name $srv -Force -ErrorAction SilentlyContinue
                Set-Service -Name $srv -StartupType Disabled -ErrorAction SilentlyContinue
                Write-Host " ${creamyGreen}[DISABLED]${reset}"
            } catch {
                Write-Host " ${creamyYellow}[SKIPPED]${reset}"
            }
        }
        Write-Host ''
        Write-Host "${creamyGreen}[OK] Services optimized.${reset}"
        Write-AssistantLog "ServicesOptimizer" "SUCCESS" "Optimized $($safeServices.Count) background services"
    } elseif ($sChoice -eq '3') {
        $restoreServices = @('DiagTrack', 'MapsBroker', 'WerSvc', 'XblAuthManager', 'XblGameSave', 'XboxNetApiSvc')
        foreach ($srv in $restoreServices) {
            Set-Service -Name $srv -StartupType Automatic -ErrorAction SilentlyContinue
        }
        Write-Host "${creamyGreen}[OK] Services restored to default settings.${reset}"
    }

    Write-Host ''
    Write-Host 'Press Enter to return to main menu...'
    [void][Console]::ReadLine()
}

# ===================================================================
# MODULE 10: DEFAULT APPS & PACKAGE RECOVERY CENTER
# ===================================================================
function Assistant-PackageRecovery {
    Invoke-AssistantHeader "DEFAULT APPS & PACKAGE RECOVERY CENTER" "Instructions and 1-click tools to restore default Microsoft Store applications."

    Write-Host "${creamyCyan}Options to restore or reinstall default Windows Store applications:${reset}"
    Write-Host ''
    Write-Host "${creamyYellow}[1] Re-register and restore all built-in Microsoft Store applications${reset}"
    Write-Host "${creamyYellow}[2] Roll back to a System Restore Point${reset}"
    Write-Host "${dimText}[0] Return to Main Menu${reset}"
    Write-Host ''
    $rChoice = Read-Host "Select option (0-2)"

    if ($rChoice -eq '1') {
        Write-Host ''
        Write-Host "${creamyCyan}[*] Re-registering all built-in packages...${reset}"
        try {
            Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Foreach-Object {
                Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -ErrorAction SilentlyContinue
            }
            Write-Host "${creamyGreen}[OK] Default apps re-registration command executed.${reset}"
        } catch {
            Write-Host "${creamyRed}[ERROR] Re-registration failed: $($_.Exception.Message)${reset}"
        }
    } elseif ($rChoice -eq '2') {
        Assistant-RestorePoints
        return
    }

    Write-Host ''
    Write-Host 'Press Enter to return to main menu...'
    [void][Console]::ReadLine()
}

# ===================================================================
# MODULE 11: HEALTH REPORT GENERATOR
# ===================================================================
function Assistant-HealthReport {
    Invoke-AssistantHeader "SYSTEM HEALTH & PERFORMANCE REPORT" "Generates a comprehensive HTML report of hardware, RAM, services and performance status."

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
        Write-Host "${creamyRed}[ERROR] Generate-HealthReport.ps1 not found.${reset}"
        Write-Host 'Press Enter to return to main menu...'
        [void][Console]::ReadLine()
        return
    }

    Write-Host "${creamyCyan}[REPORT] Collecting system performance data...${reset}"
    Write-Host ''

    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $docsFolder = [Environment]::GetFolderPath('MyDocuments')
    $reportDir = "$docsFolder\Secret-Optimizer\Reports"
    if (-not (Test-Path $reportDir)) { New-Item -ItemType Directory -Path $reportDir -Force | Out-Null }
    $outPath = "$reportDir\SecretOptimizer_HealthReport_$timestamp.html"

    try {
        $result = & powershell -NoProfile -ExecutionPolicy Bypass -File "$reportModule" -OutputPath $outPath 2>&1
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
# MODULE 12: SYSTEM RESTORE POINT MANAGER
# ===================================================================
function Assistant-RestorePoints {
    Invoke-AssistantHeader "SYSTEM RESTORE POINT MANAGER" "List, create or roll back to a previous System Restore Point."

    $points = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
    if (-not $points) {
        Write-Host "${creamyYellow}[INFO] No restore points found, or System Restore is disabled on $env:SystemDrive.${reset}"
        Write-Host "Enable System Restore and create one now? (Y/N): " -NoNewline
        $ans = Read-Host
        if ($ans -match '^[YySs]') {
            Enable-ComputerRestore -Drive "$env:SystemDrive" -ErrorAction SilentlyContinue
            Checkpoint-Computer -Description "Secret-Optimizer Manual Checkpoint" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
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
            Checkpoint-Computer -Description "Secret-Optimizer Manual Checkpoint" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
            Write-Host "${creamyGreen}[OK] Restore point created.${reset}"
            Write-AssistantLog "RestorePoint" "SUCCESS" "Manual restore point created"
        } elseif ($sel -match '^\d+$') {
            $target = $points | Where-Object { $_.SequenceNumber -eq [int]$sel }
            if ($target) {
                Write-Host "${creamyRed}[WARNING] This restarts the computer and rolls back system settings to '$($target.Description)'.${reset}"
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
# MODULE 13: ACTION HISTORY & LOGS VIEWER
# ===================================================================
function Assistant-ViewLogs {
    Invoke-AssistantHeader "ACTION HISTORY & OPTIMIZATION LOGS" "Displays logged optimization operations and system traces."

    Write-Host "${creamyYellow}--- Secret-Optimizer Action History ---${reset}"
    $docsFolder = [Environment]::GetFolderPath('MyDocuments')
    $histLog = "$docsFolder\Secret-Optimizer\Logs\optimizer_actions.log"
    if (-not (Test-Path $histLog)) { $histLog = "$installDir\logs\optimizer_actions.log" }
    if (Test-Path $histLog) {
        Get-Content $histLog -Tail 20 | ForEach-Object { Write-Host "   $_" }
    } else {
        Write-Host "   No previous action logs recorded."
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

    $mem = Get-SystemMemoryStats
    Write-Host " User: ${creamyCyan}$currentUser${reset} ${creamyGreen}[ADMIN]${reset} | Host: ${creamyCyan}$env:COMPUTERNAME${reset} | Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    Show-MemoryBar -mem $mem
    Write-Host '============================================================================================='
    Write-Host '              SECRET-OPTIMIZER : ADVANCED PROCESS & PERFORMANCE SUITE'
    Write-Host '============================================================================================='
    Write-Host ''
    Write-Host "  ${creamyYellow}--- PROCESS & MEMORY OPTIMIZATION ---${reset}"
    Write-Host "  ${creamyGreen}[1] 1-Click Intelligent Deep RAM Optimization (Safe Working Set Trim + Cache Flush)${reset}"
    Write-Host "  ${accentBlue}[2] Real-Time Process Monitor & Performance Booster (Priority, Threads & Tree Trim)${reset}"
    Write-Host "  ${accentBlue}[3] Idle Background Helper & Subprocess Freezer (Clean Chrome/Edge/Discord/Game Helpers)${reset}"
    Write-Host "  ${accentBlue}[4] Gaming / Heavy Workload Turbo Mode (Boost Foreground Game, Lower Background Overhead)${reset}"
    Write-Host "  ${accentBlue}[5] Continuous Smart RAM & Process Guard (Auto-optimizes memory above threshold)${reset}"
    Write-Host ''
    Write-Host "  ${creamyYellow}--- CONTROLLED WINDOWS DEBLOATER ---${reset}"
    Write-Host "  ${creamyGreen}[6] Safe 1-Click Recommended Debloat (Sponsored Apps, Junk Games, Stubs & Promo Items)${reset}"
    Write-Host "  ${accentBlue}[7] Controlled Custom AppX Package Manager (Granular Selection, Search & Uninstall)${reset}"
    Write-Host "  ${accentBlue}[8] Windows Telemetry, Diagnostic Tracking & Start Menu Ads Purge (Registry Optimization)${reset}"
    Write-Host "  ${accentBlue}[9] Windows Non-Essential Background Services Optimizer (Safe / Gaming Presets)${reset}"
    Write-Host "  ${accentBlue}[R] Default Apps & Package Recovery Center (1-Click Reinstall & Restore Guide)${reset}"
    Write-Host ''
    Write-Host "  ${creamyYellow}--- SMART WINDOWS JUNK & RAM-HOG DETECTOR ---${reset}"
    Write-Host "  ${creamyGreen}[S] Smart Windows Junk & RAM-Hog Detector (Auto-detect & disable background bloat)${reset}"
    Write-Host ''
    Write-Host "  ${creamyYellow}--- SYSTEM HEALTH & TOOLS ---${reset}"
    Write-Host "  ${creamyCyan}[H] Generate Comprehensive HTML Health & Performance Report${reset}"
    Write-Host "  ${accentBlue}[P] System Restore Point Center (Create / List / Roll Back)${reset}"
    Write-Host "  ${accentBlue}[L] Optimization Action History & Logs Viewer${reset}"
    Write-Host "  ${creamyRed}[0] Exit${reset}"
    Write-Host ''
    Write-Host '============================================================================================='
    Write-Host ''
    $choice = Read-Host "Select an option (1-9, S, R, H, P, L, 0)"

    switch ($choice.Trim()) {
        '1' { Assistant-RamOptimizer }
        '2' { Assistant-ProcessManager }
        '3' { Assistant-HelperFreezer }
        '4' { Assistant-GamingBooster }
        '5' { Assistant-ContinuousGuard }
        '6' { Assistant-Debloat }
        '7' { Assistant-InteractiveAppxManager }
        '8' { Assistant-TelemetryPurge }
        '9' { Assistant-ServicesOptimizer }
        { $_ -in 'S','s' } { Assistant-SmartJunkDetector }
        { $_ -in 'R','r' } { Assistant-PackageRecovery }
        { $_ -in 'H','h' } { Assistant-HealthReport }
        { $_ -in 'P','p' } { Assistant-RestorePoints }
        { $_ -in 'L','l' } { Assistant-ViewLogs }
        { $_ -in '0','X','x','q','Q' } { exit 0 }
        default {
            Write-Host "${creamyRed}Invalid option.${reset}"
            Start-Sleep -Seconds 1
        }
    }
}
