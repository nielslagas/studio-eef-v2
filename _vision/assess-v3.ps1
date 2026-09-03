# Visuele beoordeling van de v4-screenshots: logo-centrering + gevelkaart-herontwerp.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root   = "D:\Projects\Eva Aukema\Studio-Eef\site"
$outDir = Join-Path $root "_vision"
$dk = [regex]::Match((Get-Content "C:\Users\Gebruiker\.dsh\.credentials.yaml" -Raw), 'DEEPSEEK_API_KEY:\s*(\S+)').Groups[1].Value

function ConvertTo-JpegDataUrl([string]$path, [int]$cropTop = -1, [int]$cropHeight = -1) {
  $img = [System.Drawing.Image]::FromFile($path)
  try {
    $src = $img
    if ($cropTop -ge 0) {
      $bmp = New-Object System.Drawing.Bitmap($img.Width, $cropHeight)
      $g = [System.Drawing.Graphics]::FromImage($bmp)
      $g.DrawImage($img, (New-Object System.Drawing.Rectangle(0, 0, $img.Width, $cropHeight)), (New-Object System.Drawing.Rectangle(0, $cropTop, $img.Width, $cropHeight)), [System.Drawing.GraphicsUnit]::Pixel)
      $g.Dispose(); $src = $bmp
    }
    $w = $src.Width; $h = $src.Height
    if ($w -gt 780) { $h = [int]($h * 780 / $w); $w = 780 }
    $out = New-Object System.Drawing.Bitmap($w, $h)
    $g2 = [System.Drawing.Graphics]::FromImage($out)
    $g2.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g2.DrawImage($src, 0, 0, $w, $h); $g2.Dispose()
    $ms = New-Object System.IO.MemoryStream
    $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
    $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]85)
    $out.Save($ms, $codec, $ep)
    if ($src -ne $img) { $src.Dispose() }
    $out.Dispose()
    'data:image/jpeg;base64,' + [Convert]::ToBase64String($ms.ToArray())
  } finally { $img.Dispose() }
}

function Invoke-VisionAgent([string]$naam, [string]$prompt, [string[]]$dataUrls) {
  $content = @(@{ type = 'text'; text = $prompt })
  foreach ($u in $dataUrls) { $content += @{ type = 'image_url'; image_url = @{ url = $u } } }
  $body = @{ model = 'deepseek-v4-flash-vision-exp'; messages = @(@{ role = 'user'; content = $content }); max_tokens = 6000; temperature = 0.3 } | ConvertTo-Json -Depth 8
  $reqFile = Join-Path $outDir "$naam-req.json"
  [System.IO.File]::WriteAllText($reqFile, $body)
  $respFile = Join-Path $outDir "$naam-resp.json"
  & curl.exe -s --max-time 240 "https://api.deepseek.com/chat/completions" -H "Authorization: Bearer $dk" -H "Content-Type: application/json" -d "@$reqFile" -o $respFile
  $raw = Get-Content $respFile -Raw
  try {
    $j = $raw | ConvertFrom-Json
    if ($j.error) { "FOUT van API voor ${naam}: $($j.error.message)"; return }
    $tekst = $j.choices[0].message.content
    if (-not $tekst -and $j.choices[0].message.reasoning_content) { $tekst = $j.choices[0].message.reasoning_content }
    [System.IO.File]::WriteAllText((Join-Path $outDir "$naam.txt"), $tekst)
    "== $naam OK ($($tekst.Length) tekens) =="
  } catch { "FOUT parse/HTTP voor ${naam}: $($raw.Substring(0, [Math]::Min(400, $raw.Length)))" }
  Remove-Item $reqFile, $respFile -ErrorAction SilentlyContinue
}

function Get-Slices([string]$path, [int]$sliceH, [int]$overlap) {
  $h = ([System.Drawing.Image]::FromFile($path)).Height
  $urls = @()
  for ($top = 0; $top -lt $h; $top += ($sliceH - $overlap)) {
    $hh = [Math]::Min($sliceH, $h - $top)
    $urls += (ConvertTo-JpegDataUrl $path $top $hh)
  }
  $urls
}

$kleuren = "Huisstijl: olijf #424631, mosterd #D6AF29, roze #F37C96, inkt #231F20, papier #FAF8F4. Nederlandse een-pager van schilderbedrijf Studio EEF."

