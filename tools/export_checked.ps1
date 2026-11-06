param(
    [Parameter(Mandatory=$true)][string]$Output,
    [switch]$Pack,
    [string]$Preset = 'Windows Desktop',
    [string]$Godot = ''
)
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
if (-not $Godot) { $Godot = Join-Path $project 'Godot_v4.7.2-stable_win64_console.exe' }
$target = [System.IO.Path]::GetFullPath($Output)
if (Test-Path -LiteralPath $target) { throw "Existing output left untouched: $target" }
$extension = if ($Pack) { '.pck' } else { '.exe' }
if ([System.IO.Path]::GetExtension($target) -ne $extension) { throw "Choose a new $extension output file." }
$targetPack = [System.IO.Path]::ChangeExtension($target, '.pck')
if (-not $Pack -and (Test-Path -LiteralPath $targetPack)) { throw "Existing PCK left untouched: $targetPack" }
$stage = Join-Path $project ('builds/validation/checked-export-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage | Out-Null

function Invoke-Godot([string[]]$Arguments) {
    $text = & $Godot --headless --path $project @Arguments 2>&1
    $code = $LASTEXITCODE
    $text | ForEach-Object { Write-Host $_ }
    if ($code -ne 0 -or ($text -match 'SCRIPT ERROR:|ERROR:')) { throw "Checked export stopped (Godot exit $code)." }
}

$before = Join-Path $stage 'before.json'
Invoke-Godot @('--script', 'res://tools/check_level_exports.gd', '--', '--report', $before)
$snapshot = Get-Content -LiteralPath $before -Raw | ConvertFrom-Json
$stagedFile = Join-Path $stage ('Cinderkeep' + $extension)
$mode = if ($Pack) { '--export-pack' } else { '--export-release' }
Invoke-Godot @($mode, $Preset, $stagedFile)
$after = Join-Path $stage 'after.json'
Invoke-Godot @('--script', 'res://tools/check_level_exports.gd', '--', '--report', $after)
$current = Get-Content -LiteralPath $after -Raw | ConvertFrom-Json
if ($snapshot.signature -ne $current.signature) { throw 'Maps changed during export. Staged output retained; no final output published.' }
if (-not (Test-Path -LiteralPath $stagedFile)) { throw 'Exporter did not create its staged artifact.' }
$copies = @(@{Source=$stagedFile; Target=$target})
if (-not $Pack) {
    $stagedPack = [System.IO.Path]::ChangeExtension($stagedFile, '.pck')
    if (-not (Test-Path -LiteralPath $stagedPack)) { throw 'Exporter did not create its staged PCK.' }
    $copies += @{Source=$stagedPack; Target=$targetPack}
}
foreach ($copy in $copies) { if (Test-Path -LiteralPath $copy.Target) { throw "Existing output left untouched: $($copy.Target)" } }
New-Item -ItemType Directory -Force -Path ([System.IO.Path]::GetDirectoryName($target)) | Out-Null
# .NET's non-overwriting copy refuses a destination created concurrently.
foreach ($copy in $copies) { [System.IO.File]::Copy($copy.Source, $copy.Target, $false) }
Write-Host "Checked export published: $target"
