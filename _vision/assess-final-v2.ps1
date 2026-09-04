# Visuele eindbeoordeling van de v2 "Verse verf"-screenshots (desktop + mobiel).
# Adaptatie van assess-final.ps1 voor de v2-ronde: nieuwe bestandsnamen en
# v2-eindoordeelvragen per sectie. Output in _vision\final-v2-desktop.txt / -mobile.txt.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root   = "D:\Projects\Eva Aukema\Studio-Eef\site"
$outDir = "D:\Projects\Eva Aukema\Studio-Eef\_vision"
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

$kleuren = "Huisstijl: olijf #424631, mosterd #D6AF29, roze #F37C96, inkt #231F20, papier #FAF8F4. Nederlandse één-pager van schilderbedrijf Studio EEF."

$p1 = @"
Je bent vision-inspector en geeft het EINDOORDEEL over de website na de logo-B + AI-hero-inbouw (desktop, volledige pagina in plakken van boven naar beneden, met kleine overlap). $kleuren

Belangrijke wijzigingen sinds de vorige meting: (1) het logo is nu Eefs originele tegel (EEF in mosterd/olijf/roze verfstalen-banden, verticale STUDIO-letters, olijf lichter gemaakt #6A7150) — in header (46px), groot in de Over-sectie, en als favicon-bands; (2) de hero-plank is nu een fotorealistische eiken macrofoto met een mosterd verfstreek mét kwasttextuur en een fotorealistische RONDE huisschilderskwast met mosterdresten die de kop 'beschildert'; (3) verder ongewijzigd: schuine mosterd marquee, trustbar, diensten-verfstaalkaarten, werk-impressies, interactieve kleurengevel, werkwijze, contact op olijf, footer.

Bewust zo (geen fouten): mosterd nergens als kleine tekstkleur op licht; placeholders (telefoon, e-mail, app, KvK/BTW/adres, [plaats + regio]) dragen een mosterthalo + stippellijn — de contact-waardes horen die halo te hebben (check!); de verticale STUDIO-letters lezen van onder naar boven (Eefs eigen ontwerp); de verfstreek loopt over de volle plankbreedte (v2-concept).

Beoordeel IN HET NEDERLANDS per sectie bij naam: hiërarchie, witruimte, contrast, huisstijl-gebruik en storende elementen. Beantwoord daarnaast expliciet: (a) leest de fotokwast als een geloofwaardige RONDE, gebruikte huisschilderskwast (vakmanschap) of als kunstenaarspenseel/nieuw?; (b) oogt het logo-vervangingswerk consistent (header/Over/favicon-idee)?; (c) komt de site als geheel nog steeds flitsend en modern over, nu met fotorealistisch materiaal? Eindig met "OORDEEL:" gevolgd door een rapportcijfer (1-10) en een zinsnijd samenvatting.
"@
Invoke-VisionAgent 'final-routea-desktop' $p1 (Get-Slices (Join-Path $root '_inspect-desktop.png') 1250 90)

$p2 = @"
Je bent vision-inspector en geeft het EINDOORDEEL over de website na de logo-B + AI-hero-inbouw (mobiel, 390px, volledige pagina in plakken van boven naar beneden, met kleine overlap). $kleuren

Wijzigingen sinds de vorige meting: originele logo-tegel van Eef (header 46px, groot in Over, favicon-bands) en een fotorealistische hero (eiken plank-foto, mosterd verfstreek met kwasttextuur, fotorealistische ronde huisschilderskwast met mosterdresten). De vaste mobiele CTA-balk is op een full-page screenshot mogelijk niet zichtbaar — beoordeel die niet.

Bewust zo (geen fouten): mosterd nergens als kleine tekstkleur op licht; placeholders dragen mosterthalo + stippellijn (de contact-waardes horen die te hebben — check!); verfstalen staan 3x2 met naamlabels; STUDIO-letters lezen van onder naar boven (eigen ontwerp).

Beoordeel IN HET NEDERLANDS per sectie bij naam: mobiele leesbaarheid, hiërarchie, witruimte, contrast, huisstijl-gebruik en storende elementen (afgeknapte teksten, te krappe marges, kwast die te groot/klein op mobiel valt). Eindig met "OORDEEL:" gevolgd door een rapportcijfer (1-10) en een zinsnijd samenvatting.
"@
Invoke-VisionAgent 'final-routea-mobile' $p2 (Get-Slices (Join-Path $root '_inspect-mobile.png') 1100 80)

"KLAAR"
