<#
.SYNOPSIS
    Secret-Optimizer Comprehensive Performance, RAM & Bloatware Audit Report
.DESCRIPTION
    Generates a state-of-the-art HTML performance report focused on memory pressure,
    process resource consumption, helper subprocess overhead, Windows bloatware audit,
    and telemetry & background service bottlenecks.
.AUTHOR
    mrsecret_official
#>

[CmdletBinding()]
param(
    [string]$OutputPath = ""
)

$esc = [char]27
$creamyGreen  = "$esc[38;2;145;225;165m"
$creamyRed    = "$esc[38;2;235;120;120m"
$creamyCyan   = "$esc[38;2;130;210;245m"
$creamyYellow = "$esc[38;2;245;220;130m"
$dimText      = "$esc[38;2;160;175;195m"
$reset        = "$esc[0m"

if (-not $OutputPath) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $docsFolder = [Environment]::GetFolderPath('MyDocuments')
    $reportDir = "$docsFolder\Secret-Optimizer\Reports"
    if (-not (Test-Path $reportDir)) { New-Item -ItemType Directory -Path $reportDir -Force | Out-Null }
    $OutputPath = "$reportDir\SecretOptimizer_PerformanceReport_$timestamp.html"
}

Write-Host ""
Write-Host "${creamyCyan}[REPORT] Analyzing system performance, RAM metrics, and bloatware...${reset}"

# ──────────────────────────────────────────────
# 1. SYSTEM & CPU METRICS
# ──────────────────────────────────────────────
$os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
$cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
$cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1

$reportDate = Get-Date -Format "dddd, MMMM dd, yyyy - HH:mm:ss"
$hostname = $env:COMPUTERNAME
$currentUser = $env:USERNAME
$uptime = if ($os -and $os.LastBootUpTime) {
    $ts = (Get-Date) - $os.LastBootUpTime
    "$($ts.Days)d $($ts.Hours)h $($ts.Minutes)m"
} else { 'N/A' }

$osName = if ($os) { $os.Caption } else { 'Windows 11/10' }
$osBuild = if ($os) { $os.BuildNumber } else { 'N/A' }
$osArch = if ($os) { $os.OSArchitecture } else { '64-bit' }

$cpuName = if ($cpu) { $cpu.Name.Trim() } else { 'Generic CPU' }
$cpuCores = if ($cpu) { "$($cpu.NumberOfCores) Cores / $($cpu.NumberOfLogicalProcessors) Threads" } else { 'N/A' }
$cpuSpeed = if ($cpu) { "$([math]::Round($cpu.MaxClockSpeed/1000, 2)) GHz" } else { 'N/A' }
$cpuLoad = if ($cpu) { "$($cpu.LoadPercentage)%" } else { 'N/A' }

# Power Plan
$activePowerPlan = 'Balanced'
try {
    $planOut = powercfg /getactivescheme 2>&1
    if ($planOut -match '\((.*?)\)') { $activePowerPlan = $matches[1] }
} catch {}

Write-Host "${dimText}  [1/6] Hardware profile & CPU metrics collected...${reset}"

# ──────────────────────────────────────────────
# 2. MEMORY & WORKING SET METRICS
# ──────────────────────────────────────────────
$totalRamGB = if ($cs) { [math]::Round($cs.TotalPhysicalMemory / 1GB, 2) } else { 16 }
$freeRamGB  = if ($os) { [math]::Round($os.FreePhysicalMemory / 1MB, 2) } else { 8 }
$usedRamGB  = [math]::Round($totalRamGB - $freeRamGB, 2)
$ramPercent = if ($totalRamGB -gt 0) { [math]::Round(($usedRamGB / $totalRamGB) * 100, 1) } else { 50 }

$protectedList = @(
    'System', 'Idle', 'Registry', 'smss', 'csrss', 'wininit', 'services', 'lsass',
    'winlogon', 'dwm', 'fontdrvhost', 'powershell', 'pwsh', 'cmd', 'conhost',
    'taskmgr', 'MsMpEng', 'SecurityHealthService', 'Antigravity', 'Code'
)

