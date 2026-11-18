# site-v3 — "Afplakrand"

Derde opzet van de Studio EEF-site: bewust rustig, strak en professioneel.
Eén idee: egale kleurvlakken die elkaar in exacte rechte lijnen raken — de rand
zoals hij overblijft als de afplaktape eraf gaat. Onderbouwing en keuzes staan in
`ONTWERP-V3.md`.

**Status: voorstel ter beoordeling.** Niet live, niet gepromoveerd. v2 staat nog
in `site/` en blijft de actieve site; v1 in `site-v1/`.

## Openen

Open `index.html` in een browser. Er is geen build-stap, geen dependencies en de
pagina **werkt volledig zonder JavaScript**: de menuknop is een
`<details>`-element en de enige animatie is pure CSS. Het enige scriptje op de
pagina (4 regels, onderaan `index.html`) sluit het mobiele menu nadat een link is
gekozen — zonder dat scriptje blijft dat menu open over de inhoud staan en sluit
de bezoeker het met de menuknop.

## Bestanden

```
index.html          de hele pagina
css/style.css       alle stijlen, tokens in :root
assets/logo.svg     Eefs originele merktekstegel — byte-identiek aan
                    site/assets/logo.svg (SHA-256 AE40E7E7…47DE), nooit aanpassen
assets/favicon.svg  de bestaande favicon-variant uit site/assets/, ongewijzigd
assets/img/         werk-woonkamer.jpg, werk-gevel.jpg, werk-detail.jpg
                    (ongewijzigd overgenomen uit site/assets/img/ — regel 2)
                    eef-bus.jpg (1600x1200, 545 KB — échte foto van Eef naast
                    haar bus, door de eigenaar aangeleverd en opgeknapt met
                    topazlabs/image-upscale; het logo staat op de bus)
                    kleine-klus.jpg (720x480, 70 KB — échte foto van Eef met de
                    verfstripper op een kozijn, staat bij de dienst "Onderhoud &
                    kleine klussen"; origineel als img-gen/kleine-klus-bron.jpg)
assets/video/       hero.mp4 (382 KB, 1080x1080, 4 s, lus) en hero-mobiel.mp4
                    (119 KB, 540x540) — de ECHTE clip van de kwast op het kozijn,
                    opgeschaald met prunaai/p-video-upscale; hero-poster.jpg
                    (48 KB). De eerdere AI-hero staat in img-gen/hero-ai-*.mp4
ONTWERP-V3.md       ontwerpbrief en verantwoording
```

**Echte foto's gaan vóór AI-beeld.** De eigenaar leverde in november 2026 twee
eigen opnames aan: de foto van Eef bij haar bus (staat nu vol-breed in de
Over-sectie) en een clip van een kwast op een kozijn. De originelen staan als
`img-gen/eef-bus-bron.jpg` en `img-gen/werk-kwast-bron.mp4`; de bewerkte versies
staan in `assets/` of klaar in `img-gen/` (`werk-kwast-720.mp4`, 188 KB). Beide
kwamen via WhatsApp binnen en zijn dus gecomprimeerd — de foto op 1600x1200, de
video op 368x368. De video is met `prunaai/p-video-upscale` naar 1080p gebracht
en daarna teruggecomprimeerd; de foto met `topazlabs/image-upscale` (1:1, géén
gezichtsverandering — `prunaai/p-image-upscale` maakte Eefs gezicht zichtbaar
anders). Script: `_upscale_media.py`. Voor groter gebruik blijft het origineel
van de telefoon nodig.

**Het logo is heilig.** Er wordt in v3 niets aan Eefs tegel hertekend, herkleurd
of weggelaten: de tegel staat ongewijzigd in de kop (34px). In de Over-sectie
staat nu in plaats van de tegel de foto van Eef — waarop het logo op de bus te
zien is. Wie de tegel daar terug wil, kan dat met één regel (`over-merk` in
plaats van `over-foto`). De voettekst draagt alleen het woordmerk, omdat een
inkt-tegel op een inkt-achtergrond wegvalt — een keuze over de *context*, niet
over het logo.

