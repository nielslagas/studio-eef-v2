# Ontwerpbrief v3 — "Afplakrand" (rustig, strak, professioneel)

Derde opzet, vanaf de tekentafel. Opdracht van de eigenaar (2026-09): v1
(huisje met kleurstaal) en v2 ("Verse verf" met donkere AI-kwasthero) zijn
allebei afgewezen als niet mooi. Gevraagd is nu: **bewust rustig, strak en
professioneel**. Dit is een voorstel ter beoordeling — niet live, niet
gepromoveerd; v2 staat nog in `site/`.

## Waarom de eerste twee niet werkten (analyse)

Beide versies zijn voor ongeveer zeventig procent dezelfde pagina: dezelfde
dienstenkaarten, dezelfde impressies, dezelfde werkwijze, dezelfde
contactblokken. Ze verschillen vooral in de hero en het canvas. Het probleem zat
dus niet in de keuze tussen de twee, maar in de gedeelde visuele taal:

- **v2:** de hero (het middelpunt van de pagina) was niet af. De kop liep over de
  houtfoto en viel deels op de inkt-achtergrond; achter "laag verf" lagen twee
  gele vlakken die net niet samenvielen (een platte mosterd-basislak plus een
  AI-verfstreek met `object-fit: cover`); de rechterkant van die streek was geen
  verf maar een melkwitte waas — dat residu zat ín
  `assets/img/verfstreek-mosterd.png`. De kwastfoto eindigde op `opacity: 0`,
  waardoor juist het mooiste idee (de kwastslag) in de eindstand onzichtbaar was.
- **v1:** rustig en leesbaar, maar het huisje is vlakke clipart naast
  professionele foto's — precies de "skeuomorfe huisje/verfblik-look" die het
  benchmarkonderzoek in `ONTWERP-V2.md` zelf als cliché aanmerkt.
