[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$source = [Drawing.Image]::FromFile((Join-Path $PSScriptRoot 'provisions-icon-master.png'))
$bitmap = [Drawing.Bitmap]::new(64,64,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [Drawing.Graphics]::FromImage($bitmap)
try {
    $graphics.Clear([Drawing.Color]::Transparent)
    $graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.DrawImage($source,[Drawing.Rectangle]::new(0,0,64,64))
    $target = Join-Path $root 'Contents/mods/B47ANCEDProvisions/42/icon.png'
    $bitmap.Save($target,[Drawing.Imaging.ImageFormat]::Png)
    Write-Output 'Exported 64x64 transparent mod icon; thumbnail files were not touched.'
} finally {
    $graphics.Dispose(); $bitmap.Dispose(); $source.Dispose()
}