# Top RAM Processes
$allProcs = Get-Process -ErrorAction SilentlyContinue
$topProcesses = $allProcs | Sort-Object WorkingSet64 -Descending | Select-Object -First 15

# Helper Subprocesses (Browsers, Electron, Game Helpers)
$helperPatterns = @('chrome', 'msedge', 'brave', 'opera', 'firefox', 'discord', 'spotify', 'slack', 'teams', 'steamwebhelper', 'epicgameslauncher', 'googledrive', 'adobearm')
$helperProcs = $allProcs | Where-Object {
    $name = $_.ProcessName.ToLower()
    $helperPatterns | Where-Object { $name -like "*$_*" }
}

$helperCount = $helperProcs.Count
$helperWSBytes = ($helperProcs | Measure-Object -Property WorkingSet64 -Sum).Sum
$helperWSMB = [math]::Round($helperWSBytes / 1MB, 1)
$helperWSGB = [math]::Round($helperWSBytes / 1GB, 2)

Write-Host "${dimText}  [2/6] Process working sets & helper instances analyzed...${reset}"

# ──────────────────────────────────────────────
# 3. WINDOWS BLOATWARE & APPX AUDIT
# ──────────────────────────────────────────────
$installedAppx = Get-AppxPackage -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name -Unique
$bloatAuditList = @(
    @{ Name = "Clipchamp.Clipchamp"; Display = "Clipchamp Video Editor"; Category = "Promo Tool" }
    @{ Name = "Microsoft.BingNews"; Display = "Microsoft News & Feed"; Category = "News / Feed" }
    @{ Name = "Microsoft.BingWeather"; Display = "Bing Weather Widget"; Category = "Widget" }
    @{ Name = "Microsoft.BingFinance"; Display = "Bing Money & Finance"; Category = "Widget" }
    @{ Name = "Microsoft.BingSports"; Display = "Bing Sports"; Category = "Widget" }
    @{ Name = "Microsoft.WindowsFeedbackHub"; Display = "Windows Feedback Hub"; Category = "Telemetry" }
    @{ Name = "Microsoft.GetHelp"; Display = "Get Help Online Assistant"; Category = "Promo Tool" }
    @{ Name = "Microsoft.Getstarted"; Display = "Tips / Welcome App"; Category = "Promo Tool" }
    @{ Name = "Microsoft.People"; Display = "People / Contacts Bar"; Category = "Obsolete App" }
    @{ Name = "Microsoft.PowerAutomateDesktop"; Display = "Power Automate Desktop"; Category = "Enterprise Bloat" }
    @{ Name = "Microsoft.549981C3F5F10"; Display = "Cortana (Deprecated)"; Category = "Obsolete Voice" }
    @{ Name = "Microsoft.MixedReality.Portal"; Display = "Mixed Reality Portal"; Category = "VR Bloat" }
    @{ Name = "Microsoft.MicrosoftSolitaireCollection"; Display = "Microsoft Solitaire Collection"; Category = "Sponsored Game" }
    @{ Name = "Microsoft.Microsoft3DViewer"; Display = "3D Viewer"; Category = "Obsolete App" }
    @{ Name = "Microsoft.WindowsMaps"; Display = "Windows Maps"; Category = "Navigation" }
    @{ Name = "TikTok"; Display = "TikTok Sponsored App"; Category = "Sponsored App" }
    @{ Name = "CandyCrush"; Display = "Candy Crush Saga"; Category = "Sponsored Game" }
    @{ Name = "Disney"; Display = "Disney+ App"; Category = "Sponsored App" }
    @{ Name = "SpotifyAB.SpotifyMusic"; Display = "Spotify Pre-installed Stub"; Category = "Music Stub" }
    @{ Name = "Netflix"; Display = "Netflix Pre-installed Stub"; Category = "Video Stub" }
    @{ Name = "PrimeVideo"; Display = "Amazon Prime Video Stub"; Category = "Video Stub" }
)

$bloatResults = @()
$detectedBloatCount = 0

