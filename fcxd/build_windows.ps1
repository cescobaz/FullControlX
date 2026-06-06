# Build FullControlX driver (fcxd) on Windows using vcpkg for json-c.
#
# Dependencies are declared in vcpkg.json (manifest mode) and installed
# automatically by vcpkg during the CMake configure step.
#
# Usage (from a PowerShell prompt in the fcxd directory):
#   .\build_windows.ps1
#
# Optional parameters:
#   -VcpkgRoot   Path to an existing vcpkg checkout (default: <repo>\_build\vcpkg).
#   -Triplet     vcpkg triplet (default: x64-mingw-static). Use x64-windows-static for MSVC.
#   -Generator   CMake generator (default: "MinGW Makefiles"). Use a Visual Studio
#                generator together with an x64-windows-static triplet for MSVC builds.
#   -BuildType   CMake build type (default: Release).

param(
    [string]$VcpkgRoot,
    [string]$Triplet   = "x64-mingw-static",
    [string]$Generator = "MinGW Makefiles",
    [string]$BuildType = "Release"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$buildDir  = Join-Path $scriptDir "_build"

if (-not $VcpkgRoot) {
    $VcpkgRoot = Join-Path $buildDir "vcpkg"
}

# 1. Get vcpkg (clone + bootstrap if not present).
if (-not (Test-Path (Join-Path $VcpkgRoot "vcpkg.exe"))) {
    if (-not (Test-Path $VcpkgRoot)) {
        Write-Host "Cloning vcpkg into $VcpkgRoot ..."
        git clone https://github.com/microsoft/vcpkg $VcpkgRoot
    }
    Write-Host "Bootstrapping vcpkg ..."
    & (Join-Path $VcpkgRoot "bootstrap-vcpkg.bat") -disableMetrics
}

$toolchain = Join-Path $VcpkgRoot "scripts\buildsystems\vcpkg.cmake"

# 2. Configure and build with CMake. In manifest mode vcpkg reads vcpkg.json
#    and installs json-c automatically during this configure step.
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

Write-Host "Configuring CMake ($Generator, $Triplet, $BuildType) ..."
cmake -S $scriptDir -B $buildDir `
    -G $Generator `
    -DCMAKE_BUILD_TYPE=$BuildType `
    -DCMAKE_TOOLCHAIN_FILE="$toolchain" `
    -DVCPKG_TARGET_TRIPLET=$Triplet

Write-Host "Building ..."
cmake --build $buildDir --config $BuildType

Write-Host ""
Write-Host "Done. Executable is in $buildDir"
