# Visuele eindbeoordeling van de v2-screenshots (na verbetering).
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

$p1 = @"
Je bent vision inspector en beoordeelt de VERBETERDE versie van een website (desktop, volledige pagina in plakken van boven naar beneden, met kleine overlap). $kleuren

Eerdere zwaktes die zou moeten zijn opgelost:
- accentwoord 'laag' in de H1 was gele tekst met te weinig contrast (nu: donkere letters op een mosterdgele verfstreek);
- contact-labels (BEL/MAIL/APP) hadden te weinig contrast op olijf (nu lichtere mosterdtint);
- de vijf werkwijze-stappen oogden krap (nu meer ruimte);
- de Over-sectie oogde onevenwichtig (nu logo-tegel met vier-kleurenstrip eronder);
- placeholder-gegevens (KvK, [plaats + regio]) zijn nu gemarkeerd met een mosterthalo + stippellijn.

Beoordeel IN HET NEDERLANDS: 1) zijn de genoemde reparaties zichtbaar gelukt? 2) hiërarchie, witruimte, contrast en huisstijl-gebruik nu goed? 3) blijven er zwaktes of nieuwe problemen over (noem ze concreet)? Eindig met "OORDEEL:" gevolgd door een rapportcijfer (1-10) en een zinsnijd samenvatting.
"@
Invoke-VisionAgent 'final-desktop' $p1 (Get-Slices (Join-Path $root '_inspect-desktop-v2.png') 1250 90)

$p2 = @"
Je bent vision inspector en beoordeelt de VERBETERDE versie van een website (mobiel 390px, volledige pagina in plakken van boven naar beneden, met kleine overlap). $kleuren

Eerdere zwaktes die zou moeten zijn opgelost:
- de zesde verfstaal viel als wees op een tweede regel (nu 3x2 grid, gecentreerd);
- de werkwijze-stap 'Opleveren' was een wees in het grid (nu volle-breedte slot met nummer links, tekst rechts en een dunne lijn erboven);
- impressies toonden lege vlakken (afbeeldingen laden nu direct);
- placeholders (telefoonnummer, e-mail, KvK/adres) zijn gemarkeerd met mosterthalo + stippellijn.

Beoordeel IN HET NEDERLANDS: 1) zijn de genoemde reparaties zichtbaar gelukt? 2) mobiele layout, leesbaarheid en huisstijl nu goed? 3) blijven er zwaktes of nieuwe problemen over (concreet)? Eindig met "OORDEEL:" gevolgd door een rapportcijfer (1-10) en een zinsnijd samenvatting.
"@
Invoke-VisionAgent 'final-mobile' $p2 (Get-Slices (Join-Path $root '_inspect-mobile-v2.png') 1100 80)

"KLAAR"
