<#
.SYNOPSIS
    Secret-Optimizer Comprehensive Performance, RAM & Bloatware Audit Report
.DESCRIPTION
    Generates a clean, minimal HTML performance report focused on memory pressure,
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

$grade = if ($score -ge 90) { 'A - Excellent' }
         elseif ($score -ge 75) { 'B - Good, minor tweaks' }
         elseif ($score -ge 55) { 'C - Needs debloat & RAM clean' }
         else { 'D - Heavily bloated' }

$gradeColor = if ($score -ge 85) { '#5fbf7a' } elseif ($score -ge 65) { '#c9a94d' } else { '#c25a52' }

# Estimated reclaimable RAM
$estimatedReclaimMB = [math]::Round(($helperWSMB * 0.65) + 350, 0)

Write-Host "${dimText}  [6/6] Generating report...${reset}"

# ──────────────────────────────────────────────
# HTML TEMPLATE
# ──────────────────────────────────────────────
$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Secret-Optimizer Report - $hostname</title>
<style>
    :root {
        --bg: #101114;
        --bg-panel: #17181c;
        --border: #2a2b30;
        --text: #e4e4e6;
        --text-sub: #9a9ba1;
        --text-dim: #6b6c72;
        --green: #5fbf7a;
        --yellow: #c9a94d;
        --red: #c25a52;
        --accent: #7c9fc9;
    }

    * { box-sizing: border-box; margin: 0; padding: 0; }

    body {
        background: var(--bg);
        color: var(--text);
        font-family: -apple-system, "Segoe UI", Helvetica, Arial, sans-serif;
        font-size: 14px;
        line-height: 1.55;
        padding: 40px 20px;
    }

    .container {
        max-width: 1080px;
        margin: 0 auto;
    }

    /* HEADER */
    .header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        padding-bottom: 20px;
        margin-bottom: 28px;
        border-bottom: 1px solid var(--border);
    }

    .brand-title {
        font-size: 20px;
        font-weight: 600;
        letter-spacing: -0.2px;
    }

    .brand-sub {
        font-size: 13px;
        color: var(--text-sub);
        margin-top: 4px;
    }

    .meta-line {
        font-size: 12px;
        color: var(--text-dim);
        margin-top: 10px;
    }

    .header-score {
        text-align: right;
    }

    .score-label {
        font-size: 11px;
        text-transform: uppercase;
        color: var(--text-dim);
        letter-spacing: 0.4px;
    }

    .score-val {
        font-size: 30px;
        font-weight: 700;
        font-family: Consolas, "Courier New", monospace;
        line-height: 1.2;
    }

    .score-grade {
        font-size: 12px;
        margin-top: 2px;
    }

    /* SUMMARY GRID */
    .kpi-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
        gap: 1px;
        background: var(--border);
        border: 1px solid var(--border);
        margin-bottom: 28px;
    }

    .kpi-card {
        background: var(--bg-panel);
        padding: 16px 18px;
    }

    .kpi-title {
        font-size: 11px;
        font-weight: 600;
        color: var(--text-sub);
        text-transform: uppercase;
        letter-spacing: 0.4px;
        margin-bottom: 8px;
    }

    .kpi-value {
        font-size: 20px;
        font-weight: 600;
        font-family: Consolas, "Courier New", monospace;
        margin-bottom: 4px;
    }

    .kpi-sub {
        font-size: 12px;
        color: var(--text-dim);
    }

    /* SECTIONS */
    .section {
        margin-bottom: 32px;
    }

    .section-title {
        font-size: 14px;
        font-weight: 600;
        color: var(--text);
        margin-bottom: 4px;
    }

    .section-desc {
        font-size: 12px;
        color: var(--text-dim);
        margin-bottom: 14px;
    }

    /* RAM PROGRESS BAR */
    .progress-row {
        display: flex;
        justify-content: space-between;
        font-size: 12px;
        color: var(--text-sub);
        margin-bottom: 6px;
    }

    .progress-bar-container {
        background: var(--bg-panel);
        border: 1px solid var(--border);
        height: 8px;
        width: 100%;
        overflow: hidden;
        margin-bottom: 20px;
    }

    .progress-bar-fill {
        height: 100%;
        background: var(--accent);
    }

    /* TABLES */
    .data-table {
        width: 100%;
        border-collapse: collapse;
        font-size: 13px;
    }

    .data-table th {
        text-align: left;
        padding: 8px 10px;
        color: var(--text-dim);
        font-weight: 600;
        text-transform: uppercase;
        font-size: 11px;
        letter-spacing: 0.4px;
        border-bottom: 1px solid var(--border);
    }

    .data-table td {
        padding: 8px 10px;
        border-bottom: 1px solid var(--border);
        color: var(--text);
    }

    .data-table tr:last-child td {
        border-bottom: none;
    }

    .mono {
        font-family: Consolas, "Courier New", monospace;
    }

    .text-dim { color: var(--text-dim); }
    .text-sub { color: var(--text-sub); }

    /* STATUS TEXT (no pill chrome, just color + label) */
    .status {
        font-family: Consolas, "Courier New", monospace;
        font-size: 12px;
        font-weight: 600;
    }

    .status-clean { color: var(--green); }
    .status-bloat { color: var(--red); }
    .status-warn  { color: var(--yellow); }
    .status-info  { color: var(--text-sub); }

    /* ACTION LIST */
    .action-list {
        border: 1px solid var(--border);
    }

    .action-item {
        display: flex;
        align-items: baseline;
        gap: 14px;
        padding: 12px 16px;
        border-bottom: 1px solid var(--border);
    }

    .action-item:last-child {
        border-bottom: none;
    }

    .action-num {
        font-family: Consolas, "Courier New", monospace;
        color: var(--text-dim);
        font-size: 12px;
        min-width: 16px;
    }

    .action-text {
        font-size: 13px;
        color: var(--text);
    }

    .action-sub {
        font-size: 12px;
        color: var(--text-dim);
        margin-top: 2px;
    }

    /* FOOTER */
    .footer {
        text-align: left;
        padding-top: 20px;
        border-top: 1px solid var(--border);
        color: var(--text-dim);
        font-size: 12px;
    }