foreach ($b in $bloatAuditList) {
    $match = $installedAppx | Where-Object { $_ -like "*$($b.Name)*" }
    $isInstalled = ($null -ne $match -and $match.Count -gt 0)
    if ($isInstalled) { $detectedBloatCount++ }
    $bloatResults += [PSCustomObject]@{
        Name        = $b.Name
        Display     = $b.Display
        Category    = $b.Category
        IsInstalled = $isInstalled
        Status      = if ($isInstalled) { "INSTALLED" } else { "CLEAN" }
    }
}

$xboxMatch = $installedAppx | Where-Object { $_ -like "*XboxGamingOverlay*" -or $_ -like "*XboxApp*" }
$xboxInstalled = if ($xboxMatch) { $true } else { $false }

Write-Host "${dimText}  [3/6] Windows AppX bloatware packages audited...${reset}"

# ──────────────────────────────────────────────
# 4. PRIVACY, TELEMETRY & ADS AUDIT
# ──────────────────────────────────────────────
$telemetryVal = $null
$advVal = $null
$startAdsVal = $null
$bingSearchVal = $null

try {
    $telemetryVal = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -ErrorAction SilentlyContinue).AllowTelemetry
} catch {}
try {
    $advVal = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -ErrorAction SilentlyContinue).Enabled
} catch {}
try {
    $cdm = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -ErrorAction SilentlyContinue
    $startAdsVal = $cdm.SystemPaneSuggestionsEnabled
} catch {}
try {
    $bingSearchVal = (Get-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -ErrorAction SilentlyContinue).DisableSearchBoxSuggestions
} catch {}

$telemetryStatus = if ($telemetryVal -eq 0) { "DISABLED (OPTIMIZED)" } else { "ACTIVE (FULL TELEMETRY)" }
$advStatus = if ($advVal -eq 0) { "DISABLED (OPTIMIZED)" } else { "ACTIVE (TRACKING)" }
$startAdsStatus = if ($startAdsVal -eq 0) { "DISABLED (CLEAN)" } else { "ACTIVE (SHOWING ADS)" }
$bingSearchStatus = if ($bingSearchVal -eq 1) { "DISABLED (LOCAL ONLY)" } else { "ACTIVE (BING WEB SEARCH)" }

Write-Host "${dimText}  [4/6] Privacy, telemetry & Start Menu adware scanned...${reset}"

# ──────────────────────────────────────────────
# 5. BACKGROUND SERVICES AUDIT
# ──────────────────────────────────────────────
$servicesAudit = @(
    @{ Name = "DiagTrack"; Display = "Connected User Experiences & Telemetry" }
    @{ Name = "dmwappushservice"; Display = "Device Management WAP Push Telemetry" }
    @{ Name = "MapsBroker"; Display = "Downloaded Maps Manager" }
    @{ Name = "WerSvc"; Display = "Windows Error Reporting Service" }
    @{ Name = "RemoteRegistry"; Display = "Remote Registry Service" }
    @{ Name = "RetailDemo"; Display = "Retail Demo Service" }
    @{ Name = "WSearch"; Display = "Windows Search Indexing Service" }
)

$servicesResults = @()
foreach ($s in $servicesAudit) {
    $srvObj = Get-Service -Name $s.Name -ErrorAction SilentlyContinue
    $status = if ($srvObj) { $srvObj.Status.ToString() } else { "Not Found" }
    $startType = if ($srvObj) { $srvObj.StartType.ToString() } else { "N/A" }
    $servicesResults += [PSCustomObject]@{
        Name      = $s.Name
        Display   = $s.Display
        Status    = $status
        StartType = $startType
        IsHeavy   = ($status -eq "Running" -and $s.Name -in @('DiagTrack', 'dmwappushservice', 'RetailDemo'))
    }
}

# Startup items
$startupItems = @()
try {
    $startupItems = Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue | Select-Object -First 10
} catch {}

Write-Host "${dimText}  [5/6] Background services & startup bottlenecks inspected...${reset}"

# ──────────────────────────────────────────────
# 6. EXECUTIVE OPTIMIZATION SCORE
# ──────────────────────────────────────────────
$score = 100
if ($ramPercent -gt 85) { $score -= 20 }
elseif ($ramPercent -gt 70) { $score -= 10 }

