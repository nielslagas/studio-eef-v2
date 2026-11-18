# Snijdt verticale plakken uit een full-page screenshot (voor visuele inspectie).
# Gebruik: pwsh _vision/crop-png.ps1 -Src <png> -Top <px> -Height <px> -Out <png>
param(
  [Parameter(Mandatory=$true)][string]$Src,
  [Parameter(Mandatory=$true)][int]$Top,
  [Parameter(Mandatory=$true)][int]$Height,
  [Parameter(Mandatory=$true)][string]$Out
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile((Resolve-Path $Src))
try {
  $h = [Math]::Min($Height, $img.Height - $Top)
  $bmp = New-Object System.Drawing.Bitmap($img.Width, $h)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.DrawImage($img,
    (New-Object System.Drawing.Rectangle(0, 0, $img.Width, $h)),
    (New-Object System.Drawing.Rectangle(0, $Top, $img.Width, $h)),
    [System.Drawing.GraphicsUnit]::Pixel)
  $g.Dispose()
  $bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  "$Out ($($img.Width)x$h)"
} finally { $img.Dispose() }
