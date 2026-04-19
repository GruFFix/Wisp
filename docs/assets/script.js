// ═══════════════════════════════════════════════════════════════════════
// WISP — Landing interactions
// - single full-viewport particle field (fixed canvas)
// - cursor-reactive wake
// - theme switching with smooth palette interpolation
// - scroll-driven ambient gradient morph
// - intersection-observer reveals
// - scroll progress + nav glass state
// ═══════════════════════════════════════════════════════════════════════

// ─── Reveal-on-scroll ──────────────────────────────────────────────────

const io = new IntersectionObserver(entries => {
  entries.forEach(e => {
    if (e.isIntersecting) {
      e.target.classList.add('in');
      io.unobserve(e.target);
    }
  });
}, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });

document.querySelectorAll('.reveal').forEach(el => io.observe(el));

// ─── Scroll progress + nav scrolled state + ambient color morph ────────

const progressEl = document.getElementById('scrollProgress');
const navEl      = document.getElementById('nav');

// Ambient color stops — each stop has 4 rgba triplets (one per radial blob).
// Colors interpolate smoothly between adjacent stops as you scroll.
const AMB_STOPS = [
  // t=0   Hero — Aurora (green/cyan/purple ambient)
  { t: 0.00, c: [[ 26, 240, 140], [  0, 208, 240], [160,  32, 240], [ 76, 140, 255]] },
  // t=0.18  Manifesto — purple hush
  { t: 0.18, c: [[139,  92, 246], [168,  85, 247], [ 76, 140, 255], [236,  72, 153]] },
  // t=0.38  Themes — rose / warm
  { t: 0.38, c: [[236,  72, 153], [245, 165,  36], [168,  85, 247], [139,  92, 246]] },
  // t=0.58  Control — deep violet / cyan
  { t: 0.58, c: [[168,  85, 247], [  6, 212, 255], [139,  92, 246], [236,  72, 153]] },
  // t=0.78  Details — cyan / blue clarity
  { t: 0.78, c: [[  6, 212, 255], [ 76, 140, 255], [168,  85, 247], [236,  72, 153]] },
  // t=1.0   CTA — golden finale
  { t: 1.00, c: [[245, 165,  36], [236,  72, 153], [168,  85, 247], [  6, 212, 255]] },
];
const AMB_ALPHAS = [0.22, 0.17, 0.16, 0.14];  // strength per blob

function mix(a, b, t) { return [
  (a[0] * (1 - t) + b[0] * t) | 0,
  (a[1] * (1 - t) + b[1] * t) | 0,
  (a[2] * (1 - t) + b[2] * t) | 0,
]; }

function updateAmbient(p) {
  // find bracket
  let i = 0;
  while (i < AMB_STOPS.length - 1 && AMB_STOPS[i + 1].t < p) i++;
  const a = AMB_STOPS[i];
  const b = AMB_STOPS[Math.min(i + 1, AMB_STOPS.length - 1)];
  const span = Math.max(1e-6, b.t - a.t);
  const tt = Math.max(0, Math.min(1, (p - a.t) / span));
  const root = document.documentElement.style;
  for (let k = 0; k < 4; k++) {
    const rgb = mix(a.c[k], b.c[k], tt);
    root.setProperty(`--amb-${k + 1}`, `rgba(${rgb[0]}, ${rgb[1]}, ${rgb[2]}, ${AMB_ALPHAS[k]})`);
  }
}

function onScroll() {
  const max = document.body.scrollHeight - window.innerHeight;
  const p   = max > 0 ? Math.min(1, window.scrollY / max) : 0;
  progressEl.style.transform = `scaleX(${p})`;
  navEl.classList.toggle('scrolled', window.scrollY > 40);
  updateAmbient(p);
}
window.addEventListener('scroll', onScroll, { passive: true });
onScroll();

// ─── Cursor glow follow ────────────────────────────────────────────────

const cursor = document.getElementById('cursorGlow');
let cx = window.innerWidth / 2, cy = window.innerHeight / 2;
let tx = cx, ty = cy;
window.addEventListener('mousemove', e => { tx = e.clientX; ty = e.clientY; });
function tickCursor() {
  cx += (tx - cx) * 0.15;
  cy += (ty - cy) * 0.15;
  cursor.style.transform = `translate(${cx}px, ${cy}px) translate(-50%, -50%)`;
  requestAnimationFrame(tickCursor);
}
tickCursor();

// ─── Particle engine (shared between hero & cta canvases) ──────────────

const THEMES = [
  ['#F0A500', '#FF6B00', '#FFE566'], // Golden
  ['#FF73B3', '#FF3366', '#FF99CC'], // Rose
  ['#E0E8FF', '#B0C8FF', '#88AAFF'], // Moonlight
  ['#1AF08C', '#00D0F0', '#A020F0'], // Aurora
  ['#4D8CFF', '#00D4FF', '#1A4FE6'], // Sapphire
  ['#FF6EFF', '#7B61FF', '#00FFC8']  // Custom (showcase)
];