**De hero-video** is de eigen clip van de kwast op het kozijn (zie `ONTWERP-V3.md`
voor waarom die als vierkant venster staat en niet als volle achtergrond). Het
bronbestand uit WhatsApp is opgeschaald met `_upscale_media.py`
(`prunaai/p-video-upscale`), daarna gecomprimeerd met een lokale ffmpeg
(`npm install ffmpeg-static --prefix _tools`, staat in `.gitignore`):

```pwsh
_tools/node_modules/ffmpeg-static/ffmpeg.exe -i img-gen/werk-kwast-pruna-1080.mp4 `
  -an -vf scale=1080:1080 -c:v libx264 -crf 30 -preset slow -pix_fmt yuv420p `
  -movflags +faststart site-v3/assets/video/hero.mp4
```

De eerdere, gegenereerde hero (Friese gevel → verfvlak) is met
`_gen_hero_video.py` gemaakt en staat nog in `img-gen/hero-ai-*.mp4`; terugzetten
is een kwestie van die bestanden weer in `assets/video/` zetten.

## Huisstijl

Vijf tokens (regel 3), plus gedocumenteerde afgeleiden — zie de tabel in
`ONTWERP-V3.md`. Kleurstelling: **maximaal één accent per sectie.** Roze alleen
in de kleurenband (3%) en het merkteken; mosterd als accent (mosterdstrook in de
hero, stapnummers, primaire knop), nooit als kleine tekstkleur op licht.

Contrast (nagerekend, WCAG 2.1):

| Combinatie | Ratio |
| --- | --- |
| inkt op papier | 15,4:1 |
| inkt op kalkwit | 14,0:1 |
| inkt op mosterd (de strook) | 7,8:1 |
| papier op inkt | 15,4:1 |
| papier op olijf | 9,2:1 |
| `--inkt-zwak` op papier / kalkwit | 5,3:1 |
| `--papier-68` op olijf / inkt | 5,3:1 / 7,5:1 |
| `--papier-78` op inkt | 9,8:1 |
| mosterd op olijf (contact-hover) | 4,7:1 |
| hero-tekst op het videobeeld, beginbeeld (gevel) | 10,9:1 (kleine tekst 9,5:1) |
| hero-tekst op het videobeeld, eindbeeld (verf) | 14,3:1 |

De twee videorijen zijn gemeten op de pagina zelf, op beide uitersten van de clip,
met de tekst even verborgen (`_vision/contrast-check.ps1`) — anders meet je de
antialiasing van je eigen letters in plaats van de achtergrond.

## Typografie

- **Archivo** (display, 600/700, `font-stretch: 112%`) — koppen, labels, knoppen,
  waarden.
- **Atkinson Hyperlegible** — lopende tekst.
- IBM Plex Mono uit v1/v2 is geschrapt: een derde familie voegde geen informatie
  toe.

## Motion

Eén gebaar in de opmaak: de mosterdstrook achter "laag verf" wordt één keer
aangebracht (`clip-path` van rechts naar links, 820 ms, 260 ms vertraging).
Het vierkante werkvenster rechts in de hero speelt de clip in een **lus** (de
kwaststreek herhaalt zich; de camera staat stil, dus geen zichtbare naad). Op
mobiel wordt de 540px-variant geladen; zonder JavaScript of bij
`prefers-reduced-motion` blijft de poster staan. Verder alleen
hover/focus-microinteracties van 160 ms.

## TODO-conventie (regel 1)

Zelfde set als v1/v2, andere markering: **7× `class="todo"`** (plaats + regio,
telefoon, e-mail, app, KvK, BTW, adres) en **5× `data-todo`** (Bel-knop in de
kop, de drie contactlinks, Bel-knop in de mobiele actiebalk). De markering is een
stippellijn in `currentColor` in plaats van de mosterd-halo uit v1/v2: nog
steeds duidelijk, veel rustiger.

## Testen

```pwsh
node _vision/console-test.js "file:///D:/Projects/Eva Aukema/Studio-Eef/site-v3/index.html" 1280 900
node _vision/console-test.js "file:///D:/Projects/Eva Aukema/Studio-Eef/site-v3/index.html" 390 844
node _vision/anchor-test.js werkwijze 390 "file:///D:/Projects/Eva Aukema/Studio-Eef/site-v3/index.html"
node _vision/screenshot-full.js "file:///D:/Projects/Eva Aukema/Studio-Eef/site-v3/index.html" 1280 _vision/check-v3-desktop.png
```

