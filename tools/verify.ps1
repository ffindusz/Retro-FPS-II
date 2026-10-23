param([switch]$Render)
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$godot = Join-Path $project 'Godot_v4.7.2-stable_win64_console.exe'

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
Invoke-CheckedGodot @('--headless', '--script', 'res://tests/test_runtime_warden.gd')
Invoke-CheckedGodot @('--headless', '--script', 'res://tests/test_warden_motion.gd')
Invoke-CheckedGodot @('--headless', '--script', 'res://tests/test_warden_rig.gd')
Invoke-CheckedGodot @('--headless', '--script', 'res://tests/test_warden_ab.gd')
Invoke-CheckedGodot @('--headless', '--script', 'res://tests/test_warden_candidates.gd')
Invoke-CheckedGodot @('--headless', '--script', 'res://tests/test_warden_pilot.gd')
if ($Render) {
    Invoke-CheckedGodot @('--resolution', '1280x720', '--script', 'res://tools/capture_runtime_warden.gd')
    Invoke-CheckedGodot @('--resolution', '1280x720', '--script', 'res://tests/render_check.gd')
    Invoke-CheckedGodot @('--resolution', '1280x720', '--script', 'res://tools/capture_warden_motion.gd')
    Invoke-CheckedGodot @('--resolution', '1280x720', '--script', 'res://tools/capture_warden_rig.gd')
    Invoke-CheckedGodot @('--resolution', '1280x720', '--script', 'res://tools/capture_warden_ab.gd')
    Invoke-CheckedGodot @('--resolution', '1280x720', '--script', 'res://tools/capture_warden_candidates.gd')
    Invoke-CheckedGodot @('--resolution', '1280x720', '--script', 'res://tools/capture_warden_pilot.gd')
}