- **Beide:** decoratie op vrijwel elk element (EEF-01 badges, ponsgaatjes,
  IMPRESSIE-pillen, mosterd-halo's, marquee, gouden muntjes als cijfers) en een
  logo dat op zijn echte formaat (46px) niet leesbaar is: de verticale
  STUDIO-letters in olijf `#6A7150` op inkt vallen weg.

## Het idee

Schilderwerk is pas professioneel als de **rand** klopt: de strakke lijn die
overblijft als de afplaktape eraf gaat. Dat is het hele ontwerp:

1. **Egale kleurvlakken met exacte randen.** Secties zijn geschilderde vlakken
   die elkaar in rechte lijnen raken: papier → kalkwit → inkt → papier → olijf →
   inkt. Geen rondingen, geen schaduwen, geen gradients als versiering.
2. **Eén grafisch gebaar:** de mosterdstrook achter "laag verf" in de hero,
   één keer aangebracht (820 ms, links naar rechts). Geen tweede animatie, geen
   scroll-reveals, geen loops.
3. **Het balkenmotief van het merk op paginaschaal:** de kleurenband onder de
   hero is het logo, uitvergroot. Dat draagt de identiteit zonder extra
   decoratie.
4. **Het etiket van de verfpot als layout:** een smalle labelkolom links, de
   inhoud rechts. Rustig, zakelijk, en het herhaalt zich in elke sectie.

## Tokens

Huisstijl (regel 3, ongewijzigd): olijf `#424631`, mosterd `#D6AF29`, roze
`#F37C96`, inkt `#231F20`, papier `#FAF8F4`.

Gedocumenteerde afgeleiden — alleen voor oppervlakken, nooit als nieuwe
merkkleur:

| Token | Waarde | Gebruik | Contrast |
| --- | --- | --- | --- |
| `--kalk` | `#F1EDE4` | "vers geschilderd" sectievlak | inkt erop 14,0:1 |
| `--mosterd-diep` | `#C39D1F` | natte rand onderaan de mosterdstrook | — |
| `--olijf-op-inkt` | `#7E8663` | olijf balk in het merkteken | 4,3:1 decoratief |
| `--inkt-14` | `rgba(35,31,32,.14)` | hagen (scheidingslijnen) | — |
| `--inkt-zwak` | `rgba(35,31,32,.68)` | labels, noten, captions | 5,3:1 op papier én kalk |
| `--papier-68` | `rgba(250,248,244,.68)` | labels op donker | 5,3:1 op olijf, 7,5:1 op inkt |
| `--papier-78` | `rgba(250,248,244,.78)` | lopende tekst op donker | 9,8:1 op inkt |

Kleurstelling per sectie: **maximaal één accent per vlak.** Roze komt alleen
voor als strook van 3% in de kleurenband en in het merkteken — nooit als kaart
of vlak. Mosterd is accent (strook, stapnummers, primaire knop), nooit
kleine tekst op licht.

## Typografie

Twee families, geen derde:

- **Archivo** (display, weight 600/700, `font-stretch: 112%`) voor koppen,
  labels, knoppen en waarden. Krappe tracking (`-0.02em`).
- **Atkinson Hyperlegible** voor lopende tekst — een bewuste keuze: een
  hyperlegaar lettertype past bij een ambachtelijk bedrijf dat door
  niet-ontwerpers gelezen wordt.

IBM Plex Mono uit v1/v2 is geschrapt: mono-labels gaven een derde stem zonder
informatie toe te voegen. Labels zijn nu Archivo, uppercase, 0,16em gespatieerd.

## Layout

- Container 1140px, gutter `clamp(20px, 4vw, 40px)`, sectie-ritme
  `clamp(72px, 9vw, 132px)`.
- `.split`: labelkolom links (140–180px), inhoud rechts. Vanaf 900px.
- Diensten: **rijen met hagen**, geen kaarten (titel links, tekst rechts). De
  derde dienst ("Onderhoud & kleine klussen") heeft als enige een kleine foto
  (240px, 3:2): Eef met de verfstripper op een kozijn. Bewust één uitzondering,
  want juist bij die dienst weten mensen niet wat ze kunnen verwachten.
- Werk: de enige foto's, drie naast elkaar met 1px voegen, captions eronder.
- Werkwijze: inkt, vijf kolommen, nummers in mosterd — nummers mogen hier, want
  het is een echte volgorde.
- Contact: olijf met een 5px mosterdrand bovenaan (de tape-lijn), drie
  tekstblokken met hagen.
- Over: **echte foto van Eef naast haar bus**, volle breedte van de tekstkolom in
  het originele 4:3-kader — het logo staat op de bus, dus het merk blijft in
  beeld zonder dat er aan het logo gesleuteld wordt. Een vierkante uitsnede werd
  door de eigenaar afgewezen (die haalde de compositie weg). De foto is door
  WhatsApp gecomprimeerd tot 1600x1200 en daarna met `topazlabs/image-upscale`
  opgeknapt (1:1, geen gezichtsverandering).
- Mobiel (≤700px): vaste actiebalk onderaan met Bel + Offerte.

## Hero

Kop in drie regels: "Een frisse" / **mosterdstrook met "laag verf"** /
"voor je huis.". De strook is een blok met `min-width: 62%`, dus breder dan de
woorden: daardoor leest het als een geschilderde strook en niet als een
marker-highlight (dat was de opmerking in de eerste vision-meting). De
kleurenband eronder is het merkteken op paginaschaal.

Motion: alleen die ene strook, `clip-path: inset(0 100% 0 0)` → `inset(0)`,
820 ms met 260 ms vertraging. `prefers-reduced-motion`: direct de eindstand.
Verder uitsluitend hover/focus-microinteracties (≤160 ms).

### De video in de hero (op verzoek van de eigenaar, sept.–nov. 2026)

Twee rondes, met een duidelijke conclusie.

**Ronde 1 — gegenereerd, full-screen.** Eerst is een header met een full-screen
video gemaakt (`_gen_hero_video.py`: gevel van een Fries huis → langzame push-in →
dissolve naar een egaal olijfvlak; 1,2 MB). Die is gemeten (contrast 10,9:1 op het
beginbeeld en 14,3:1 op het eindbeeld) en beoordeeld (vision 7,5 / 8,5). Lessen die
blijven staan: één beweging, geen loop; het slotbeeld is de ruststand die de
bezoeker het langst ziet, dus dat moet egaal en donker zijn; en een detail in dat
slotbeeld werkt alleen als het op het raster uitlijnt.

**Ronde 2 — echt materiaal in een vierkant venster (huidige versie).** De eigenaar
leverde eigen opnames aan, waaronder een clip van een hand die met een kwast een
kozijn schildert. Als volle achtergrond werkt die niet: het is een macro-opname van
ongeveer 20 cm, en op 1280px breedte wordt het een onherkenbare donkere vlek —
geprobeerd en verworpen. Daarom staat de clip nu als **vierkant venster van ±380px
rechts naast de kop**, op een effen inktvlak:

- het is **echt werk**, geen impressie: hand en kwast zijn zichtbaar;
- de lus is hier wél verdedigbaar — de streek herhaalt zichzelf en de camera staat
  stil, dus er is geen storende naad (anders dan bij een doorlopende beweging);
- het bronbestand kwam via WhatsApp binnen op 368x368, is met
  `prunaai/p-video-upscale` naar 1440px gebracht en daarna teruggecomprimeerd:
  1080px = 382 KB, 540px = 119 KB, poster 48 KB;
- zonder JavaScript of bij `prefers-reduced-motion` staat de poster stil;
- de mosterdstrook blijft de signature: die staat los van het beeld en beweegt niet
  mee.

De AI-clip van ronde 1 staat nog in `img-gen/hero-ai-*.mp4` en is met één
bestandsverwisseling terug te zetten.

## Wat er expliciet niet in zit

Geen JavaScript nodig (de pagina werkt volledig zonder; twee kleine scripts:
het mobiele menu sluiten en de juiste videomaat kiezen), geen marquee, geen
badges of codes, geen pillen, geen TODO-halo's (de placeholders kregen een
stippellijn in `currentColor` — nog steeds zichtbaar, veel rustiger), geen kaarten
met schaduwen, geen rondingen, geen scroll-reveals. De werkclip loopt in een lus,
maar staat stil bij `prefers-reduced-motion`; daarnaast is er geen tweede beweging
die blijft doorradelen.