Twee bekende, onschuldige afwijkingen in de testuitvoer:

- `"NETWERK: laden mislukt: net::ERR_ABORTED Media"` — de test sluit de browser
  terwijl de video nog streamt. Geen fout in de pagina.
- Een lazy-load afbeelding onder de vouw meldt soms `ok: false`; dat is de
  laadtiming, niet een kapotte afbeelding (controleer met de full-page screenshot).

**Videoframes bekijken zonder videospeler** (essentieel: een clip kan halverwege
stukgaan of tekst hallucineren, en dat zie je alleen in de frames):

```pwsh
# _vision/_frames.html toont frames uit een mp4 naast elkaar
node _vision/screenshot-full.js "file:///D:/Projects/Eva Aukema/Studio-Eef/_vision/_frames.html?src=../img-gen/hero-video-huis-1.mp4&t=0.1,2.5,4.9" 1500 _vision/frames.png
```

**Een willekeurig frame in de pagina zelf bekijken** (vierde parameter van
`screenshot-full.js` is JavaScript dat vóór de capture draait):

```pwsh
$js = "(async function(){var v=document.querySelector('.hero-media');v.currentTime=1.0;await new Promise(function(r){v.addEventListener('seeked',r,{once:true})});v.pause()})()"
node _vision/screenshot-full.js "file:///D:/Projects/Eva Aukema/Studio-Eef/site-v3/index.html" 1280 _vision/hero-huis.png $js
```

**Let op bij mobiele screenshots voor de vision-meting:** verberg de vaste
actiebalk, anders schuift die in de full-page capture over de KvK/BTW-regel in de
voettekst en denkt het vision-model dat die regel ontbreekt (is precies één keer
gebeurd):

```pwsh
$js = "document.querySelector('.mobiel-balk').style.display='none';document.body.style.paddingBottom='0'"
```

Kwaliteitsronde met vision-eindoordeel en code-review:

```pwsh
powershell -File _vision/assess-v3-final.ps1 -Alleen vision   # of: review | alles
```

## Metingen

- **vision-eindoordeel** (deepseek-v4-flash-vision-exp), meting na de video-hero:
  **7,5/10 desktop, 8,5/10 mobiel** — rapporten `_vision/final-v3-desktop.txt`,
  `_vision/final-v3-mobile.txt`. De video wordt positief beoordeeld ("het
  eindbeeld draagt de typografie goed", contrast ruim voldoende, "de
  mosterdstrook is nu dé signatuur"). Het enige structurele minpunt in álle
  metingen is de sectie Werk: AI-impressies die als stock lezen (regel 2, niet
  zelf op te lossen). Eén opmerking is onderzocht en verworpen: het egaal donkere
  eindbeeld zou "mat" lezen terwijl de copy "fris" belooft. Twee alternatieven
  zijn gegenereerd (natte verfbaan, haarscherpe afplakrand) en allebei slechter —
  te licht, en de rand viel midden in de kop. Het egale olijfvlak is teruggezet,
  byte-identiek aan de gemeten versie. Zie `ONTWERP-V3.md` voor de details.
- **De mobiel-meting had één keer een artefact**: de vaste actiebalk dekte in de
  full-page screenshot de KvK/BTW-regel, waarna het model rapporteerde dat de
  voettekst die regel mist. In het echt staat hij er (gecontroleerd zonder balk);
  sindsdien is de body-padding 92px en staat de workaround in dit README.
- **code-review** (deepseek-v4-pro): **GOED-MET-OPMERKINGEN** —
  `_vision/review-v3.txt`. Alle vijf bevindingen zijn verwerkt:
  1. de papieren ring/schaduw om het logo in de voettekst is weg; de voettekst
     draagt nu alleen het woordmerk (het logo blijft onaangeroerd);
  2. de Bel-placeholders in kop en actiebalk hebben een `title`;
  3. het mobiele menu sluit na het kiezen van een link;
  4. de alt-teksten van de werkbeelden beginnen met "Impressie:";
  5. de dode `@media (min-width: 981px)`-regel is verwijderd.
- **tests**: `console-test.js` 1280×900 en 390×844 → geen console-fouten, geen
  gebroken afbeeldingen; `anchor-test.js` op `#werkwijze` (390) en `#contact`
  (1280) → ankers landen onder de sticky kop.
