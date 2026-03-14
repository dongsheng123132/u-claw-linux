# ============================================================
#  U-Claw Bootable USB - Step 3: Create Persistence Image
#  Creates persistence.dat for Ventoy
# ============================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  U-Claw Bootable USB - Step 3: Persistence" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ── Config ──
$CacheDir = Join-Path $PSScriptRoot ".download-cache"
$PersistencePath = Join-Path $CacheDir "persistence.dat"
$DefaultSizeGB = 20

if (-not (Test-Path $CacheDir)) {
    New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null
}

# ── Check if persistence.dat already exists ──
if (Test-Path $PersistencePath) {
    $existingSize = [math]::Round((Get-Item $PersistencePath).Length / 1GB, 1)
    Write-Host "[INFO] persistence.dat already exists (${existingSize} GB)." -ForegroundColor Yellow
    $overwrite = Read-Host "Recreate it? (y/N)"
    if ($overwrite -ne "y" -and $overwrite -ne "Y") {
        Write-Host "[OK]   Using existing persistence.dat." -ForegroundColor Green
        Write-Host "       Next: Run .\4-copy-to-usb.ps1" -ForegroundColor Cyan
        Read-Host "Press Enter to continue"
        exit 0
    }
    Remove-Item -Path $PersistencePath -Force
}

# ── Detect usable WSL distro (must have bash + mkfs.ext4) ──
$wslDistro = $null
try {
    $distros = (wsl --list --quiet 2>$null) -replace "`0","" | Where-Object { $_.Trim() -ne "" -and $_ -notmatch "docker" }
    foreach ($d in $distros) {
        $d = $d.Trim()
        if ($d) {
            $testResult = wsl -d $d -- sh -c "command -v mkfs.ext4 && echo HASEXT4" 2>$null
            if ($testResult -match "HASEXT4") {
                $wslDistro = $d
                break
            }
        }
    }
} catch {}

if ($wslDistro) {
    # ── Method A: Use WSL distro to create ext4 image ──
    Write-Host "[INFO] Usable WSL distro found: $wslDistro" -ForegroundColor Green
    Write-Host ""

    $sizeInput = Read-Host "Persistence size in GB (default: $DefaultSizeGB for 32GB USB)"
    if ([string]::IsNullOrWhiteSpace($sizeInput)) {
        $sizeGB = $DefaultSizeGB
    } else {
        $sizeGB = [int]$sizeInput
    }

    if ($sizeGB -lt 1 -or $sizeGB -gt 28) {
        Write-Host "[ERROR] Size must be between 1 and 28 GB." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }

    Write-Host "[INFO] Creating ${sizeGB} GB ext4 image via WSL..." -ForegroundColor Yellow

    $sizeMB = $sizeGB * 1024
    $tmpFile = "/tmp/uclaw_persistence.dat"

    wsl -d $wslDistro -- sh -c "rm -f $tmpFile; dd if=/dev/zero of=$tmpFile bs=1M count=0 seek=$sizeMB 2>/dev/null; mkfs.ext4 -F -L casper-rw $tmpFile 2>/dev/null; echo DONE"

    # Copy out via \\wsl$
    $wslNetPath = "\\wsl$\$wslDistro\tmp\uclaw_persistence.dat"
    if (Test-Path $wslNetPath) {
        Write-Host "[INFO] Copying from WSL to cache..." -ForegroundColor Yellow
        Copy-Item -Path $wslNetPath -Destination $PersistencePath -Force
        wsl -d $wslDistro -- rm -f $tmpFile
    }

    if (Test-Path $PersistencePath) {
        $actualSize = [math]::Round((Get-Item $PersistencePath).Length / 1GB, 1)
        Write-Host "[OK]   Created ${actualSize} GB persistence image." -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Failed to create persistence image via WSL." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }

} else {
    # ── Method B: Create raw file with PowerShell, format in Linux later ──
    Write-Host "[INFO] No usable WSL distro (only docker-desktop found or none)." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Will create a raw persistence image file." -ForegroundColor White
    Write-Host "  It will be formatted automatically on first Linux boot." -ForegroundColor White
    Write-Host ""

    $sizeInput = Read-Host "Persistence size in GB (default: $DefaultSizeGB for 32GB USB)"
    if ([string]::IsNullOrWhiteSpace($sizeInput)) {
        $sizeGB = $DefaultSizeGB
    } else {
        $sizeGB = [int]$sizeInput
    }

    if ($sizeGB -lt 1 -or $sizeGB -gt 28) {
        Write-Host "[ERROR] Size must be between 1 and 28 GB." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }

    Write-Host "[INFO] Creating ${sizeGB} GB sparse file (fast, only allocates on write)..." -ForegroundColor Yellow

    # Create sparse file using .NET (instant, doesn't write zeros)
    $sizeBytes = [int64]$sizeGB * 1024 * 1024 * 1024
    $fs = [System.IO.File]::Create($PersistencePath)
    $fs.SetLength($sizeBytes)
    $fs.Close()

    if (Test-Path $PersistencePath) {
        Write-Host "[OK]   Created ${sizeGB} GB persistence file." -ForegroundColor Green
        Write-Host ""
        Write-Host "  IMPORTANT: After first boot into Linux, run this to format it:" -ForegroundColor Yellow
        Write-Host '  sudo mkfs.ext4 -F -L casper-rw /media/*/Ventoy/persistence.dat' -ForegroundColor White
        Write-Host '  Then reboot for persistence to take effect.' -ForegroundColor White
    } else {
        Write-Host "[ERROR] Failed to create persistence file." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

Write-Host ""
Write-Host "[OK]   Step 3 complete! Persistence image created." -ForegroundColor Green
Write-Host "       Path: $PersistencePath" -ForegroundColor White
Write-Host ""
Write-Host "       Next: Run .\4-copy-to-usb.ps1" -ForegroundColor Cyan
Read-Host "Press Enter to continue"
