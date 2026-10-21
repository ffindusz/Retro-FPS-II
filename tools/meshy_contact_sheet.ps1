param(
    [string]$SourceDirectory = "$env:LOCALAPPDATA/Temp/opencode/cinderkeep-meshy-2026-10-20",
    [ValidateSet('preview', 'textured')][string]$Stage = 'textured'
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$ids = @('weapon-cleaver', 'weapon-staff', 'enemy-warden', 'enemy-adept', 'prop-torch', 'prop-urn')
$bitmap = [System.Drawing.Bitmap]::new(1536, 1120)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$font = [System.Drawing.Font]::new('Segoe UI', 15)
$brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(225, 210, 175))
try {
    $graphics.Clear([System.Drawing.Color]::FromArgb(18, 23, 30))
    for ($index = 0; $index -lt $ids.Count; $index++) {
        $image = [System.Drawing.Image]::FromFile((Join-Path $SourceDirectory "$($ids[$index])/$Stage.png"))
        try {
            $x = ($index % 3) * 512
            $y = [math]::Floor($index / 3) * 560
            $graphics.DrawImage($image, [int]$x, [int]$y, 512, 512)
            $graphics.DrawString($ids[$index], $font, $brush, [single]($x + 20), [single]($y + 520))
        } finally { $image.Dispose() }
    }
    $path = Join-Path $SourceDirectory "contact-sheet-$Stage.png"
    $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output $path
} finally {
    $brush.Dispose()
    $font.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}
