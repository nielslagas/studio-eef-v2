/* ============================================================
   Studio EEF — v2 hoofdscript (vanilla, geen libraries)

   1. Header: subtiel donkerder/compacter bij scrollen.
   2. Hero-signature "kwast over hout": één slag bij load.
      - mode "css": offset-path + CSS-animaties (kwast, wipe, glans,
        druppel) met gelijke duur/curve/start → synchroon.
      - mode "js": fallback met getPointAtLength + rAF, zelfde
        easing-curve in JS, kwast én wipe uit één progress-waarde.
      - geen data-hero (reduced motion / geen JS): eindstand, niets doen.
   3. Kleuren: verfstalen herschilderen de gevel (aria-live naam).
   ============================================================ */
(function () {
  'use strict';

  var html = document.documentElement;

  /* ---------- 1. header bij scrollen ---------- */

  var header = document.querySelector('.header');
  if (header) {
    var bijScroll = function () {
      header.classList.toggle('scrolled', window.scrollY > 10);
    };
    window.addEventListener('scroll', bijScroll, { passive: true });
    bijScroll();
  }

  /* ---------- 2. hero-signature ---------- */

  function heroSignature() {
    var mode = html.getAttribute('data-hero');
    if (!mode) return; // reduced motion of geen animatie: eindstand staat al

    var kunst = document.querySelector('.hero-kunst');
    var titel = document.querySelector('.hero-title');
    var kwast = document.querySelector('.kwast');
    var padPad = document.getElementById('veeg-pad-pad');
    if (!kunst || !titel || !kwast || !padPad) return;

    var DUUR = 2200; // ms, gelijk aan --veeg-duur
    var START = 250; // ms, gelijk aan --veeg-start
    var klaar = false;

    function padString(w, h) {
      // één vloeiende slag: links iets boven de tekstlijn, door het
      // midden (waar de streek valt), rechts iets eronder uit
      return 'M ' + (-90) + ' ' + (h * 0.24) +
        ' C ' + (w * 0.32) + ' ' + (h * 0.02) +
        ', ' + (w * 0.62) + ' ' + (h * 0.84) +
        ', ' + (w + 90) + ' ' + (h * 0.5);
    }

    function naarEindstand() {
      klaar = true;
      titel.style.clipPath = 'inset(0 0 0 0)';
      kwast.style.opacity = '0';
      kwast.style.willChange = 'auto'; // will-change alleen tijdens de animatie
      if (mode === 'css') {
        // lopende CSS-animaties naar hun eindframe springen
        titel.getAnimations().forEach(function (a) { a.finish(); });
        kwast.getAnimations().forEach(function (a) { a.finish(); });
      }
    }

    function startCss() {
      var box = kunst.getBoundingClientRect();
      kwast.style.offsetPath = 'path("' + padString(box.width, box.height) + '")';
      requestAnimationFrame(function () {
        kunst.classList.add('speelt'); // start kwast + wipe + glans + druppel
      });
      window.setTimeout(function () { klaar = true; }, START + DUUR + 200);
    }

    /* cubic-bezier(0.77, 0, 0.175, 1) in JS — Newton + valback op bisectie */
    function bezierOplosser(x1, y1, x2, y2) {
      function px(t) { return 3 * (1 - t) * (1 - t) * t * x1 + 3 * (1 - t) * t * t * x2 + t * t * t; }
      function py(t) { return 3 * (1 - t) * (1 - t) * t * y1 + 3 * (1 - t) * t * t * y2 + t * t * t; }
      return function (x) {
        var lo = 0, hi = 1, t = x;
        for (var i = 0; i < 24; i++) {
          var v = px(t) - x;
          if (Math.abs(v) < 1e-5) { break; }
          if (v > 0) { hi = t; } else { lo = t; }
          t = (lo + hi) / 2;
        }
        return py(t);
      };
    }

    function startJs() {
      var box = kunst.getBoundingClientRect();
      padPad.setAttribute('d', padString(box.width, box.height));
      var lengte = padPad.getTotalLength();
      var tipX = kwast.offsetWidth * 0.10;  // haarpunt linksonder = offset-anchor
      var tipY = kwast.offsetHeight * 0.75;
      var ease = bezierOplosser(0.77, 0, 0.175, 1); // --ease-in-out
      var startOp = performance.now() + START;

      titel.style.clipPath = 'inset(0 100% 0 0)';
      kwast.style.opacity = '1';

      function frame(nu) {
        if (klaar) { return; }
        var p = Math.min(Math.max((nu - startOp) / DUUR, 0), 1);
        var e = ease(p);
        var punt = padPad.getPointAtLength(lengte * e);
        kwast.style.transform =
          'translate(' + (punt.x - tipX) + 'px, ' + (punt.y - tipY) + 'px)';
        titel.style.clipPath = 'inset(0 ' + ((1 - e) * 100).toFixed(3) + '% 0 0)';
        if (p < 1) {
          requestAnimationFrame(frame);
        } else {
          naarEindstand(); // glans + druppel lopen via CSS (.speelt)
        }
      }

      kunst.classList.add('speelt');
      requestAnimationFrame(frame);
    }

    // wacht kort op de fonts (display=swap) zodat de wipe niet halverwege
    // van fallback-lettertype wisselt; max 600 ms, daarna toch starten
    var fontsKlaar = (document.fonts && document.fonts.ready) || Promise.resolve();
    Promise.race([fontsKlaar, new Promise(function (r) { window.setTimeout(r, 600); })])
      .then(function () {
        window.setTimeout(function () {
          if (klaar) { return; }
          if (mode === 'css') { startCss(); } else { startJs(); }
        }, 120);
      });

    // midden in de slag van formaat wisselen (rotate/resize): spring naar
    // de eindstand in plaats van met een verlopen pad door te schilderen
    window.addEventListener('resize', function () {
      if (!klaar) { naarEindstand(); }
    }, { passive: true });
  }

  /* ---------- 3. kleuren: gevel herschilderen ---------- */

  function gevelStalen() {
    var kaart = document.querySelector('.facade-card');
    var wand = document.querySelector('.wand'); // inline fill: leesbaar voor de testtooling
    var band = document.querySelector('.facade-band');
    var naam = document.querySelector('.facade-naam');
    var stalen = Array.prototype.slice.call(document.querySelectorAll('.swatch'));
    if (!stalen.length || !kaart) return;

    function kies(btn) {
      stalen.forEach(function (s) {
        s.setAttribute('aria-pressed', String(s === btn));
      });
      // één --staal stuurt wand, kozijnen én deur (CSS regelt de tinten)
      kaart.style.setProperty('--staal', btn.getAttribute('data-color'));
      if (wand) { wand.style.fill = btn.getAttribute('data-color'); }
      if (band) {
        band.style.setProperty('--band', btn.getAttribute('data-color'));
        band.classList.toggle('facade-band--donker', btn.getAttribute('data-contrast') === 'donker');
      }
      if (naam) { naam.textContent = btn.getAttribute('aria-label'); }
    }

    stalen.forEach(function (btn) {
      btn.addEventListener('click', function () { kies(btn); });
    });

    // startmosterd: de laag die er nu in zit
    if (stalen[1]) { kies(stalen[1]); }
  }

  /* ---------- 4. scroll-reveals: één keer, dan unobserve ----------
     Initial hidden staat alléén onder html.js-reveal (gezet in de
     <head>, weggehaald bij falen) → zonder JS is alles zichtbaar. */

  function scrollReveals() {
    var items = document.querySelectorAll('[data-reveal]');
    if (!items.length) { html.classList.remove('js-reveal'); return; }
    if (!('IntersectionObserver' in window)) { html.classList.remove('js-reveal'); return; }

    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add('zichtbaar');
          io.unobserve(entry.target); // one-shot: geen herhaling, geen loop
        }
      });
    }, { threshold: 0.15, rootMargin: '0px 0px -6% 0px' });

    items.forEach(function (el) { io.observe(el); });

    // Vangnet: IO herrekent niet op CDP-geëmuleerde viewport-resizes
    // (headless captures). Zelfde criterium, handmatig toegepast.
    function handmatigeCheck() {
      items.forEach(function (el) {
        if (el.classList.contains('zichtbaar')) { return; }
        var r = el.getBoundingClientRect();
        if (r.top < window.innerHeight * 0.94 && r.bottom > 0) {
          el.classList.add('zichtbaar');
          io.unobserve(el);
        }
      });
    }
    window.addEventListener('resize', function () {
      window.setTimeout(handmatigeCheck, 150);
    }, { passive: true });
  }

  /* ---------- 5. mobiele CTA-balk ----------
     Verdwijnt zodra #contact in beeld komt; reduced motion toont
     de balk simpel (CSS zet de transitie uit). */

  function mobieleCta() {
    var balk = document.querySelector('.mobiel-cta');
    var contact = document.getElementById('contact');
    if (!balk || !contact || !('IntersectionObserver' in window)) return;

    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        balk.classList.toggle('weg', entry.isIntersecting);
      });
    }, { threshold: 0.12 });
    io.observe(contact);
  }

  try {
    heroSignature();
  } catch (e) {
    // nooit de kop verborgen laten als er iets misgaat
    var titel = document.querySelector('.hero-title');
    var kwast = document.querySelector('.kwast');
    if (titel) { titel.style.clipPath = 'inset(0 0 0 0)'; }
    if (kwast) { kwast.style.opacity = '0'; }
  }

  try {
    gevelStalen();
  } catch (e) { /* stalen blijven gewoon klikbaar-kleurloos: gevel toont mosterd */ }

  try {
    scrollReveals();
  } catch (e) {
    // zonder werkende reveals: alles gewoon zichtbaar laten
    html.classList.remove('js-reveal');
  }

  try {
    mobieleCta();
  } catch (e) { /* balk blijft dan gewoon staan — veilige fallback */ }
})();
