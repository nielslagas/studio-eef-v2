# AGENTS.md — Studio EEF website

Project: statische één-pager (Nederlands, geen build-stap) in `site-v3/`.
Open `site-v3/index.html` in een browser; er is verder niets nodig.

## Mappenstructuur (sinds 18-11-2026: alleen v3 in de repo)

- `site-v3/` — **de site** (derde opzet "Afplakrand"; rustig, strak,
  professioneel; werkt volledig zonder JavaScript). Brief:
  `site-v3/ONTWERP-V3.md`, README: `site-v3/README.md`. Live-publicatie gebeurt
  met `_vision/deploy-gh-pages.ps1 -Bevestig` (zonder die vlag: droogloop,
  omdat de site nog TODO-placeholders heeft).
- `_archief/site-v1/` en `_archief/site-v2/` — de twee eerdere opzetten, op
  verzoek van de eigenaar uit de repo gehaald (18-11-2026). Lokaal bewaard en
  in de gitgeschiedenis; `_archief/` staat in `.gitignore`.
- `_vision/` — inspectie- en testtooling + rapporten (versie-onafhankelijk)
- `logo-alternatieven/`, `logo-keuze/`, `studio-eef-logo.svg`, `eef.pdf.pdf`,
  `_gen_*.py` — bronmateriaal en generatiescripts (niet verplaatsen: de scripts
  verwijzen naar relatieve paden vanuit de projectroot)
- `img-gen/` — ruwe AI-generaties en tussenbestanden (48 MB, `img-gen/*` is
  ge-ignored behalve de originelen van de eigenaar)

## Modellenvaste per rol (afgesproken met de eigenaar)

| Rol | Model | Route |
| --- | --- | --- |
| Orchestrator (planning, coördinatie) | glm-5.3 | sessie-default (zai) |
| **Fullstack engineer (implementatie)** | **glm-5.3** | subagent op sessie-default (geen override) |
| **Reviewer (code/diff)** | **deepseek-v4-pro** | provider `deepseek` (native API) |
| Tester (tests/builds) | glm-5.3-flash | provider `zai` (flat-rate) |
| Vision-check (routine screenshots) | glm-5.3-flash | provider `zai` (flat-rate, text+image) |
| Vision-eindoordeel (nulmeting) | deepseek-v4-flash-vision-exp | provider `deepseek` |
| **Researcher (achtergrond/web)** | **glm-5.3-flash** | provider `zai` (flat-rate, 1M context) |
| Beeldgenerator (AI-beelden) | glm-5.3 | subagent (sessie-default) met replicate-skills |

De providers `zai` (GLM Coding Plan, flat-rate) en `deepseek` staan in
`~/.dsh/settings.yaml` (deepseek-key: `DEEPSEEK_API_KEY` uit
`~/.dsh/.credentials.yaml`). Volumerollen (tester, vision-check, researcher)
draaien op zai/glm-5.3-flash; review als workflow-agent met
`{ provider: "deepseek", model: "deepseek-v4-pro" }` en het vision-eindoordeel
idem met `model: "deepseek-v4-flash-vision-exp"` — DeepSeek blijft bewust
ingezet waar onafhankelijkheid van de implementerende modelfamilie telt.
deepseek-v4-flash blijft fallback voor research als de zai-route onverhoopt
niet beschikbaar is.

De fullstack engineer is een gewone subagent zonder provider/model-override
(draait dus op glm-5.3): krijgt de goedgekeurde punten + deze vaste regels
mee, laadt vóór UI-werk de `frontend-design` skill, werkt in batches en
levert per batch af voor review. Bij grotere changes meerdere engineers
parallel over onafhankelijke bestanden.

Let op: op OpenRouter is de vision-slug geblokkeerd door het databeleid van
die key — altijd de native provider gebruiken. deepseek-v4-flash is
tekst-only (geen read_image); glm-5.3-flash wél vision-capable
(`input: [text, image]` in settings.yaml).

## vaste regels voor dit project

1. **TODO-placeholders nooit zelf invullen.** Zoek op `class="todo"`, `data-todo`
   of `TODO` in `site-v3/index.html`. Markeringsstijl: `.todo` (mosterthalo +
   stippellijn). De eigenaar vult telefoon, e-mail, KvK/BTW/adres, werkgebied
   en de JSON-LD zelf in.
2. **AI-impressies (`site-v3/assets/img/werk-*.jpg`) niet vervangen of regenereren**
   — daar komen echte projectfoto's (zelfde bestandsnamen, alt-teksten bijwerken).
