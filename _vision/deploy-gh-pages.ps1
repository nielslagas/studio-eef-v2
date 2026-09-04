# Veilige gh-pages-deploy voor Studio EEF (voorkomt de map-zonder-Recurse-val).
# Gebruik:  pwsh _vision/deploy-gh-pages.ps1
# Werkt in de bestaande temp-clone (%TEMP%\eef-ghpages-v2); bouwt die zo nodig
# volledig opnieuw op. Hoofdregel: index/README als bestanden, css/js/assets
# ALTILIJD met -Recurse; logo-keuze/ blijft behouden; inspect-PNG's gaan nooit mee.
$ErrorActionPreference = 'Stop'
$root = "D:\Projects\Eva Aukema\Studio-Eef"
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
Copy-Item "$root\site\index.html", "$root\site\README.md" $tmp -Force
Copy-Item "$root\site\css", "$root\site\js", "$root\site\assets" $tmp -Recurse -Force
if (Test-Path "$root\logo-keuze") {
  if (Test-Path "$tmp\logo-keuze") { Remove-Item "$tmp\logo-keuze" -Recurse -Force }
  Copy-Item "$root\logo-keuze" "$tmp\logo-keuze" -Recurse -Force
}
Remove-Item "$tmp\_inspect-*.png" -ErrorAction SilentlyContinue

# harde sanity-checks vóór de push: deploy moet de site volledig bevatten
$must = @("index.html", "css\style.css", "js\main.js", "assets\logo.svg", "assets\favicon.svg", "assets\img\hero-hout.jpg", "assets\img\verfstreek-mosterd.png", "assets\img\kwast-ronde.png", "assets\img\werk-woonkamer.jpg", "assets\img\werk-gevel.jpg", "assets\img\werk-detail.jpg")
$missing = $must | Where-Object { -not (Test-Path (Join-Path $tmp $_)) }
if ($missing) { throw "deploy onvolledig, mist: $($missing -join ', ')" }

git -C $tmp add -A
$changed = git -C $tmp status --porcelain
if ($changed) {
  git -C $tmp -c "user.name=$name" -c "user.email=$email" commit -m "Site-deploy vanaf projectroot" | Out-Null
  git -C $tmp push origin gh-pages
  "gedeployd: " + ((Get-ChildItem $tmp -Recurse -File | Measure-Object).Count) + " bestanden"
} else {
  "niets gewijzigd - geen push nodig"
}
