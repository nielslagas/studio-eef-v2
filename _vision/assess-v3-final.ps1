# Kwaliteitsronde v3 "Afplakrand": vision-eindoordeel (desktop + mobiel) en
# onafhankelijke code-review, volgens de rolverdeling in AGENTS.md.
#   - vision  : model deepseek-v4-flash-vision-exp (native API)
#   - review  : model deepseek-v4-pro
# Output: _vision/final-v3-desktop.txt, _vision/final-v3-mobile.txt, _vision/review-v3.txt
# Gebruik: -Alleen vision | review | alles   (standaard: alles)
param([string]$Alleen = 'alles')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root   = "D:\Projects\Eva Aukema\Studio-Eef\site-v3"
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

function Invoke-DeepSeek([string]$naam, [string]$model, [double]$temp, [int]$maxTokens, [object[]]$content) {
  $body = @{ model = $model; messages = @(@{ role = 'user'; content = $content }); max_tokens = $maxTokens; temperature = $temp } | ConvertTo-Json -Depth 10
  $reqFile = Join-Path $outDir "$naam-req.json"
  [System.IO.File]::WriteAllText($reqFile, $body)
  $respFile = Join-Path $outDir "$naam-resp.json"
  & curl.exe -s --max-time 420 "https://api.deepseek.com/chat/completions" -H "Authorization: Bearer $dk" -H "Content-Type: application/json" -d "@$reqFile" -o $respFile
  # ReadAllText i.p.v. Get-Content: die laatste leest UTF-8 als ANSI en dan
  # komen accenten en streepjes als mojibake in het rapport terecht.
  $raw = [System.IO.File]::ReadAllText($respFile)
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

$context = @"
Het gaat om een NIEUWE derde opzet (v3 "Afplakrand") van de website van Studio EEF,
een eenmans-schildersbedrijf. Huisstijl: olijf #424631, mosterd #D6AF29, roze #F37C96,
inkt #231F20, papier #FAF8F4 (plus kalkwit #F1EDE4 als vlak).
Opdracht van de eigenaar: "bewust rustig, strak en professioneel". De twee eerdere
opzetten (v1 huisje/gevelstaal, v2 donkere 'Verse verf' met AI-kwastfoto) werden door
de eigenaar allebei afgewezen als niet mooi; verwijten waren: druk, gedateerd,
onrustige hero, te veel decoratie (badges, pillen, halo's, marquee), en AI-foto's die
als werk doorgaan. v3 is daarom volledig getypeerd: geen AI-beeld in de hero, geen
rondingen, geen schaduwen, geen badges/pillen, en nul JavaScript.
Bewust zo (geen fouten): placeholders (telefoon, e-mail, app, KvK/BTW/adres,
[plaats + regio]) zijn gemarkeerd met een stippellijn (class="todo") — die horen zo;
de werkfoto's zijn AI-impressies en dat staat er als noot bij; de sectie Werkwijze
heeft nummers omdat het een echte volgorde is.

Sinds de vorige meting is de hero opnieuw opgebouwd. In plaats van een video achter
de hele kop staat er nu een inktvlak met de kop links en rechts een VIERKANT venster
(ongeveer 380px) met een echte werkvideo: een hand die met een kwast een kozijn in
donkerrood schildert. Die clip is eigen materiaal van de eigenaar (via WhatsApp
binnen, opgeschaald met AI) en loopt in een lus; bij prefers-reduced-motion of zonder
JavaScript staat het stille beginbeeld er. Hij staat bewust NIET als volle
achtergrond: het is een macro-opname en op volledige breedte werd het een
onherkenbare donkere vlek. Beoordeel of de combinatie (typografie links, echt
werkmateriaal rechts) rustig en professioneel voelt, of het rode kozijn bij de
huisstijl past of juist stoort, en of de verhouding tussen tekst en beeld klopt.
"@

$p1 = @"
Je bent vision-inspector en geeft het EINDOORDEEL over v3 op DESKTOP (volledige pagina
in plakken van boven naar beneden, met kleine overlap). $context

LET OP — dit is de Herziening na eerdere metingen. Wat er sindsdien is veranderd:
(1) de mosterdstrook achter "laag verf" loopt over de volle regelhoogte en breder
door dan de woorden; (2) de Over-sectie toont nu een echte foto van Eef naast haar
bus (met het logo op de bus) in plaats van de logo-tegel, en de kop zegt daar "haar
eigen huis"; (3) de hero is opnieuw opgebouwd, zie de uitleg hierboven.

Beoordeel IN HET NEDERLANDS per sectie bij naam: hero (incl. het vierkante
werkvenster en de mosterdstrook), de kleurenband onder de hero, diensten, werk,
werkwijze, over EEF, contact, voettekst.
Let op hiërarchie, witruimte, contrast, huisstijlgebruik en storende elementen.
Beantwoord daarnaast expliciet:
(a) komt de pagina rustig en professioneel over, of ruikt het naar een generieke
    AI/template-look? Wees streng en concreet;
(b) leest de mosterdstrook achter "laag verf" als een aangebrachte laag verf, of
    als een marker-highlight? En is het contrast van de inkt-tekst erop goed genoeg?
(c) past het rode kozijn in de hero-video bij de huisstijl, of stoort die kleur?
    En klopt de verhouding tussen de tekstkolom en het vierkante beeld?
(d) is de foto van Eef in de Over-sectie een verbetering ten opzichte van een
    logo-tegel, of leidt hij af?
(c) is het merkteken (inkt-tegel met drie balken in mosterd/olijf/roze) op zijn
    echte formaat (34px in de kop, 118px in de Over-sectie) bruikbaar en consistent?
(d) wat is het zwakste punt van de hele pagina, met sectienaam en concrete reden?
(e) leest de mosterdstrook nog als dé signature, nu de hero een vierkant werkvenster
    heeft in plaats van een volle achtergrond?
Eindig met "OORDEEL:" gevolgd door een rapportcijfer (1-10) en één zin samenvatting.
"@
if ($Alleen -in @('alles', 'vision')) {
  Invoke-DeepSeek 'final-v3-desktop' 'deepseek-v4-flash-vision-exp' 0.3 16000 (@(@{ type = 'text'; text = $p1 }) + (Get-Slices 'D:\Projects\Eva Aukema\Studio-Eef\_vision\check-v3-desktop.png' 1250 90 | ForEach-Object { @{ type = 'image_url'; image_url = @{ url = $_ } } }))
}
$p2 = @"
Je bent vision-inspector en geeft het EINDOORDEEL over v3 op MOBIEL (390px, volledige
pagina in plakken van boven naar beneden, met kleine overlap). $context

De vaste actiebalk onderaan (Bel/Offerte) valt op een full-page screenshot buiten
beeld — beoordeel die niet.
Beoordeel IN HET NEDERLANDS per sectie bij naam: hero, kleurenband, diensten, werk,
werkwijze, over, contact, voettekst. Let op leesbaarheid, hiërarchie, witruimte,
contrast, aanraakbare knoppen en storende elementen (afgekapte tekst, te krappe
marges, rare regelafbrekingen rond de mosterdlaag). Beantwoord daarnaast expliciet:
(a) voelt dit op mobiel rustig en professioneel?; (b) breekt de mosterdlaag achter
"laag verf" netjes af over de regel, of oogt het rommelig?; (c) komt het vierkante
werkvenster op mobiel goed uit (formaat, plek onder de tekst) of maakt het de hero
te lang?; (d) wat is het zwakste punt op mobiel, met sectienaam?
Eindig met "OORDEEL:" gevolgd door een rapportcijfer (1-10) en één zin samenvatting.
"@
if ($Alleen -in @('alles', 'vision')) {
  Invoke-DeepSeek 'final-v3-mobile' 'deepseek-v4-flash-vision-exp' 0.3 16000 (@(@{ type = 'text'; text = $p2 }) + (Get-Slices 'D:\Projects\Eva Aukema\Studio-Eef\_vision\check-v3-mobile.png' 1100 80 | ForEach-Object { @{ type = 'image_url'; image_url = @{ url = $_ } } }))
}

$html = [System.IO.File]::ReadAllText((Join-Path $root 'index.html'))
$css  = [System.IO.File]::ReadAllText((Join-Path $root 'css\style.css'))
$p3 = @"
Je bent code-reviewer voor een statische Nederlandse één-pager (vanilla HTML/CSS,
geen build-stap, nul JavaScript). $context

Hieronder staan index.html en css/style.css volledig. Reken GEEN contrastgetallen
na — die zijn al gecontroleerd en staan in site-v3/README.md; noem alleen een
combinatie als je er een ziet die daar ontbreekt.

Antwoord in het Nederlands, maximaal 500 woorden, in precies deze vorm, en begin
direct met punt 1 (geen inleiding, geen afweging vooraf):

1. VIJF BEVINDINGEN — per bevinding: bestand + selector/regel + waarom het een
   probleem is. Let op cascade en specificity (ook tussen de media queries), dode
   of tegenstrijdige regels, ontbrekende hover/focus/active-staten, aria en
   alt-teksten, of de ankers bestaan, de <details>-menumarkup, en restjes van
   eerdere versies (v1/v2).
2. QUICK WINS — maximaal 4, klein en concreet.
3. OORDEEL: GOED / GOED-MET-OPMERKINGEN / AFKEUR — plus één zin.

Pas NIETS aan — alleen review.

--- index.html ---
$html

--- css/style.css ---
$css
"@
if ($Alleen -in @('alles', 'review')) {
  Invoke-DeepSeek 'review-v3' 'deepseek-v4-pro' 0.2 32000 @(@{ type = 'text'; text = $p3 })
}

"KLAAR"
