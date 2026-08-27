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

**Secret-Optimizer** is an advanced, lightweight Windows optimization, RAM management, recovery, and debloating suite.

## PERSONAL USE ONLY
This tool is for **PERSONAL USE ONLY** on your own devices.

---

## Key Features

### 🚀 1. Intelligent RAM Cleaner & Working Set Optimizer
- **Safe Working Set Trimming**: Utilizes native Win32 `psapi.dll!EmptyWorkingSet` to safely trim idle and unnecessary background process memory without closing applications or causing crashes.
- **Protected System Processes**: Automatically whitelists and shields critical Windows components (`System`, `csrss`, `dwm`, `services`, `lsass`, `SecurityHealthService`, etc.) and the active foreground user application.
- **Standby Cache & Garbage Collection Flush**: Purges modified memory lists and reclaims physical RAM instantly with before/after statistics.
- **Process RAM Inspector**: Interactive monitor displaying top RAM consumers with real-time memory usage and per-process trimming.
- **Continuous RAM Guard**: Optional background watcher that automatically triggers memory optimizations when RAM usage exceeds a set threshold (e.g. 80%).

### 🛡️ 2. Safe Windows Bloatware Remover
- **Automatic System Restore Point**: Creates a rollback checkpoint before removing any packages or modifying settings.
- **Safe 1-Click Recommended Debloat**: Eliminates pre-installed promotional bloatware, sponsored junk, adware stubs (TikTok, Candy Crush, Disney+, Spotify stub, Feedback Hub, Bing Weather/News/Finance, Clipchamp, etc.).
- **Provisioned System-wide Cleanup**: Removes packages from both current user profile and provisioned image (`Remove-AppxProvisionedPackage`) so they never reinstall after Windows updates.
- **Xbox & Gaming Bloatware Remover**: Optional debloating of Xbox overlays and background captures for non-gaming environments.
- **Privacy & Telemetry Purge**: Safely disables Windows diagnostic data collection, advertising ID, Bing Start menu web search, and promotional suggestions via registry.
- **Interactive AppX Package Manager**: Scan, review, and selectively uninstall specific user packages with protection badges.

### 🛠️ 3. Complete Windows Recovery & Repair Suite
- **Guided Intelligent System Diagnosis**: Comprehensive scan of boot integrity, memory pressure, disk space, DISM component store, network stack, and core kernel files.
- **Startup / SrtTrail.txt / BCD Repair**: Rebuilds bootloader files (`bcdboot`), fixes boot sectors (`bootrec`), disables automatic repair infinite boot loops, and inspects `SrtTrail.txt`.
- **Deep System Files & Image Repair**: Runs SFC (`sfc /scannow`) and DISM component store restoration (`DISM /Online /Cleanup-Image /RestoreHealth`).
- **Disk & Bad Sector Repair**: Schedules offline CHKDSK scans for NTFS filesystem integrity.
- **Network, DNS & Sockets Full Repair**: Resets Winsock, TCP/IP stack, DNS cache, and firewall rules.
- **Windows Update Clean & Reset**: Flushes corrupted `SoftwareDistribution` and `Catroot2` caches and re-registers update DLLs.
- **Health Report Generator**: Generates a rich HTML report with dark mode aesthetics and detailed hardware/software metrics.
- **System Restore & BitLocker**: Manage restore points and view BitLocker volume recovery passwords.

---

## Installation & Setup

Execute **`Setup-Tools.bat`**:

```cmd
Setup-Tools.bat
```

The installer:
- Deploys the package to `%USERPROFILE%\Tools`.
- Registers both `secret-optimizer` and `secret-tools` into your system `PATH`.
- Creates a Desktop shortcut (`Secret-Optimizer.lnk`).
- Verifies integrity and checks for updates automatically.

---

## Usage from Any Terminal

Once installed, open any PowerShell or Command Prompt terminal and type:

```cmd
secret-optimizer
```
*(or `secret-tools` for backwards compatibility)*

Windows will prompt for Administrator elevation (UAC) once per launch to allow deep optimization and repair capabilities.

---

## Updating

Running `Setup-Tools.bat` (or launching `secret-optimizer`, which checks in the background) automatically detects and deploys updates from the repository.

---

## Security Notes

- **No telemetry or data collection**: All operations run 100% locally on your machine.
- **Restore Point Safety**: System Restore checkpoints are generated before applying system changes or package debloating.
- **Clean and Transparent**: All source code is open and readable in batch and PowerShell scripts.
