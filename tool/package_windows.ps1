# PowerShell script to build & package the Windows release
param (
    [string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"

Write-Host "`n===============================================" -ForegroundColor Cyan
Write-Host " Building & Packaging Windows App (v$Version)  " -ForegroundColor Cyan
Write-Host "===============================================`n" -ForegroundColor Cyan

# 1. Flutter release build
Write-Host "--> Running 'flutter build windows --release'..." -ForegroundColor Yellow
flutter build windows --release

$releaseDir = "build\windows\x64\runner\Release"
$distDir = "build\windows\dist"

if (-not (Test-Path $releaseDir)) {
    Write-Error "Release build not found in $releaseDir"
    exit 1
}

# Ensure dist directory exists
if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Force -Path $distDir | Out-Null
}

# 2. Create Portable Zip
$zipName = "Quran-Windows-x64-v$Version.zip"
$zipPath = "$distDir\$zipName"
Write-Host "`n--> Creating Portable ZIP: $zipPath..." -ForegroundColor Yellow
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path "$releaseDir\*" -DestinationPath $zipPath -Force
Write-Host "--> Created $zipName successfully!" -ForegroundColor Green

# 3. Check for Inno Setup compiler to create Setup.exe
$isccPaths = @(
    "iscc",
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe",
    "C:\Program Files (x86)\Inno Setup 5\ISCC.exe"
)

$iscc = $null
foreach ($p in $isccPaths) {
    if (Get-Command $p -ErrorAction SilentlyContinue) {
        $iscc = $p
        break
    } elseif (Test-Path $p) {
        $iscc = $p
        break
    }
}

if ($iscc) {
    Write-Host "`n--> Found Inno Setup compiler: $iscc" -ForegroundColor Yellow
    Write-Host "--> Compiling Windows Setup Installer (Quran-Setup-v$Version.exe)..." -ForegroundColor Yellow
    & $iscc "tool\installer.iss"
    Write-Host "--> Setup installer created in $distDir!" -ForegroundColor Green
} else {
    Write-Host "`n[Note] Inno Setup compiler (ISCC.exe) was not found." -ForegroundColor DarkYellow
    Write-Host "       To build a single 'Quran-Setup.exe' wizard, install Inno Setup (free) from: https://jrsoftware.org/isdl.php" -ForegroundColor DarkYellow
    Write-Host "       The portable zip is ready to upload: $distDir\$zipName" -ForegroundColor Green
}

Write-Host "`n===============================================" -ForegroundColor Green
Write-Host " Done! Files ready to upload in $distDir:     " -ForegroundColor Green
Get-ChildItem -Path $distDir | ForEach-Object {
    Write-Host ("  - " + $_.Name + " (" + [math]::Round($_.Length / 1MB, 2) + " MB)") -ForegroundColor White
}
Write-Host "===============================================`n" -ForegroundColor Green