</style>
</head>
<body>

<div class="container">

    <!-- HEADER -->
    <div class="header">
        <div>
            <div class="brand-title">Secret-Optimizer</div>
            <div class="brand-sub">Process, memory & Windows bloatware audit</div>
            <div class="meta-line">$hostname &bull; $currentUser &bull; $osName (Build $osBuild, $osArch) &bull; Uptime $uptime</div>
        </div>
        <div class="header-score">
            <div class="score-label">Optimization Score</div>
            <div class="score-val" style="color: $gradeColor;">$score / 100</div>
            <div class="score-grade" style="color: $gradeColor;">$grade</div>
        </div>
    </div>

    <!-- KPI SUMMARY GRID -->
    <div class="kpi-grid">
        <div class="kpi-card">
            <div class="kpi-title">RAM Utilization</div>
            <div class="kpi-value" style="color: $(if($ramPercent -gt 80){'var(--red)'}elseif($ramPercent -gt 65){'var(--yellow)'}else{'var(--green)'});">$usedRamGB GB <span style="font-size:13px;color:var(--text-dim);">/ $totalRamGB GB</span></div>
            <div class="kpi-sub">$ramPercent% active load &bull; $freeRamGB GB available</div>
        </div>

        <div class="kpi-card">
            <div class="kpi-title">Helper Subprocesses</div>
            <div class="kpi-value">$helperWSMB MB</div>
            <div class="kpi-sub">$helperCount idle browser/app helper tasks</div>
        </div>

        <div class="kpi-card">
            <div class="kpi-title">Bloatware Detected</div>
            <div class="kpi-value" style="color: $(if($detectedBloatCount -gt 0){'var(--red)'}else{'var(--green)'});">$detectedBloatCount apps</div>
            <div class="kpi-sub">Pre-installed promo & junk packages</div>
        </div>

        <div class="kpi-card">
            <div class="kpi-title">Telemetry & Adware</div>
            <div class="kpi-value" style="color: $(if($telemetryStatus -match 'ACTIVE'){'var(--yellow)'}else{'var(--green)'});">$(if($telemetryStatus -match 'ACTIVE'){'Active'}else{'Clean'})</div>
            <div class="kpi-sub">DiagTrack & Start Menu ads status</div>
        </div>
    </div>

    <!-- SECTION 1: PROCESS & RAM DIAGNOSTICS -->
    <div class="section">
        <div class="section-title">Memory & process working set breakdown</div>
        <div class="section-desc">Top 15 processes by working set. Potential reclamation via 1-Click Trim: ~$estimatedReclaimMB MB.</div>

        <div class="progress-row">
            <span>Memory pressure</span>
            <span>$ramPercent%</span>
        </div>
        <div class="progress-bar-container">
            <div class="progress-bar-fill" style="width: $ramPercent%;"></div>
        </div>

        <table class="data-table">
            <thead>
                <tr>
                    <th>PID</th>
                    <th>Process</th>
                    <th>Working Set</th>
                    <th>Threads</th>
                    <th>Category</th>
                </tr>
            </thead>
            <tbody>
