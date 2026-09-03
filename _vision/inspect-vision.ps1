# Vision-nulmeting Studio EEF via native DeepSeek API (deepseek-v4-flash-vision-exp)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root   = "D:\Projects\Eva Aukema\Studio-Eef\site"
$outDir = Join-Path $root "_vision"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$dk = [regex]::Match((Get-Content "C:\Users\Gebruiker\.dsh\.credentials.yaml" -Raw), 'DEEPSEEK_API_KEY:\s*(\S+)').Groups[1].Value

function ConvertTo-JpegDataUrl([string]$path, [int]$maxWidth = 0, [int]$cropTop = -1, [int]$cropHeight = -1) {
  $img = [System.Drawing.Image]::FromFile($path)
  try {
    $src = $img
    if ($cropTop -ge 0) {
      $bmp = New-Object System.Drawing.Bitmap($img.Width, $cropHeight)
      $g = [System.Drawing.Graphics]::FromImage($bmp)
      $g.DrawImage($img, (New-Object System.Drawing.Rectangle(0, 0, $img.Width, $cropHeight)), (New-Object System.Drawing.Rectangle(0, $cropTop, $img.Width, $cropHeight)), [System.Drawing.GraphicsUnit]::Pixel)
      $g.Dispose()
      $src = $bmp
    }
    $w = $src.Width; $h = $src.Height
    if ($maxWidth -gt 0 -and $w -gt $maxWidth) { $h = [int]($h * $maxWidth / $w); $w = $maxWidth }
    $out = New-Object System.Drawing.Bitmap($w, $h)
    $g2 = [System.Drawing.Graphics]::FromImage($out)
    $g2.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g2.DrawImage($src, 0, 0, $w, $h)
    $g2.Dispose()
    $ms = New-Object System.IO.MemoryStream
    $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
    $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]85)
    $out.Save($ms, $jpegCodec, $ep)
    if ($src -ne $img) { $src.Dispose() }
    $out.Dispose()
    'data:image/jpeg;base64,' + [Convert]::ToBase64String($ms.ToArray())
  } finally { $img.Dispose() }
}

function Invoke-VisionAgent([string]$naam, [string]$prompt, [string[]]$dataUrls) {
  $content = @(@{ type = 'text'; text = $prompt })
  foreach ($u in $dataUrls) { $content += @{ type = 'image_url'; image_url = @{ url = $u } } }
  $body = @{ model = 'deepseek-v4-flash-vision-exp'; messages = @(@{ role = 'user'; content = $content }); max_tokens = 16000; temperature = 0.3 } | ConvertTo-Json -Depth 8
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
}

$kleuren = "Huisstijlkleuren uit het logo: olijf #424631, mosterd #D6AF29, roze #F37C96, inkt #231F20, plus papier #FAF8F4 en wit. De site is van Studio EEF, een Nederlands schilderbedrijf (een-pager). Er staat een interactieve gevel-kleurenkiezer in de hero."

# --- Taak 1: desktop volledig ---
$p1 = @"
Je bent vision inspector voor een website-review. Dit is een volledige desktopscreenshot (720px breed, boven naar beneden lezen). $kleuren

Beoordeel IN HET NEDERLANDS, concreet en specifiek (noem secties en elementen bij naam):
1. Visuele hierarchie: wat valt het eerst op, is de leesvolgorde logisch, zijn koppen/CTA's duidelijk onderscheiden?
2. Witruimte en ritme: sectie-afstanden, uitlijning, waar voelt het krap of willekeurig?
3. Contrast en leesbaarheid van tekst op achtergrond.
4. Huisstijl: worden olijf/mosterd/roze/inkt herkenbaar en consequent gebruikt of domineert iets generieks? Zijn er elementen die er AI-templated uitzien (cream+serif+terracotta-cliche, paarse gradients, generieke icon-cards)?

Eindig met "TOP:" gevolgd door de 3-6 belangrijkste zwakheden van deze screenshot, elk in een zin, grootste impact eerst.
"@
Invoke-VisionAgent 'desktop' $p1 @((ConvertTo-JpegDataUrl (Join-Path $root '_inspect-desktop-full.png')))

# --- Taak 2: mobiel in plakken ---
$mob = Join-Path $root '_inspect-mobile-full.png'
$imgH = ([System.Drawing.Image]::FromFile($mob)).Height
$imgH = 6237
$sliceH = 1100; $overlap = 80
$dataUrls = @(); $idx = 0
for ($top = 0; $top -lt $imgH; $top += ($sliceH - $overlap)) {
  $h = [Math]::Min($sliceH, $imgH - $top)
  $dataUrls += (ConvertTo-JpegDataUrl $mob 0 $top $h)
  $idx++
}
$p2 = @"
Je bent vision inspector voor een website-review. Dit is een volledige mobiele screenshot (390px breed) in $idx verticale plakken van boven naar beneden (plakken overlappen iets). $kleuren

Beoordeel IN HET NEDERLANDS, concreet en specifiek (noem secties en elementen bij naam):
1. Mobiele layout: header/menu, stapeling van secties, afbeeldingen, tekstgrootte, knoppen, de gevel-kleurenkiezer.
2. Witruimte en ritme specifiek op smal scherm.
3. Contrast en leesbaarheid.
4. Huisstijl-consistentie op mobiel en AI-look-check (cream+serif+terracotta-cliche, paarse gradients, generieke icon-cards).

Eindig met "TOP:" gevolgd door de 3-6 belangrijkste zwakheden op mobiel, elk in een zin, grootste impact eerst.
"@
Invoke-VisionAgent 'mobile' $p2 $dataUrls

# --- Taak 3: hero + contact close-ups ---
$p3 = @"
Je bent vision inspector voor een website-review. Je krijgt twee close-ups: eerst de hero, dan de contactsectie. $kleuren

Beoordeel IN HET NEDERLANDS, concreet en specifiek:
1. Hero: compositie, hierarchie tussen kop/subkop/knoppen, de interactieve gevel-kaart met verfstalen (is het duidelijk? oogt het verzorgd?), de druppel onder het gele woord, uitlijning.
2. Contactsectie: de drie kaarten (Bel/Mail/App), contrast van de mosterd labels op het olijfgroen, uitlijning, grootte.
3. Details die op een volle pagina-screenshot niet zichtbaar zouden zijn.

Eindig met "TOP:" gevolgd door de 3-6 belangrijkste zwakheden, elk in een zin, grootste impact eerst.
"@
Invoke-VisionAgent 'detail' $p3 @((ConvertTo-JpegDataUrl (Join-Path $root '_inspect-hero.png')), (ConvertTo-JpegDataUrl (Join-Path $root '_inspect-contact-anchor.png')))

"KLAAR"
