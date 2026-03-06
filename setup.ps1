# setup.ps1 - One-step build setup for LibraTrack (Windows / PowerShell)
# Usage:  .\setup.ps1
#
# Prerequisites (install once):
#   - CMake   : https://cmake.org/download/  (add to PATH during install)
#   - A C++17 compiler:
#       Visual Studio 2019+  OR  MinGW-w64 via MSYS2  OR  WSL/Git Bash
#   - Git     : https://git-scm.com

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "+======================================+" -ForegroundColor Cyan
Write-Host "|       LibraTrack - Setup             |" -ForegroundColor Cyan
Write-Host "+======================================+" -ForegroundColor Cyan
Write-Host ""

# -- Helper: install a package via winget -------------------------------------------
function Install-WingetPackage {
    param([string]$Name, [string]$WingetId)
    Write-Host "  Installing $Name via winget..." -ForegroundColor Yellow
    winget install --id $WingetId --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [X] Failed to install $Name automatically." -ForegroundColor Red
        Write-Host "      Please install it manually and re-run setup.ps1" -ForegroundColor Red
        exit 1
    }
    # Refresh PATH in the current session
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("PATH", "User")
    Write-Host "  [OK] $Name installed." -ForegroundColor Green
}

# -- Dependency checks (auto-install if missing) ------------------------------------
if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "  [!] winget not found - cannot auto-install dependencies." -ForegroundColor Yellow
    Write-Host "      Please install CMake and Git manually, then re-run setup.ps1" -ForegroundColor Yellow
    Write-Host "      CMake : https://cmake.org/download/" -ForegroundColor White
    Write-Host "      Git   : https://git-scm.com" -ForegroundColor White
    exit 1
}

foreach ($entry in @(
    @{ Tool = "cmake"; WingetId = "Kitware.CMake"    },
    @{ Tool = "git";   WingetId = "Git.Git"          }
)) {
    if (!(Get-Command $entry.Tool -ErrorAction SilentlyContinue)) {
        Write-Host "  [X] Missing: $($entry.Tool)" -ForegroundColor Red
        Install-WingetPackage -Name $entry.Tool -WingetId $entry.WingetId
    } else {
        $path = (Get-Command $entry.Tool).Source
        Write-Host "  [OK] Found: $($entry.Tool)  ($path)" -ForegroundColor Green
    }
}
Write-Host ""

# -- CMake configure -----------------------------------------------------------------
Write-Host "[1/2] Configuring build..." -ForegroundColor White
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
if ($LASTEXITCODE -ne 0) {
    Write-Host "CMake configure failed." -ForegroundColor Red
    exit 1
}
Write-Host ""

# -- Build ---------------------------------------------------------------------------
Write-Host "[2/2] Building..." -ForegroundColor White
cmake --build build --config Debug
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "  [OK] Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  Run the test for a specific issue:" -ForegroundColor White
Write-Host "    .\check.ps1 [issue-number]" -ForegroundColor Cyan
Write-Host "  Examples:" -ForegroundColor White
Write-Host "    .\check.ps1 1    - tests your fix for Issue #01" -ForegroundColor Cyan
Write-Host "    .\check.ps1 42   - tests your fix for Issue #42" -ForegroundColor Cyan
Write-Host ""
