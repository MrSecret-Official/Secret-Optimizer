# Secret-Optimizer

```
   ____                      _          ___        _   _           _              
  / ___|  ___  ___ _ __ ___| |_       / _ \ _ __ | |_(_)_ __ ___ (_)_______ _ __  
  \___ \ / _ \/ __| '__/ _ \ __|_____| | | | '_ \| __| | '_ ` _ \| |_  / _ \ '__|
   ___) |  __/ (__| | |  __/ |_|_____| |_| | |_) | |_| | | | | | | |/ /  __/ |    
  |____/ \___|\___|_|  \___|\__|      \___/| .__/ \__|_|_| |_| |_|_/___\___|_|    
                                           |_|                                    
                               Made by: mrsecret_official
```

**Secret-Optimizer** is an advanced, high-performance Windows Process, Memory, and System Optimizer paired with a safe, controlled Windows Bloatware Remover.

## PERSONAL USE ONLY
This tool is for **PERSONAL USE ONLY** on your own devices.

---

## Key Modules & Capabilities

### ⚡ 1. Complete Process & Memory Optimizer
- **1-Click Deep RAM Working Set Purge**: Utilizes native Win32 `psapi.dll!EmptyWorkingSet` and `kernel32.dll!SetProcessWorkingSetSize` to flush clean pages back to cache and shrink background process memory footprints without terminating processes or causing crashes.
- **Protected Core OS Process Shield**: Hardcoded protection for critical Windows processes (`System`, `csrss`, `dwm`, `services`, `lsass`, `winlogon`, `explorer`, `pwsh`, `cmd`, `taskmgr`, `MsMpEng`, `SecurityHealthService`, etc.).
- **Active Foreground Window Protection**: Dynamically identifies the currently focused application (`user32.dll!GetForegroundWindow`) to ensure active gaming or creative work is never interrupted.
- **Real-Time Process Monitor & Performance Booster**: Real-time process explorer with live memory usage, thread count, CPU priority control (High / AboveNormal / Normal / BelowNormal / Idle), and frozen task termination.
- **Idle Helper & Subprocess Freezer**: Scans and cleans multi-process background renderers (Chrome, Edge, Brave, Opera, Discord, Spotify, Slack, Steam WebHelper, Epic Games background web helpers) that silently hoard memory.
- **Gaming & Heavy Workload Turbo Mode**: 1-click optimization that boosts foreground game CPU priority to `HIGH`, sets background updaters/helpers to `BELOW NORMAL`, and activates High/Ultimate Performance power plans.
- **Continuous Smart RAM & Process Guard**: Background daemon loop that monitors RAM usage every 5 seconds and auto-trims background working sets whenever load exceeds the configured threshold (default 75%).

### 🛡️ 2. Controlled & Safe Windows Bloatware Remover
- **Automatic System Restore Point**: Generates a rollback checkpoint (`Checkpoint-Computer`) before removing any packages or modifying settings.
- **Safe 1-Click Recommended Debloat**: Eliminates pre-installed promotional bloatware, sponsored junk, adware stubs (`TikTok`, `Candy Crush`, `Disney+`, `Spotify stub`, `Netflix stub`, `Feedback Hub`, `Bing Weather/News/Finance/Sports`, `Clipchamp`, `Solitaire`, `Tips`, `Get Help`, `Mixed Reality`, etc.).
- **Provisioned System-wide Cleanup**: Removes packages from both current user profile (`Remove-AppxPackage`) AND provisioned system image (`Remove-AppxProvisionedPackage -Online`) so apps never reinstall after Windows updates or for new user profiles.
- **Controlled Custom AppX Package Manager**: Interactive package inspector with status badges (`[RECOMMENDED REMOVAL]`, `[OPTIONAL USER APP]`, `[SYSTEM PROTECTED]`) allowing selective uninstallation by index ranges or search filters.
- **Windows Telemetry, Privacy & Start Menu Adware Purge**: Disables diagnostic data collection, advertising ID, Bing Start menu web search suggestions, activity history, and promoted apps installations via registry.
- **Windows Non-Essential Background Services Optimizer**: Safe tuning presets to disable `DiagTrack`, `dmwappushservice`, `MapsBroker`, `RemoteRegistry`, and `RetailDemo`.
- **Default Apps & Package Recovery Center**: 1-click re-registration commands to restore built-in Microsoft Store applications if ever needed.

### 📊 3. System Health & Performance Diagnostics
- **Comprehensive HTML Performance Report**: Generates a rich, dark-mode dashboard showing CPU, RAM, storage volumes, services, and hardware metrics.
- **System Restore Point Manager**: List, create, or roll back to any system restore point.

---

## Installation & Setup

Execute **`Optimizer_Setup.bat`**:

```cmd
Optimizer_Setup.bat
```

The installer:
- Deploys the package to `%USERPROFILE%\Secret-Optimizer`.
- Registers `secret-optimizer` into your system `PATH`.
- Creates a Desktop shortcut (`Secret-Optimizer.lnk`).
- Verifies integrity and launches Secret-Optimizer directly.

---

## Usage from Any Terminal

Once installed, open any PowerShell or Command Prompt terminal and type:

```cmd
secret-optimizer
```

Windows will prompt for Administrator elevation (UAC) once per launch to allow deep process management and optimization capabilities.

---

## Security & Privacy Notes

- **100% Local & Transparent**: All scripts run locally on your machine. No telemetry, analytics, or external data transmission.
- **Safe by Design**: System Restore checkpoints are generated before applying debloat or system changes.
- **Zero Antivirus Conflicts**: Uses native Win32 APIs and official PowerShell cmdlets.