## Open punten voor de eigenaar

1. **Het merkteken is onaangeroerd.** v3 gebruikt `assets/logo.svg` — Eefs
   originele tegel, één-op-één gekopieerd uit `site/assets/` — in de kop (34px)
   en groot in de Over-sectie (118px). Er is niets hertekend, herkleurd of
   weggelaten. De inkt-tegel valt weg tegen een inkt-achtergrond, dus de
   voettekst draagt alleen het woordmerk; het logo zelf blijft met rust. In een
   eerdere versie van dit voorstel was het merkteken vereenvoudigd (zonder de
   verticale STUDIO-letters); dat is teruggedraaid omdat het originele logo voor
   Eef heilig is. Het bestand is byte-identiek aan dat van v2 (SHA-256
   `AE40E7E7…47DE`), zodat er nooit twee logo-versies kunnen ontstaan.
2. **Echte werkfoto's.** De drie `werk-*.jpg` zijn AI-impressies en dat is de
   zwakste plek van de pagina (ook volgens de vision-meting). Regel 2 verbiedt
   vervangen zonder opdracht; echte foto's zijn de grootste kwaliteitssprong.
3. **De kleurenband.** Bewust behouden als merk-drager, maar het is het meest
   decoratieve element op de pagina. Schrappen kan.
4. **Copy** is ongewijzigd overgenomen uit v1/v2 (inclusief de TODO's).