"@

foreach ($p in $topProcesses) {
    $wsMB = [math]::Round($p.WorkingSet64 / 1MB, 1)
    $catLabel = if ($p.ProcessName -in $protectedList) {
        "<span class='status status-info'>System core</span>"
    } elseif ($p.ProcessName -match 'chrome|edge|brave|discord|spotify|steam') {
        "<span class='status status-warn'>Helper / idle</span>"
    } else {
        "<span class='status status-clean'>User task</span>"
    }

    $html += @"
                <tr>
                    <td class="mono text-dim">$($p.Id)</td>
                    <td>$($p.ProcessName)</td>
                    <td class="mono">$wsMB MB</td>
                    <td class="mono text-dim">$($p.Threads.Count)</td>
                    <td>$catLabel</td>
                </tr>
"@
}

$html += @"
            </tbody>
        </table>
    </div>

    <!-- SECTION 2: WINDOWS BLOATWARE AUDIT -->
    <div class="section">
        <div class="section-title">Windows bloatware & sponsored package audit</div>
        <div class="section-desc">Pre-installed promotional applications, games, and telemetry stubs found on this installation.</div>

        <table class="data-table">
            <thead>
                <tr>
                    <th>Application</th>
                    <th>Package Identifier</th>
                    <th>Category</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
"@

foreach ($b in $bloatResults) {
    $statusLabel = if ($b.IsInstalled) {
        "<span class='status status-bloat'>Needs debloat</span>"
    } else {
        "<span class='status status-clean'>Clean</span>"
    }

    $html += @"
                <tr>
                    <td>$($b.Display)</td>
                    <td class="mono text-dim">$($b.Name)</td>
                    <td class="text-sub">$($b.Category)</td>
                    <td>$statusLabel</td>
                </tr>
"@
}