3. **Huisstijl:** olijf `#424631`, mosterd `#D6AF29`, roze `#F37C96`,
   inkt `#231F20`, papier `#FAF8F4`. Tokens in `:root` van `site-v3/css/style.css`.
   Geen generieke AI-looks (cream+serif+terracotta, paarse gradients).
4. **README-sync:** wijzigingen in typografie/kleuren/structuur ook vastleggen
   in `site-v3/README.md`.

## standaardprompts & skills (bewezen in dit project)

**Engineer (glm-5.3, subagent):** roept vóór UI-werk eerst de skill-tool aan
met de exacte naam `frontend-design`. Prompt-inhoud per batch: de
goedgekeurde punten, de vaste regels hierboven, en "werk in batches, lever
per batch af". Grotere changes: meerdere engineers parallel over
onafhankelijke bestanden (workflow met `agent()`-hooks of losse subagents).

**Reviewer (deepseek-v4-pro):** geef mee (a) de lijst wijzigingen sinds
vorige review, (b) laat hem index.html + style.css volledig lezen, (c) de
rubric: A CSS-correctheid/cascade/specificity, B HTML-geldigheid/aria/refs/
ankers, C toegankelijkheid/contrast (claims laten narekenen), D
huisstijl-en codestijl-consistentie, E rot/restjes. Vraag altijd om
`OORDEEL: GOED / GOED-MET-OPMERKINGEN / AFKEUR` + quick wins, en
"pas niets aan — alleen review".

**Vision-inspectie (two-tier):** routine-checks tijdens iteratie via
`subagent_vision_quick` (zai/glm-5.3-flash, flat-rate); eindoordeel via
`subagent_vision` of ask-vision.ps1 (deepseek-v4-flash-vision-exp,
-MaxTokens ≥ 6000 — het model redeneert vóór het antwoordt). Vraag per sectie
concreet (hiërarchie, witruimte, contrast, huisstijl, storende elementen), noem
secties bij naam, en laat eindigen met "OORDEEL:" + rapportcijfer +
samenvatting. Screenshots > 2000px hoog knippen in plakken van ~1100px met 80px
overlap (assess-final.ps1 heeft daar een Get-Slices-helper).

**Researcher (glm-5.3-flash):** één zelfstandige achtergrondvraag per agent,
antwoord met bronnen, parallel starten aan het begin van de ronde (kan de
web_search-tool gebruiken; deepseek-v4-flash als fallback).

**Beeldgenerator (AI-beelden via Replicate):** gewone subagent die allereerst
de skills `run-models` + `prompt-images` laadt (`prompt-videos` voor video).
Vaste spelregels:
- Token uit `.replicate_token` in de projectroot — nóóit printen of
  committen (staat in `.gitignore`).
- Vóór elke serie: budget checken; zonder expliciete opdracht max ~€0,50 per
  keer, boven €2,-- eerst overleggen met de eigenaar.
- Raw generaties naar `img-gen/` (projectroot, naam als
  ` <onderwerp>-<model>-<n>.png/jpg/webp`); alléén gecureerde assets
  verhuizen naar `site-v3/assets/`, mét alt-tekst en README-sync (regel 4).
- Harde vuistregels: nóóit tekst/letters door het model laten genereren
  (tekst = echte HTML/SVG eroverheen); huisstijlkleuren expliciet in de
  prompt benoemen; `werk-*.jpg` nooit vervangen (regel 2); AI-beelden die
  als "werk" getoond worden zijn impressies → als zodanig labelen.
- Replicate-output-URL's verlopen na 1 uur → direct downloaden naar `img-gen/`.
- PoC en werkwijze staan in de gitgeschiedenis (eerste run: hout-macro,
  flux-schnell, sept. 2026).

**Video (AI-clips):** dezelfde rol, met de skill `prompt-videos` erbij. Ervaring
uit de eerste ronde (hero-video v3, sept. 2026):

- **Altijd frames inspecteren vóór je een clip in de pagina zet.** Een clip kan
  halverwege stukgaan of tekst hallucineren. Bewezen: de eerste roller-clip viel
  bij t=2,5s uit elkaar (losse roller, steel verdwenen) en een tweede poging
  zette pseudotekst in beeld tijdens de overgang. Zonder framestrip zie je dat
  niet — met `_vision/_frames.html` + `screenshot-full.js` wel.
- **Gereedschap en handen deformeren.** Een statisch onderwerp (gevel, muur,
  oppervlak) blijft staan; een roller of kwast valt uit elkaar. Kies bij
  voorkeur een onderwerp zonder werktuig in beeld.