if ($detectedBloatCount -gt 5) { $score -= 20 }
elseif ($detectedBloatCount -gt 0) { $score -= ($detectedBloatCount * 3) }

if ($telemetryStatus -match 'ACTIVE') { $score -= 10 }
if ($startAdsStatus -match 'ACTIVE') { $score -= 10 }
if ($activePowerPlan -match 'Power Saver|Balanced') { $score -= 5 }

if ($score -lt 20) { $score = 25 }

$grade = if ($score -ge 90) { 'A (EXCELLENT)' }
         elseif ($score -ge 75) { 'B (GOOD - MINOR TWEAKS)' }
         elseif ($score -ge 55) { 'C (NEEDS DEBLOAT & RAM CLEAN)' }
         else { 'D (HEAVILY BLOATED)' }

$gradeColor = if ($score -ge 85) { '#4ade80' } elseif ($score -ge 65) { '#fbbf24' } else { '#f87171' }

# Estimated reclaimable RAM
$estimatedReclaimMB = [math]::Round(($helperWSMB * 0.65) + 350, 0)

Write-Host "${dimText}  [6/6] Generating rich HTML dashboard...${reset}"

# ──────────────────────────────────────────────
# HTML TEMPLATE
# ──────────────────────────────────────────────
$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Secret-Optimizer Performance & Health Report - $hostname</title>
<style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap');

    :root {
        --bg-main: #070a12;
        --bg-card: rgba(18, 25, 41, 0.85);
        --bg-card-hover: rgba(26, 36, 60, 0.95);
        --border-card: rgba(56, 189, 248, 0.12);
        --border-active: rgba(56, 189, 248, 0.4);
        --text-main: #f1f5f9;
        --text-sub: #94a3b8;
        --text-dim: #64748b;
        --cyan: #38bdf8;
        --green: #4ade80;
        --yellow: #fbbf24;
        --red: #f87171;
        --purple: #c084fc;
    }

    * { box-sizing: border-box; margin: 0; padding: 0; }

    body {
        background-color: var(--bg-main);
        background-image: 
            radial-gradient(at 0% 0%, rgba(56, 189, 248, 0.08) 0px, transparent 50%),
            radial-gradient(at 100% 100%, rgba(192, 132, 252, 0.06) 0px, transparent 50%);
        color: var(--text-main);
        font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
        line-height: 1.6;
        padding: 30px 20px;
    }

    .container {
        max-width: 1240px;
        margin: 0 auto;
    }

    /* HEADER */
    .header {
        background: var(--bg-card);
        border: 1px solid var(--border-card);
        border-radius: 16px;
        padding: 28px 32px;
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 24px;
        backdrop-filter: blur(12px);
        box-shadow: 0 10px 25px rgba(0,0,0,0.3);
    }

    .logo-container {
        display: flex;
        align-items: center;
        gap: 16px;
    }

    .logo-icon {
        width: 48px;
        height: 48px;
        background: linear-gradient(135deg, #0284c7, #38bdf8);
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 24px;
        box-shadow: 0 0 20px rgba(56, 189, 248, 0.35);
    }

    .brand-title {
        font-size: 24px;
        font-weight: 800;
        letter-spacing: -0.5px;
        background: linear-gradient(90deg, #38bdf8, #818cf8);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
    }

    .brand-sub {
        font-size: 13px;
        color: var(--text-sub);
    }

    .header-score-card {
        text-align: right;
        background: rgba(10, 15, 26, 0.7);
        padding: 12px 24px;
        border-radius: 12px;
        border: 1px solid var(--border-card);
    }

    .score-label {
        font-size: 11px;
        text-transform: uppercase;
        color: var(--text-dim);
        font-weight: 700;
        letter-spacing: 0.5px;
    }

    .score-val {
        font-size: 28px;
        font-weight: 800;
        font-family: 'JetBrains Mono', monospace;
    }

    /* SUMMARY GRID */
    .kpi-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
        gap: 16px;
        margin-bottom: 24px;
    }

    .kpi-card {
        background: var(--bg-card);
        border: 1px solid var(--border-card);
        border-radius: 14px;
        padding: 20px;
        backdrop-filter: blur(8px);
        transition: transform 0.2s, border-color 0.2s;
    }

    .kpi-card:hover {
        transform: translateY(-2px);
        border-color: var(--border-active);
    }

    .kpi-title {
        font-size: 12px;
        font-weight: 600;
        color: var(--text-sub);
        text-transform: uppercase;
        letter-spacing: 0.5px;
        margin-bottom: 8px;
    }

    .kpi-value {
        font-size: 22px;
        font-weight: 700;
        font-family: 'JetBrains Mono', monospace;
        margin-bottom: 6px;
    }

    .kpi-sub {
        font-size: 12px;
        color: var(--text-dim);
    }

    /* SECTIONS */
    .section {
        background: var(--bg-card);
        border: 1px solid var(--border-card);
        border-radius: 14px;
        padding: 24px 28px;
        margin-bottom: 24px;
        backdrop-filter: blur(8px);
    }

    .section-title {
        font-size: 16px;
        font-weight: 700;
        color: var(--text-main);
        display: flex;
        align-items: center;
        gap: 10px;
        margin-bottom: 16px;
        padding-bottom: 12px;
        border-bottom: 1px solid rgba(255,255,255,0.06);
    }

    .section-icon {
        color: var(--cyan);
        font-size: 18px;
    }

    /* RAM PROGRESS BAR */
    .progress-bar-container {
        background: rgba(0,0,0,0.4);
        border-radius: 10px;
        height: 20px;
        width: 100%;
        overflow: hidden;
        margin: 10px 0 16px 0;
        border: 1px solid rgba(255,255,255,0.08);
    }

    .progress-bar-fill {
        height: 100%;
        background: linear-gradient(90deg, #0284c7, #38bdf8);
        border-radius: 8px;
        transition: width 0.5s;
    }

    /* TABLES */
    .data-table {
        width: 100%;
        border-collapse: collapse;
        margin-top: 8px;
        font-size: 13px;
    }

    .data-table th {
        text-align: left;
        padding: 10px 12px;
        color: var(--text-dim);
        font-weight: 600;
        text-transform: uppercase;
        font-size: 11px;
        letter-spacing: 0.5px;
        border-bottom: 1px solid rgba(255,255,255,0.08);
    }

    .data-table td {
        padding: 10px 12px;
        border-bottom: 1px solid rgba(255,255,255,0.04);
        color: var(--text-main);
    }

    .data-table tr:hover td {
        background: rgba(255,255,255,0.02);
    }

    .mono {
        font-family: 'JetBrains Mono', monospace;
    }

    /* BADGES */
    .badge {
        display: inline-block;
        padding: 3px 8px;
        border-radius: 6px;
        font-size: 11px;
        font-weight: 600;
        text-transform: uppercase;
        font-family: 'JetBrains Mono', monospace;
    }

    .badge-clean { background: rgba(74, 222, 128, 0.15); color: #4ade80; border: 1px solid rgba(74, 222, 128, 0.3); }
    .badge-bloat { background: rgba(248, 113, 113, 0.15); color: #f87171; border: 1px solid rgba(248, 113, 113, 0.3); }
    .badge-warn  { background: rgba(251, 191, 36, 0.15); color: #fbbf24; border: 1px solid rgba(251, 191, 36, 0.3); }
    .badge-info  { background: rgba(56, 189, 248, 0.15); color: #38bdf8; border: 1px solid rgba(56, 189, 248, 0.3); }

    /* ACTION ROADMAP */
    .roadmap-list {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
        gap: 12px;
        margin-top: 8px;
    }

    .roadmap-item {
        background: rgba(10, 15, 26, 0.6);
        border: 1px solid rgba(56, 189, 248, 0.15);
        border-radius: 10px;
        padding: 14px 18px;
        display: flex;
        align-items: center;
        gap: 14px;
    }

    .roadmap-num {
        width: 32px;
        height: 32px;
        border-radius: 8px;
        background: rgba(56, 189, 248, 0.15);
        color: var(--cyan);
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        font-family: 'JetBrains Mono', monospace;
    }

    .roadmap-text {
        font-size: 13px;
        color: var(--text-main);
    }

    .roadmap-sub {
        font-size: 11px;
        color: var(--text-dim);
    }

    /* FOOTER */
    .footer {
        text-align: center;
        padding: 24px;
        color: var(--text-dim);
        font-size: 12px;
    }

    .footer span {
        color: var(--cyan);
        font-weight: 600;
    }
</style>
</head>
<body>

<div class="container">

    <!-- HEADER -->
    <div class="header">
        <div class="logo-container">
            <div class="logo-icon">&#9889;</div>
            <div>
                <div class="brand-title">Secret-Optimizer</div>
                <div class="brand-sub">Advanced Process, Memory & Windows Bloatware Audit</div>
            </div>
        </div>
        <div class="header-score-card">
            <div class="score-label">Optimization Score</div>
            <div class="score-val" style="color: $gradeColor;">$score / 100</div>
            <div class="score-label" style="color: $gradeColor; font-size:10px;">$grade</div>
        </div>
    </div>

    <!-- KPI SUMMARY GRID -->
    <div class="kpi-grid">
        <div class="kpi-card">
            <div class="kpi-title">RAM Utilization</div>
            <div class="kpi-value" style="color: $(if($ramPercent -gt 80){'#f87171'}elseif($ramPercent -gt 65){'#fbbf24'}else{'#4ade80'});">$usedRamGB GB <span style="font-size:14px;color:var(--text-dim);">/ $totalRamGB GB</span></div>
            <div class="kpi-sub">$ramPercent% active load &bull; $freeRamGB GB available</div>
        </div>

        <div class="kpi-card">
            <div class="kpi-title">Helper Subprocesses</div>
            <div class="kpi-value" style="color: #38bdf8;">$helperWSMB MB</div>
            <div class="kpi-sub">$helperCount idle browser/app helper tasks</div>
        </div>

        <div class="kpi-card">
            <div class="kpi-title">Bloatware Detected</div>
            <div class="kpi-value" style="color: $(if($detectedBloatCount -gt 0){'#f87171'}else{'#4ade80'});">$detectedBloatCount Apps</div>
            <div class="kpi-sub">Pre-installed promo & junk packages</div>
        </div>

        <div class="kpi-card">
            <div class="kpi-title">Telemetry & Adware</div>
            <div class="kpi-value" style="color: $(if($telemetryStatus -match 'ACTIVE'){'#fbbf24'}else{'#4ade80'});">$(if($telemetryStatus -match 'ACTIVE'){'Active'}else{'Clean'})</div>
            <div class="kpi-sub">DiagTrack & Start Menu Ads status</div>
        </div>
    </div>

    <!-- SECTION 1: PROCESS & RAM DIAGNOSTICS -->
    <div class="section">
        <div class="section-title">
            <span class="section-icon">&#128187;</span>
            Deep Memory & Process Working Set Breakdown
        </div>

        <div style="display:flex; justify-content:space-between; font-size:12px; color:var(--text-sub); margin-bottom:4px;">
            <span>Memory Pressure Status: <strong>$ramPercent%</strong></span>
            <span>Potential Reclamation: <strong>~$estimatedReclaimMB MB</strong> via 1-Click Trim</span>
        </div>
        <div class="progress-bar-container">
            <div class="progress-bar-fill" style="width: $ramPercent%;"></div>
        </div>

        <table class="data-table">
            <thead>
                <tr>
                    <th>PID</th>
                    <th>Process Name</th>
                    <th>Working Set (RAM)</th>
                    <th>Threads</th>
                    <th>Status / Category</th>
                </tr>
            </thead>
            <tbody>
"@

foreach ($p in $topProcesses) {
    $wsMB = [math]::Round($p.WorkingSet64 / 1MB, 1)
    $catBadge = if ($p.ProcessName -in $protectedList) {
        "<span class='badge badge-info'>System Core</span>"
    } elseif ($p.ProcessName -match 'chrome|edge|brave|discord|spotify|steam') {
        "<span class='badge badge-warn'>Helper / Idle</span>"
    } else {
        "<span class='badge badge-clean'>User Task</span>"
    }

    $html += @"
                <tr>
                    <td class="mono">$($p.Id)</td>
                    <td><strong>$($p.ProcessName)</strong></td>
                    <td class="mono" style="color:var(--cyan);">$wsMB MB</td>
                    <td class="mono">$($p.Threads.Count)</td>
                    <td>$catBadge</td>
                </tr>
"@
}

$html += @"
            </tbody>
        </table>
    </div>

    <!-- SECTION 2: WINDOWS BLOATWARE AUDIT -->
    <div class="section">
        <div class="section-title">
            <span class="section-icon">&#128737;</span>
            Windows Bloatware & Sponsored Package Audit
        </div>
        <p style="font-size:13px; color:var(--text-sub); margin-bottom:16px;">
            Audit of pre-installed promotional applications, games, and telemetry stubs found on this Windows installation.
        </p>

        <table class="data-table">
            <thead>
                <tr>
                    <th>Application</th>
                    <th>Package Identifier</th>
                    <th>Category</th>
                    <th>Audit Status</th>
                </tr>
            </thead>
            <tbody>
"@

foreach ($b in $bloatResults) {
    $statusBadge = if ($b.IsInstalled) {
        "<span class='badge badge-bloat'>NEEDS DEBLOAT</span>"
    } else {
        "<span class='badge badge-clean'>CLEAN / REMOVED</span>"
    }

    $html += @"
                <tr>
                    <td><strong>$($b.Display)</strong></td>
                    <td class="mono" style="color:var(--text-dim);">$($b.Name)</td>
                    <td>$($b.Category)</td>
                    <td>$statusBadge</td>
                </tr>
"@
}

$html += @"
            </tbody>
        </table>
    </div>

    <!-- SECTION 3: PRIVACY & TELEMETRY AUDIT -->
    <div class="section">
        <div class="section-title">
            <span class="section-icon">&#128274;</span>
            Privacy, Telemetry & Start Menu Adware Audit
        </div>

        <table class="data-table">
            <thead>
                <tr>
                    <th>Component</th>
                    <th>Registry / Target Policy</th>
                    <th>Current Status</th>
                    <th>Recommendation</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td><strong>Windows Diagnostic Telemetry</strong></td>
                    <td class="mono">HKLM:\...\DataCollection\AllowTelemetry</td>
                    <td><span class="badge $(if($telemetryStatus -match 'ACTIVE'){'badge-warn'}else{'badge-clean'})">$telemetryStatus</span></td>
                    <td style="color:var(--text-sub);">Disable via Menu Option [8]</td>
                </tr>
                <tr>
                    <td><strong>Advertising ID Tracking</strong></td>
                    <td class="mono">HKCU:\...\AdvertisingInfo\Enabled</td>
                    <td><span class="badge $(if($advStatus -match 'ACTIVE'){'badge-warn'}else{'badge-clean'})">$advStatus</span></td>
                    <td style="color:var(--text-sub);">Disable via Menu Option [8]</td>
                </tr>
                <tr>
                    <td><strong>Start Menu Promoted Apps & Ads</strong></td>
                    <td class="mono">HKCU:\...\ContentDeliveryManager</td>
                    <td><span class="badge $(if($startAdsStatus -match 'ACTIVE'){'badge-warn'}else{'badge-clean'})">$startAdsStatus</span></td>
                    <td style="color:var(--text-sub);">Disable via Menu Option [8]</td>
                </tr>
                <tr>
                    <td><strong>Bing Web Search in Start Menu</strong></td>
                    <td class="mono">HKCU:\...\Explorer\DisableSearchBoxSuggestions</td>
                    <td><span class="badge $(if($bingSearchStatus -match 'ACTIVE'){'badge-warn'}else{'badge-clean'})">$bingSearchStatus</span></td>
                    <td style="color:var(--text-sub);">Disable to speed up local search</td>
                </tr>
            </tbody>
        </table>
    </div>

    <!-- SECTION 4: BACKGROUND SERVICES & POWER OPTIMIZATION -->
    <div class="section">
        <div class="section-title">
            <span class="section-icon">&#9881;</span>
            Background Services & Power Profile Audit
        </div>

        <div style="margin-bottom:16px; font-size:13px; color:var(--text-sub);">
            Active Power Scheme: <strong style="color:var(--cyan);">$activePowerPlan</strong> &bull; Host: <strong>$hostname</strong> &bull; Uptime: <strong>$uptime</strong>
        </div>

        <table class="data-table">
            <thead>
                <tr>
                    <th>Service Name</th>
                    <th>Description</th>
                    <th>Current State</th>
                    <th>Startup Type</th>
                </tr>
            </thead>
            <tbody>
"@

foreach ($s in $servicesResults) {
    $stateBadge = if ($s.Status -eq "Running") {
        if ($s.IsHeavy) { "<span class='badge badge-warn'>RUNNING (TELEMETRY)</span>" } else { "<span class='badge badge-info'>RUNNING</span>" }
    } else {
        "<span class='badge badge-clean'>STOPPED</span>"
    }

    $html += @"
                <tr>
                    <td class="mono"><strong>$($s.Name)</strong></td>
                    <td>$($s.Display)</td>
                    <td>$stateBadge</td>
                    <td class="mono">$($s.StartType)</td>
                </tr>
"@
}

$html += @"
            </tbody>
        </table>
    </div>

    <!-- SECTION 5: SECRET-OPTIMIZER ACTION ROADMAP -->
    <div class="section">
        <div class="section-title">
            <span class="section-icon">&#128640;</span>
            Recommended 1-Click Secret-Optimizer Actions
        </div>

        <div class="roadmap-list">
            <div class="roadmap-item">
                <div class="roadmap-num">1</div>
                <div>
                    <div class="roadmap-text">Execute 1-Click Deep RAM Optimizer</div>
                    <div class="roadmap-sub">Reclaim ~$estimatedReclaimMB MB RAM (Menu Option [1])</div>
                </div>
            </div>

            <div class="roadmap-item">
                <div class="roadmap-num">2</div>
                <div>
                    <div class="roadmap-text">Run Safe 1-Click Bloatware Debloat</div>
                    <div class="roadmap-sub">Purge $detectedBloatCount detected promo packages (Menu Option [6])</div>
                </div>
            </div>

            <div class="roadmap-item">
                <div class="roadmap-num">3</div>
                <div>
                    <div class="roadmap-text">Apply Privacy & Telemetry Purge</div>
                    <div class="roadmap-sub">Turn off Start Menu ads & tracking (Menu Option [8])</div>
                </div>
            </div>

            <div class="roadmap-item">
                <div class="roadmap-num">4</div>
                <div>
                    <div class="roadmap-text">Enable Continuous Smart RAM Guard</div>
                    <div class="roadmap-sub">Prevent background memory buildup (Menu Option [5])</div>
                </div>
            </div>
        </div>
    </div>

    <!-- FOOTER -->
    <div class="footer">
        Generated by <span>Secret-Optimizer</span> &bull; mrsecret_official &bull; All performance diagnostics evaluated 100% locally
        <div style="margin-top:4px;">Report Date: $reportDate</div>
    </div>

</div>

</body>
</html>
"@

# ──────────────────────────────────────────────
# SAVE REPORT
# ──────────────────────────────────────────────
try {
    [System.IO.File]::WriteAllText($OutputPath, $html, [System.Text.Encoding]::UTF8)
    Write-Host ""
    Write-Host "${creamyGreen}[OK] Secret-Optimizer Performance Report generated successfully!${reset}"
    Write-Host "     Path: ${creamyCyan}$OutputPath${reset}"
    Write-Host ""
    try { Start-Process $OutputPath -ErrorAction SilentlyContinue } catch {}
    return $OutputPath
} catch {
    Write-Host "${creamyRed}[ERROR] Failed to save report: $($_.Exception.Message)${reset}"
    return $null
}