$html += @"
            </tbody>
        </table>
    </div>

    <!-- SECTION 3: PRIVACY & TELEMETRY AUDIT -->
    <div class="section">
        <div class="section-title">Privacy, telemetry & Start Menu adware audit</div>

        <table class="data-table">
            <thead>
                <tr>
                    <th>Component</th>
                    <th>Registry / Policy</th>
                    <th>Status</th>
                    <th>Recommendation</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>Windows diagnostic telemetry</td>
                    <td class="mono text-dim">HKLM:\...\DataCollection\AllowTelemetry</td>
                    <td><span class="status $(if($telemetryStatus -match 'ACTIVE'){'status-warn'}else{'status-clean'})">$telemetryStatus</span></td>
                    <td class="text-sub">Disable via menu option [8]</td>
                </tr>
                <tr>
                    <td>Advertising ID tracking</td>
                    <td class="mono text-dim">HKCU:\...\AdvertisingInfo\Enabled</td>
                    <td><span class="status $(if($advStatus -match 'ACTIVE'){'status-warn'}else{'status-clean'})">$advStatus</span></td>
                    <td class="text-sub">Disable via menu option [8]</td>
                </tr>
                <tr>
                    <td>Start Menu promoted apps & ads</td>
                    <td class="mono text-dim">HKCU:\...\ContentDeliveryManager</td>
                    <td><span class="status $(if($startAdsStatus -match 'ACTIVE'){'status-warn'}else{'status-clean'})">$startAdsStatus</span></td>
                    <td class="text-sub">Disable via menu option [8]</td>
                </tr>
                <tr>
                    <td>Bing web search in Start Menu</td>
                    <td class="mono text-dim">HKCU:\...\Explorer\DisableSearchBoxSuggestions</td>
                    <td><span class="status $(if($bingSearchStatus -match 'ACTIVE'){'status-warn'}else{'status-clean'})">$bingSearchStatus</span></td>
                    <td class="text-sub">Disable to speed up local search</td>
                </tr>
            </tbody>
        </table>
    </div>

    <!-- SECTION 4: BACKGROUND SERVICES & POWER OPTIMIZATION -->
    <div class="section">
        <div class="section-title">Background services & power profile audit</div>
        <div class="section-desc">Active power scheme: <strong>$activePowerPlan</strong></div>

        <table class="data-table">
            <thead>
                <tr>
                    <th>Service</th>
                    <th>Description</th>
                    <th>State</th>
                    <th>Startup Type</th>
                </tr>
            </thead>
            <tbody>
"@

foreach ($s in $servicesResults) {
    $stateLabel = if ($s.Status -eq "Running") {
        if ($s.IsHeavy) { "<span class='status status-warn'>Running (telemetry)</span>" } else { "<span class='status status-info'>Running</span>" }
    } else {
        "<span class='status status-clean'>Stopped</span>"
    }

    $html += @"
                <tr>
                    <td class="mono">$($s.Name)</td>
                    <td class="text-sub">$($s.Display)</td>
                    <td>$stateLabel</td>
                    <td class="mono text-dim">$($s.StartType)</td>
                </tr>
"@
}

$html += @"
            </tbody>
        </table>
    </div>

    <!-- SECTION 5: SECRET-OPTIMIZER ACTION ROADMAP -->
    <div class="section">
        <div class="section-title">Recommended actions</div>

        <div class="action-list">
            <div class="action-item">
                <div class="action-num">1</div>
                <div>
                    <div class="action-text">Run 1-Click Deep RAM Optimizer</div>
                    <div class="action-sub">Reclaim ~$estimatedReclaimMB MB RAM (menu option [1])</div>
                </div>
            </div>

            <div class="action-item">
                <div class="action-num">2</div>
                <div>
                    <div class="action-text">Run Safe 1-Click Bloatware Debloat</div>
                    <div class="action-sub">Purge $detectedBloatCount detected promo packages (menu option [6])</div>
                </div>
            </div>

            <div class="action-item">
                <div class="action-num">3</div>
                <div>
                    <div class="action-text">Apply Privacy & Telemetry Purge</div>
                    <div class="action-sub">Turn off Start Menu ads & tracking (menu option [8])</div>
                </div>
            </div>

            <div class="action-item">
                <div class="action-num">4</div>
                <div>
                    <div class="action-text">Enable Continuous Smart RAM Guard</div>
                    <div class="action-sub">Prevent background memory buildup (menu option [5])</div>
                </div>
            </div>
        </div>
    </div>

    <!-- FOOTER -->
    <div class="footer">
        Generated by Secret-Optimizer &bull; mrsecret_official &bull; All diagnostics evaluated locally
        <div style="margin-top:4px;">Report date: $reportDate</div>
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