- **Prompt "no text" is niet genoeg**: herhaal het expliciet (no letters, no
  words, no subtitles, no captions, no signage, no watermarks).
- **Eén beweging, geen loop** (projectregel). Laat de clip één keer spelen en op
  het laatste beeld blijven staan; het laatste beeld is de ruststand die de
  bezoeker het langst ziet, dus dat moet een rustig, donker vlak zijn.
- **Reken het contrast na op het begin- én eindbeeld** van de clip
  (`_vision/contrast-check.ps1`, met de tekst even verborgen). Een video
  verandert van helderheid; één meting op één moment zegt niets.
- Modelkeuze via de API, niet uit het hoofd. `prunaai/p-video` kost $0,02 per
  seconde (5 s = $0,10) en ondersteunt begin- én eindbeeld; het beeldformaat
  volgt het aangeleverde beeld ("aspect ratio is ignored when an image is
  provided").
- **Comprimeren:** zet `npm install ffmpeg-static --prefix _tools` neer (staat in
  `.gitignore`; de machine heeft geen systeem-ffmpeg). H.264 met `-crf 28
  -movflags +faststart` bracht 5 MB terug naar 1,2 MB, plus een 640px-variant van
  298 KB voor mobiel.
- AI-video is sfeer, nooit werk van Eef: label het als impressie en zet er geen
  claim bij.
- **Het slotbeeld moet egaal en donker zijn.** Twee pogingen om er meer "fris" of
  meer ambacht in te leggen (natte glanzende verfbaan; haarscherpe afplakrand
  tussen twee olijftinten) zijn verworpen: te licht, of een harde rand die midden
  in de kop valt en als naad leest. Met `object-fit: cover` is zo'n rand niet te
  verplaatsen zonder de video te vergroten (en dus zachter te maken). Wil je toch
  een rand in het slotbeeld, genereer hem dan meteen op ~72% van de bronbreedte.
- **Eigen materiaal uit WhatsApp is klein maar te verbeteren.** Een foto komt
  binnen op ~1600px, een video op 368x368 (zwaar gecomprimeerd). Upscalen werkt,
  met deze ervaring (nov. 2026, `_upscale_media.py`):
  - **Foto's/portretten: `topazlabs/image-upscale`** (alleen `image` meegeven —
    zonder `upscale_factor` verbetert hij 1:1 en houdt gezichten intact).
  - **`prunaai/p-image-upscale` niet gebruiken voor mensen**: met
    `enhance_details`/`enhance_realism` wordt het scherper, maar het gezicht
    verandert zichtbaar (glad, jonger). Alleen voor objecten/textuur.
  - **Video: `prunaai/p-video-upscale` met `target: '1080p'`** werkt goed (echt
    detail terug in kwast, metaal, verfglans). `topazlabs/video-upscale` faalt
    intern met "`source.container` is required" — niet meer proberen.
  - **Daarna altijd zelf comprimeren**: 1440x1440 → 720x720 met crf 30 werd
    188 KB (van 9 MB), plus een posterframe.
  - **Reken eerst op de rate limit**: bij minder dan $5 credit geldt 6
    predictions/minuut met een burst van 1 — start dus niet twee runs naast
    elkaar (kostte een 429).
  - Het echte antwoord blijft: vraag het origineel (niet via WhatsApp), want
    upscalen verzint detail; het maakt iets scherper, niet authentieker.

**Skills:** `frontend-design` (UI-werk, bovenstaande), geen overige nodig;
`cordis-plugin-development` / `editing-cordis-compositions` alleen bij
harness-uitbreidingen; replicate-skills (`run-models`, `prompt-images`,
`prompt-videos`, `find-models`) alleen voor de beeldgenerator-rol.

## testprotocol vóór oplevering (scripts in `_vision/`)

```pwsh
# console-fouten + kapotte afbeeldingen (desktop en mobiel)
node _vision/console-test.js "file:///D:/Projects/Eva Aukema/Studio-Eef/site-v3/index.html" 1280 900
node _vision/console-test.js "file:///D:/Projects/Eva Aukema/Studio-Eef/site-v3/index.html" 390 844

# anker-landing onder de sticky header
node _vision/anchor-test.js werkwijze 390 "file:///D:/Projects/Eva Aukema/Studio-Eef/site-v3/index.html"

# full-page screenshots (daarna vision-check)
node _vision/screenshot-full.js "file:///D:/Projects/Eva Aukema/Studio-Eef/site-v3/index.html" 1280 _vision/check-v3-desktop.png
```

