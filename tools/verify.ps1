param([switch]$Render)
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$godot = Join-Path $project 'Godot_v4.7-stable_win64_console.exe'

function Invoke-CheckedGodot([string[]]$GodotArgs) {
    $output = & $godot --path $project @GodotArgs 2>&1
    $exitCode = $LASTEXITCODE
    $output | ForEach-Object { Write-Host $_ }
    if ($exitCode -ne 0 -or ($output -match 'SCRIPT ERROR:|ERROR:')) {
        throw "Godot verification failed (exit $exitCode)."
    }
}

Invoke-CheckedGodot @('--headless', '--editor', '--import')
Invoke-CheckedGodot @('--headless', '--quit-after', '10')
Invoke-CheckedGodot @('--headless', '--script', 'res://tests/run_tests.gd')
if ($Render) {
    Invoke-CheckedGodot @('--resolution', '1280x720', '--script', 'res://tests/render_check.gd')
}