// Particle archetypes — mirror the app's CAEmitter setup: aura → near → mote → spark → dot.
// Weights determine spawn probability. Sizes in px, speeds in px/frame, life in frames.
const TYPES = [
  // name   weight  size       speed          life         accelY    alpha  hasCore  haloMul
  { n: 'aura',  w:  2, sz: [4.0, 7.5], sp: [0.008, 0.045], lf: [1200, 2000], ay: -0.0018, a: 0.22, core: false, halo: 4.2 },
  { n: 'near',  w:  5, sz: [1.6, 3.2], sp: [0.020, 0.090], lf: [ 600, 1200], ay: -0.0040, a: 0.55, core: true,  halo: 3.6 },
  { n: 'mote',  w: 14, sz: [0.9, 1.8], sp: [0.016, 0.080], lf: [ 650, 1250], ay: -0.0044, a: 0.65, core: true,  halo: 3.2 },
  { n: 'spark', w: 22, sz: [0.5, 1.0], sp: [0.012, 0.065], lf: [ 800, 1400], ay: -0.0052, a: 0.75, core: true,  halo: 2.8 },
  { n: 'dot',   w: 35, sz: [0.25,0.55],sp: [0.008, 0.045], lf: [1200, 2000], ay: -0.0052, a: 0.85, core: false, halo: 2.2 },
];
const TOTAL_WEIGHT = TYPES.reduce((s, t) => s + t.w, 0);

class ParticleField {
  constructor(canvas, opts = {}) {
    this.canvas   = canvas;
    this.ctx      = canvas.getContext('2d');
    this.themeIdx = opts.themeIdx ?? 3;
    this.palette        = THEMES[this.themeIdx];
    this.paletteActual  = [...this.palette];
    this.paletteFrom    = [...this.palette];
    this.transitionT    = 1;
    this.densityFactor  = opts.density ?? 1.0;
    this.particles      = [];

    this.resize();
    window.addEventListener('resize', () => this.resize());
    requestAnimationFrame(this.tick.bind(this));
  }

  resize() {
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    const w = this.canvas.offsetWidth  || window.innerWidth;
    const h = this.canvas.offsetHeight || window.innerHeight;
    this.canvas.width  = w * dpr;
    this.canvas.height = h * dpr;
    this.ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    this.w = w; this.h = h;
  }

  pickType() {
    let r = Math.random() * TOTAL_WEIGHT;
    for (const t of TYPES) { r -= t.w; if (r <= 0) return t; }
    return TYPES[TYPES.length - 1];
  }

  pickColor() {
    return this.paletteActual[(Math.random() * this.paletteActual.length) | 0];
  }

  spawn(initialLife = false) {
    const t = this.pickType();
    const angle = Math.random() * Math.PI * 2;               // spawn in random direction
    const speed = t.sp[0] + Math.random() * (t.sp[1] - t.sp[0]);
    const life  = t.lf[0] + Math.random() * (t.lf[1] - t.lf[0]);
    const size  = t.sz[0] + Math.random() * (t.sz[1] - t.sz[0]);
    this.particles.push({
      x: Math.random() * this.w,
      y: Math.random() * this.h,
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed,
      ay: t.ay,
      size,
      life:    initialLife ? life * (0.2 + Math.random() * 0.6) : life,
      maxLife: life,
      maxAlpha: t.a,
      alpha: 0,
      color: this.pickColor(),
      core:  t.core,
      halo:  t.halo,
    });
  }

  setTheme(idx) {
    if (idx === this.themeIdx) return;
    this.paletteFrom = [...this.paletteActual];
    this.themeIdx = idx;
    this.palette  = THEMES[idx];
    this.transitionT = 0;
  }

  updatePalette(dt) {
    if (this.transitionT >= 1) return;
    this.transitionT = Math.min(1, this.transitionT + dt * 0.8);
    this.paletteActual = this.palette.map(
      (c, i) => mixHex(this.paletteFrom[i % this.paletteFrom.length], c, this.transitionT)
    );
  }

  targetCount() {
    // Scale with viewport area (baseline: 1920×1080 → 360 particles).
    const base = 360 * this.densityFactor;
    return Math.min(520, Math.round(base * (this.w * this.h) / (1920 * 1080)));
  }

  tick(now) {
    requestAnimationFrame(this.tick.bind(this));
    const dt = this.lastT ? Math.min(2.5, (now - this.lastT) / 16.67) : 1;
    this.lastT = now;
    this.updatePalette(dt * 0.016);

    const ctx = this.ctx;
    ctx.clearRect(0, 0, this.w, this.h);
    ctx.globalCompositeOperation = 'lighter';  // additive — overlapping glows brighten

    // Pre-fill with life already in progress so we never see a build-up
    if (this.particles.length === 0) {
      const tc = this.targetCount();
      for (let i = 0; i < tc; i++) this.spawn(true);
    }
    const target = this.targetCount();
    while (this.particles.length < target) this.spawn(false);

    for (let i = this.particles.length - 1; i >= 0; i--) {
      const p = this.particles[i];

      p.vy += p.ay * dt;
      p.vx *= 0.995;
      p.vy *= 0.995;
      p.x  += p.vx * dt;
      p.y  += p.vy * dt;
      p.life -= dt;

      if (p.life <= 0 || p.y < -40 || p.x < -40 || p.x > this.w + 40) {
        this.particles.splice(i, 1);
        continue;
      }

      // fade-in over first 25 % of life, fade-out over last 35 %
      const age = p.maxLife - p.life;
      const inF  = Math.min(1, age / (p.maxLife * 0.25));
      const outF = Math.min(1, p.life / (p.maxLife * 0.35));
      p.alpha = Math.max(0, Math.min(inF, outF)) * p.maxAlpha;

      this.drawParticle(p);
    }

    ctx.globalCompositeOperation = 'source-over';
  }