Vision-check: `_vision/ask-vision.ps1 -Image <png> -Vraag "..."`.
Poort-tip: na elkaar gestarte CDP-scripts botsen soms op de debug-poort —
een `Start-Sleep 3` ertussen lost dat op.
Screenshot-CDP en netwerktoegang (api.deepseek.com) werken niet in de confined
sandbox: Chrome heeft named pipes nodig en egress wordt geblokkeerd. Draai die
commando's met volledige toegang.

**Valkuil (kostte een ronde):** raak UTF-8-bestanden nooit aan met
`Get-Content`/`Set-Content` in Windows PowerShell. `Get-Content -Raw` leest UTF-8
als ANSI, waarna `Set-Content -Encoding UTF8` de tekst dubbel codeert (accenten
en streepjes worden mojibake, plus een BOM). Gebruik de edit-tool, of
`[System.IO.File]::ReadAllText`/`WriteAllText`.

## status

- **v3 "Afplakrand" (voorstel, in `site-v3/`)** — sept. 2026, gebouwd nadat de
  eigenaar v1 én v2 allebei afwees ("beide niet mooi") en koos voor een derde
  opzet vanaf de tekentafel: bewust rustig, strak en professioneel. Analyse van
  de afwijzing: v1 en v2 zijn voor ±70% dezelfde pagina, dus het probleem zat in
  de gedeelde visuele taal (druk, gedateerd, decoratie op elk element, logo
  moeilijk leesbaar op 46px); v2's hero was bovendien onaf: de AI-verfstreek-cut-out
  `verfstreek-mosterd.png` bevat een achtergrond/schaduwresidu dat als melkwitte
  waas precies op het focuspunt stond, en de kwastfoto eindigde op `opacity: 0`.
  v3 heeft één idee (egale kleurvlakken met exacte randen = de afplakrand),
  twee lettertypefamilies, **werkt volledig zonder JavaScript** (twee kleine
  scripts: mobiel menu sluiten en de juiste videomaat kiezen), geen
  badges/pillen/halo's/marquee en een mosterdstrook als enige beweging in de
  opmaak. De hero is twee keer opnieuw opgebouwd op verzoek van de eigenaar:
  eerst een gegenereerde **full-screen** clip (Friese gevel → olijf verfvlak,
  1,2 MB, één keer afgespeeld, contrast 10,9:1 en 14,3:1 — staat nog in
  `img-gen/hero-ai-*.mp4`), daarna vervangen door **echt materiaal**: een
  vierkant werkvenster van ±380px rechts naast de kop met de eigen clip van een
  kwast op een kozijn (lus, 382 KB breed / 119 KB smal, poster-fallback). Die
  clip is als volle achtergrond geprobeerd en verworpen: het is een macro-opname
  en werd op 1280px een onherkenbare vlek. Zie de videosectie hierboven voor de
  lessen; scripts `_gen_hero_video.py` en `_upscale_media.py`, kosten van het
  hele videotraject ±$0,40.
  De eigenaar leverde daarna ook losse werkfoto's aan: `eef-bus.jpg` (Over) en
  `kleine-klus.jpg` (Eef met de verfstripper op een kozijn, bij de dienst
  "Onderhoud & kleine klussen"). Beide zijn echte opnames; de werkfoto's in de
  sectie Werk zijn nog steeds AI-impressies (regel 2).
  Kwaliteitsronde: review deepseek-v4-pro **GOED-MET-OPMERKINGEN** (alle vijf
  bevindingen verwerkt: logo-ring uit de voettekst i.p.v. schaduw, title op de
  Bel-placeholders, menu sluit na navigatie, alt-teksten als "Impressie:",
  dode media query weg). Let op voor volgende rondes: de reviewer liep drie keer
  vast in de redenatiefase toen hem ook werd gevraagd contrastgetallen na te
  rekenen; met een smallere opdracht ("vijf bevindingen, max 500 woorden, reken
  geen contrast na") gaf hij binnen één ronde een eindoordeel.
  deepseek-v4-flash-vision-exp **7,5/10 desktop, 8,5/10 mobiel** (rapporten
  `_vision/final-v3-*.txt`, meting via `_vision/assess-v3-final.ps1`). Het
  oordeel over de nieuwe hero is positief ("de nieuwe opbouw werkt", "voelt
  volwassen", "de verhouding tekst/beeld klopt"). Open punten die de meting
  blijft noemen: de sectie Werk (AI-impressies lezen als stock — echte
  werkfoto's ontbreken nog), de kleurenband ("template-divider") en de kleine
  merkdrager (olijfbalk weg op inkt — niet oplosbaar zonder het logo aan te
  passen).
  Let op: de `.todo`-markering is hier een stippellijn in `currentColor` in
  plaats van de mosterd-halo (regel 1).
- **Het logo is heilig (uitspraak eigenaar, 2026-09).** Eefs originele tegel
  wordt **nooit** hertekend, vereenvoudigd of herkleurd — ook niet "voor de
  leesbaarheid op klein formaat". De bron staat byte-identiek in
  `site-v3/assets/logo.svg` (SHA-256 `AE40E7E7…47DE`; het oorspronkelijke
  v2-exemplaar staat in `_archief/site-v2/assets/` en in de gitgeschiedenis).
  Valt de inkt-tegel weg tegen een donkere achtergrond, dan
  lossen we dat op aan de *context* en niet aan het logo: in v3 staat de tegel in
  de kop (34px) en in de voettekst draagt alleen het woordmerk. De Over-sectie
  toont sinds nov. 2026 de echte foto van Eef bij haar bus (het logo staat op de
  bus); de tegel kan daar met één klasse terugkomen. Een eerdere v3-poging met
  een vereenvoudigd merkteken is teruggedraaid.
- **Route A + logo B (live, sept. 2026):** Eefs originele logo-tegel keerde
  terug (olijf-contrastfix #6A7150, 3,18:1 decoratief) in header/Over/favicon
  (bands-variant). Hero kreeg fotorealistisch materiaal via de
  beeldgenerator-pijplijn: eiken plank-foto (hout-macro-final), mosterd
  verfstreek-cut-out (naar #D6AF29 getint), ronde huisschilderskwast-cut-out
  (qwen-3, na vergelijking gehandhaafd boven qwen-4 i.v.m. pseudo-tekst op
  de klem). Kwaliteitsronde: review deepseek-v4-pro
  **GOED-MET-OPMERKINGEN** (quick wins toegepast, incl. herstel TODO-halo's
  op contactwaardes — oorzaak: `class="contact-value todo"` matchte niet op
  naive greps; nu v1-patroon); tester 5/6 PASS (telconventie gepind: **7×
  class="todo" + 5× data-todo = 12 elementen**; commentaar-regels met de
  letterlijke tekst `class="todo"` tellen niet); vision-eindoordeel
  **8,5/10 desktop, 9/10 mobiel** (rapporten `_vision/final-routea-*.txt`).
  Beeldgenerator-totaalkosten heel traject: ±$0,30.
- **v2 "Verse verf" (gearchiveerd in `_archief/site-v2/`, 18-11-2026 uit de
  repo gehaald)** — opgeleverd 2025-09: flitsend redesign
  met kwast-over-hout-hero (signature-animatie), nieuw logo (balkenmotief +
  kwastveeg), trustbar, interactieve kleurengevel, scroll-reveals, mobiele
  CTA-balk. Kwaliteitsronde: review deepseek-v4-pro
  **GOED-MET-OPMERKINGEN** (alle quick wins toegepast: README-sync,
  contrastgetallen 7,8/15,4/5,2/9,7:1, typo, unused id); tester 7/8 PASS
  (enige afwijking was een TODO-telconventie; 13 markeringen = v1-set +
  mobiele Bel-knop, niets ingevuld); vision-eindoordeel
  deepseek-v4-flash-vision-exp **8,5/10 desktop, 9/10 mobiel**
  (rapporten: `_vision/final-v2-desktop.txt`, `_vision/final-v2-mobile.txt`;
  eindmeting via `_vision/assess-final-v2.ps1`). Ontwerpbrief:
  `site/ONTWERP-V2.md` (incl. onderzoeksinput) — staat in het archief.
- v1 (gearchiveerd in `_archief/site-v1/`): laatste review deepseek-v4-pro
  **GOED** — 2025-10, nulmeting 8/10 desktop en 8,5/10 mobiel (rapporten in
  `_vision/*.txt`).
- **GitHub:** nieuwe repo `nielslagas/studio-eef-v2` (main = heel dit project,
  gh-pages = alleen de site zelf) — live voor Eef:
  **<https://nielslagas.github.io/studio-eef-v2/>**. De oude v1-repo
  `nielslagas/studio-eef` is onaangeroerd gelaten; de oude lokale .git staat
  in `.git-v1-backup/` (ge-ignored).
- Open voor de eigenaar: de TODO-placeholders uit regel 1 hierboven.
- Optioneel batch C: e-opening in logo.svg voor echt 24px-gebruik, echte
  Archivo-glyph-paden in de wordmark, gevoelscheck mobiel op echt apparaat
  (safe-area + reveal-timing).