$pHero = @"
Je bent vision inspector. Deze uitsnede toont de herontworpen 'gevelstaal'-kaart in de hero van $kleuren. De kaart was eerst een simpel streepjeshuis en is nu opgezet als een verfstaal: kopband in de actieve kleur (met ringgat en de kleurnaam 'Mosterd'), daaronder een geïllustreerde Nederlandse gevel die meekleurt, en zes kleurstalen met namen.

Beoordeel IN HET NEDERLANDS, concreet en kritisch:
1) Kopband: hiërarchie van GEVELSTAAL-label, ringgat en kleurnaam; contrast van de tekst op de band.
2) Huisillustratie: leest het als een vakmatig getekende gevel of nog als kleutertekening? Kijk naar lijnvoering, baksteenstructuur, vensters, deur, dak, stoep, en of elementen correct op elkaar aansluiten (raakvlakken, uitlijningen, overlappende onderdelen).
3) Stalenrij: zijn alle zes namen volledig leesbaar (let specifiek op 'Prima-roze')? Oogt de rij netjes uitgelijnd?
4) Totale kaart: witruimte, samenhang met de rest van de huisstijl, storende elementen.
Eindig met "OORDEEL:" gevolgd door een rapportcijfer (1-10) en een zinsnijd samenvatting.
"@
Invoke-VisionAgent 'v3-hero' $pHero @((ConvertTo-JpegDataUrl (Join-Path $root '_crop-hero-v4.png')))

$pLogo = @"
Je bent vision inspector. Deze uitsnede toont het logo van $($kleuren): een inktkleurige tegel met daarin een verfstaal-rastertje (geel/olijf/roze blokken) en verticale witte letters 'STUDIO'. De inhoud is zojuist gecentreerd in de tegel (eerder hing hij linksboven).

Beoordeel IN HET NEDERLANDS:
1) Zit de inhoud (letters + blokken) nu optisch gecentreerd in de tegel, zowel horizontaal als verticaal? Schat de marges links/rechts en boven/onder.
2) Is er ergens een witte rand, kleurstaart of niet-opgevuld hoekje zichtbaar aan de tegelrand?
3) Oogt het geheel netter en uitgebalanceerd?
Eindig met "OORDEEL:" gevolgd door een rapportcijfer (1-10) en een korte samenvatting.
"@
Invoke-VisionAgent 'v3-logo' $pLogo @((ConvertTo-JpegDataUrl (Join-Path $root '_crop-logo-v4.png')))

$pDesktop = @"
Je bent vision inspector en beoordeelt de bijgewerkte desktopversie (volledige pagina in plakken van boven naar beneden, met overlap) van $kleuren.

Zojuist gewijzigd: (1) het logo (inkttegel in de header en in de Over-sectie) is gecentreerd; (2) de hero-kaart is een 'gevelstaal' met kleurbare huisillustratie en stalenrij met zichtbare namen.

Beoordeel IN HET NEDERLANDS:
1) Sluiten de gewijzigde hero-kaart en het logo visueel aan op de rest van de pagina (diensten-stalen, impressies, werkwijze, over, contact)?
2) Zijn er elders op de pagina elementen stukgegaan of uit balans geraakt?
3) Wat zijn de twee zwakste plekken van de hele pagina nu (concreet, met sectienaam)?
Eindig met "OORDEEL:" gevolgd door een rapportcijfer (1-10) en een zinsnijd samenvatting.
"@
Invoke-VisionAgent 'v3-desktop' $pDesktop (Get-Slices (Join-Path $root '_inspect-desktop-v4.png') 1250 90)

$pMobile = @"
Je bent vision inspector en beoordeelt de mobiele versie (390px, volledige pagina in plakken, met overlap) van $kleuren.

Zojuist gewijzigd: de hero-kaart ('gevelstaal' met kleurbare huis en stalen-grid) en het gecentreerde logo.

Beoordeel IN HET NEDERLANDS:
1) Hero-kaart op mobiel: band, huis en stalen (3x2) leesbaar en netjes? Alle zes kleurnamen volledig zichtbaar?
2) Header met logo-tegel en menuknop: gebalanceerd?
3) Blijft de rest van de pagina (diensten, impressies, werkwijze, over, contact) netjes?
Eindig met "OORDEEL:" gevolgd door een rapportcijfer (1-10) en een zinsnijd samenvatting.
"@
Invoke-VisionAgent 'v3-mobile' $pMobile (Get-Slices (Join-Path $root '_inspect-mobile-v4.png') 1100 80)

"KLAAR"