  drawParticle(p) {
    const ctx = this.ctx;
    const rOuter = p.size * p.halo;

    // outer halo — soft falloff, main color
    const g = ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, rOuter);
    g.addColorStop(0.00, p.color + alphaHex(p.alpha * 0.55));
    g.addColorStop(0.35, p.color + alphaHex(p.alpha * 0.22));
    g.addColorStop(1.00, p.color + '00');
    ctx.fillStyle = g;
    ctx.beginPath(); ctx.arc(p.x, p.y, rOuter, 0, Math.PI * 2); ctx.fill();

    // bright white core
    if (p.core) {
      ctx.fillStyle = '#ffffff' + alphaHex(p.alpha * 0.70);
      ctx.beginPath(); ctx.arc(p.x, p.y, p.size * 0.55, 0, Math.PI * 2); ctx.fill();
    }
  }
}

// convert hex + alpha 0..1 to 2-char hex
function alphaHex(a) {
  const v = Math.max(0, Math.min(1, a));
  return ((v * 255) | 0).toString(16).padStart(2, '0');
}

// mix two #RRGGBB colors at t in [0..1]
function mixHex(a, b, t) {
  const pa = hexToRgb(a), pb = hexToRgb(b);
  const r = (pa[0] * (1 - t) + pb[0] * t) | 0;
  const g = (pa[1] * (1 - t) + pb[1] * t) | 0;
  const bl = (pa[2] * (1 - t) + pb[2] * t) | 0;
  return '#' + [r, g, bl].map(v => v.toString(16).padStart(2, '0')).join('');
}
function hexToRgb(h) {
  h = h.replace('#', '');
  if (h.length === 3) h = h.split('').map(c => c + c).join('');
  return [0, 2, 4].map(i => parseInt(h.slice(i, i + 2), 16));
}

// ─── Instantiate single global particle field ──────────────────────────

const bgField = new ParticleField(document.getElementById('bgCanvas'), {
  themeIdx: 3, density: 1.0
});

// Auto-rotate themes every 9s — stops after user picks one
let autoRotate = true;
let autoIdx = 3;
setInterval(() => {
  if (!autoRotate) return;
  autoIdx = (autoIdx + 1) % THEMES.length;
  bgField.setTheme(autoIdx);
  setActiveThemeCard(autoIdx);
}, 9000);

// ─── Theme cards ───────────────────────────────────────────────────────

function setActiveThemeCard(idx) {
  document.querySelectorAll('.theme-card').forEach(c => {
    c.classList.toggle('is-active', parseInt(c.dataset.theme, 10) === idx);
  });
  // Also reflect in the mockup swatches (just visual)
  const mockupSwatches = document.querySelectorAll('.app-swatches .swatch');
  mockupSwatches.forEach((s, i) => s.classList.toggle('active', i === idx));
}

document.querySelectorAll('.theme-card').forEach(card => {
  card.addEventListener('click', () => {
    const idx = parseInt(card.dataset.theme, 10);
    autoRotate = false;
    bgField.setTheme(idx);
    setActiveThemeCard(idx);
  });
});

// Initial highlight
setActiveThemeCard(3);

// ─── 3D tilt on app mockup ─────────────────────────────────────────────

(() => {
  const frame   = document.querySelector('.app-frame');
  const section = document.getElementById('control');
  if (!frame || !section) return;

  const MAX_TILT = 9;  // degrees
  let raf = 0;

  section.addEventListener('mousemove', e => {
    if (raf) cancelAnimationFrame(raf);
    raf = requestAnimationFrame(() => {
      const r  = frame.getBoundingClientRect();
      const mx = (e.clientX - (r.left + r.width  / 2)) / (r.width  * 0.8);
      const my = (e.clientY - (r.top  + r.height / 2)) / (r.height * 0.8);
      const rx = Math.max(-1, Math.min(1, my)) * -MAX_TILT;  // rotateX flips Y
      const ry = Math.max(-1, Math.min(1, mx)) *  MAX_TILT;
      frame.style.transform = `perspective(1200px) rotateX(${rx}deg) rotateY(${ry}deg)`;
    });
  });
  section.addEventListener('mouseleave', () => {
    frame.style.transform = 'perspective(1200px) rotateX(0deg) rotateY(0deg)';
  });
})();
