# Restwise build helper.
#   .\scripts\rw.ps1 build   -> compile the app (bin\Restwise.prg)
#   .\scripts\rw.ps1 run     -> compile, start simulator if needed, launch on Fenix 7 Pro
#   .\scripts\rw.ps1 test    -> compile unit tests and run them in the simulator
param([ValidateSet("build", "run", "test")][string]$Cmd = "build")

$ErrorActionPreference = "Stop"
$root    = Split-Path -Parent $PSScriptRoot
$proj    = Join-Path $root "Restwise"
$bin     = Join-Path $proj "bin"
$device  = "fenix7pro"
$key     = Join-Path $env:USERPROFILE ".connectiq\developer_key.der"
$sdkDir  = (Get-Content (Join-Path $env:APPDATA "Garmin\ConnectIQ\current-sdk.cfg") -Raw).Trim()
$monkeyc = Join-Path $sdkDir "bin\monkeyc.bat"
$monkeydo= Join-Path $sdkDir "bin\monkeydo.bat"
$sim     = Join-Path $sdkDir "bin\simulator.exe"

New-Item -ItemType Directory -Force $bin | Out-Null

function Ensure-Simulator {
    if (-not (Get-Process simulator -ErrorAction SilentlyContinue)) {
        Start-Process $sim
        Start-Sleep -Seconds 5
    }
}

switch ($Cmd) {
    "build" {
        & $monkeyc -f (Join-Path $proj "monkey.jungle") -d $device -o (Join-Path $bin "Restwise.prg") -y $key -w
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    "run" {
        & $monkeyc -f (Join-Path $proj "monkey.jungle") -d $device -o (Join-Path $bin "Restwise.prg") -y $key -w
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        Ensure-Simulator
        & $monkeydo (Join-Path $bin "Restwise.prg") $device
    }
    "test" {
        & $monkeyc -f (Join-Path $proj "monkey.jungle") -d $device -o (Join-Path $bin "RestwiseTest.prg") -y $key -w --unit-test
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        Ensure-Simulator
        & $monkeydo (Join-Path $bin "RestwiseTest.prg") $device /t
    }
}
