# Rekent het contrast na van tekst over een beeld (foto of video-frame).
# Zoekt in het opgegeven gebied de LICHTSTE achtergrondpixel (pixels die geen
# tekst zijn) en vergelijkt die met de opgegeven tekstkleur. Zo krijg je het
# slechtste geval, niet het gemiddelde.
#
# Gebruik:
#   powershell -File _vision/contrast-check.ps1 -Image x.png -X 40 -Y 180 -W 520 -H 240 -TekstKleur FAF8F4
param(
  [Parameter(Mandatory=$true)][string]$Image,
  [Parameter(Mandatory=$true)][int]$X,
  [Parameter(Mandatory=$true)][int]$Y,
  [Parameter(Mandatory=$true)][int]$W,
  [Parameter(Mandatory=$true)][int]$H,
  [string]$TekstKleur = 'FAF8F4',
  [double]$TekstDrempel = 0.55   # pixels boven deze luminantie gelden als tekst
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

function Luminantie([int]$r, [int]$g, [int]$b) {
  $kanaal = {
    param($c)
    $s = $c / 255.0
    if ($s -le 0.03928) { return $s / 12.92 }
    return [Math]::Pow(($s + 0.055) / 1.055, 2.4)
  }
  $rl = & $kanaal $r; $gl = & $kanaal $g; $bl = & $kanaal $b
  return 0.2126 * $rl + 0.7152 * $gl + 0.0722 * $bl
}

$img = [System.Drawing.Bitmap]::FromFile((Resolve-Path $Image))
try {
  $maxBg = -1.0; $bgKleur = ''
  $tekstPixels = 0; $totaal = 0
  for ($px = $X; $px -lt [Math]::Min($X + $W, $img.Width); $px++) {
    for ($py = $Y; $py -lt [Math]::Min($Y + $H, $img.Height); $py++) {
      $c = $img.GetPixel($px, $py)
      $l = Luminantie $c.R $c.G $c.B
      $totaal++
      if ($l -ge $TekstDrempel) { $tekstPixels++; continue }
      if ($l -gt $maxBg) { $maxBg = $l; $bgKleur = '{0:X2}{1:X2}{2:X2}' -f $c.R, $c.G, $c.B }
    }
  }
  $tr = [Convert]::ToInt32($TekstKleur.Substring(0,2),16)
  $tg = [Convert]::ToInt32($TekstKleur.Substring(2,2),16)
  $tb = [Convert]::ToInt32($TekstKleur.Substring(4,2),16)
  $lt = Luminantie $tr $tg $tb
  $ratio = ([Math]::Max($lt, $maxBg) + 0.05) / ([Math]::Min($lt, $maxBg) + 0.05)

  "gebied        : x=$X y=$Y w=$W h=$H"
  "tekstkleur    : #$TekstKleur (L=$([Math]::Round($lt,4)))"
  "lichtste bg   : #$bgKleur (L=$([Math]::Round($maxBg,4)))  <- slechtste geval"
  "contrast      : $([Math]::Round($ratio,2)):1"
  "tekstdekking  : $([Math]::Round(100.0 * $tekstPixels / [Math]::Max($totaal,1),1))% van de pixels"
  $advies = if ($ratio -ge 4.5) { 'AA gehaald voor kleine tekst' } elseif ($ratio -ge 3.0) { 'alleen AA-large (>=24px of vet >=18,66px)' } else { 'ONVOLDOENDE' }
  "oordeel       : $advies"
} finally { $img.Dispose() }
