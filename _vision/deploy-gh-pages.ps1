# Veilige gh-pages-deploy voor Studio EEF - publiceert site-v3.
#
# Gebruik:
#   pwsh _vision/deploy-gh-pages.ps1              -> DROOGLOOP: bouwt en controleert, pusht NIET
#   pwsh _vision/deploy-gh-pages.ps1 -Bevestig    -> publiceert echt naar gh-pages
#
# De droogloop is de standaard sinds v3: de site bevat nog TODO-placeholders
# (telefoon, e-mail, KvK/BTW, werkgebied), dus publiceren mag alleen bewust.
#
# Werkt in de bestaande temp-clone (%TEMP%\eef-ghpages-v2); bouwt die zo nodig
# opnieuw op. Hoofdregel: index/README als bestanden, css/assets ALTIJD met
# -Recurse; logo-keuze/ blijft behouden; inspect-PNG's gaan nooit mee.
param([switch]$Bevestig)

$ErrorActionPreference = 'Stop'
$root = "D:\Projects\Eva Aukema\Studio-Eef"
$src  = Join-Path $root 'site-v3'
$name = git -C $root config user.name
$email = git -C $root config user.email
$tmp  = Join-Path $env:TEMP "eef-ghpages-v2"

if (-not (Test-Path "$tmp\.git")) {
  New-Item -ItemType Directory $tmp -Force | Out-Null
  git -C $tmp init -b gh-pages 2>&1 | Out-Null
  git -C $tmp remote add origin "https://github.com/nielslagas/studio-eef-v2.git"
  git -C $tmp fetch origin gh-pages 2>&1 | Out-Null
  git -C $tmp checkout -b gh-pages --track origin/gh-pages 2>&1 | Out-Null
}

Get-ChildItem $tmp -Exclude "logo-keuze", ".git" | Remove-Item -Recurse -Force
Copy-Item "$src\index.html", "$src\README.md" $tmp -Force
Copy-Item "$src\css", "$src\assets" $tmp -Recurse -Force
if (Test-Path "$root\logo-keuze") {
  if (Test-Path "$tmp\logo-keuze") { Remove-Item "$tmp\logo-keuze" -Recurse -Force }
  Copy-Item "$root\logo-keuze" "$tmp\logo-keuze" -Recurse -Force
}
Remove-Item "$tmp\_inspect-*.png" -ErrorAction SilentlyContinue

# harde sanity-checks v??r de push: deploy moet de site volledig bevatten
$must = @(
  "index.html",
  "css\style.css",
  "assets\logo.svg",
  "assets\favicon.svg",
  "assets\img\werk-woonkamer.jpg",
  "assets\img\werk-gevel.jpg",
  "assets\img\werk-detail.jpg",
  "assets\img\eef-bus.jpg",
  "assets\img\kleine-klus.jpg",
  "assets\video\hero.mp4",
  "assets\video\hero-mobiel.mp4",
  "assets\video\hero-poster.jpg"
)
$missing = $must | Where-Object { -not (Test-Path (Join-Path $tmp $_)) }
if ($missing) { throw "deploy onvolledig, mist: $($missing -join ', ')" }
"controle ok: $($must.Count) verplichte bestanden aanwezig"

git -C $tmp add -A
$changed = git -C $tmp status --porcelain
if (-not $changed) { "niets gewijzigd - geen deploy nodig"; return }

"gewijzigd t.o.v. gh-pages: $((($changed -split "`n").Count)) bestanden"
if (-not $Bevestig) {
  "DROOGLOOP - niets gepusht. Voeg -Bevestig toe om echt te publiceren."
  return
}

git -C $tmp -c "user.name=$name" -c "user.email=$email" commit -m "Site-deploy v3 vanaf projectroot" | Out-Null
git -C $tmp push origin gh-pages
"gepubliceerd: " + ((Get-ChildItem $tmp -Recurse -File | Measure-Object).Count) + " bestanden"
