// ── i18n ──────────────────────────────────────────────────────────────────

const translations = {
  en: {
    'nav.download':  'Download',
    'hero.badge':    '✦ Free for macOS',
    'hero.h1':       'Your desktop,<br>alive.',
    'hero.p':        'Wisp adds beautiful ambient particle effects that float across your screen — subtle, mesmerizing, and fully customizable.',
    'btn.download':  'Download for Mac',
    'btn.features':  'See features →',
    'hero.note':     'Free · macOS 14+ · Apple Silicon & Intel',
    'app.subtitle':  'DESKTOP PARTICLES',
    'app.theme':     'Color Theme',
    'app.density':   'Density',
    'app.speed':     'Speed',
    'app.size':      'Size',
    'app.opacity':   'Opacity',
    'features.h2':   'Everything you need,<br>nothing you don\'t.',
    'f1.title': '6 Color Themes',
    'f1.desc':  'Golden, Rose, Moonlight, Aurora, Sapphire — or mix your own three colors with the custom picker.',
    'f2.title': 'Full Control',
    'f2.desc':  'Tune density, speed, size, opacity, lifespan, drift, and wind direction. Every detail is yours to adjust.',
    'f3.title': 'Battery Aware',
    'f3.desc':  'Automatically pauses when running on battery power. Your laptop\'s charge comes first.',
    'f4.title': 'Screenshot Clean',
    'f4.desc':  'Optionally exclude particles from screenshots and screen recordings. Your content, distraction-free.',
    'f5.title': 'Additive Glow',
    'f5.desc':  'Toggle additive blend mode for an ethereal, light-layering glow effect that looks stunning on dark wallpapers.',
    'f6.title': 'Auto Updates',
    'f6.desc':  'Built-in Sparkle updater keeps Wisp current automatically — no App Store, no fuss.',
    'req.1': '🍎 macOS 14 Sonoma or later',
    'req.2': '⚡ Apple Silicon & Intel',
    'req.3': '🪶 ~4 MB download',
    'req.4': '🔒 No tracking, no data collection',
    'cta.h2': 'Make your desktop<br>feel alive.',
    'cta.p':  'Free download. No account required.',
    'cta.btn': 'Download Wisp — Free',
    'footer.releases': 'Releases',
    'footer.github':   'GitHub',
  },
  ru: {
    'nav.download':  'Скачать',
    'hero.badge':    '✦ Бесплатно для macOS',
    'hero.h1':       'Твой рабочий стол,<br>живой.',
    'hero.p':        'Wisp добавляет красивые атмосферные эффекты частиц, которые парят по экрану — тонко, завораживающе и полностью настраиваемо.',
    'btn.download':  'Скачать для Mac',
    'btn.features':  'Смотреть функции →',
    'hero.note':     'Бесплатно · macOS 14+ · Apple Silicon и Intel',
    'app.subtitle':  'ЧАСТИЦЫ НА РАБОЧЕМ СТОЛЕ',
    'app.theme':     'Цветовая тема',
    'app.density':   'Плотность',
    'app.speed':     'Скорость',
    'app.size':      'Размер',
    'app.opacity':   'Прозрачность',
    'features.h2':   'Всё что нужно,<br>ничего лишнего.',
    'f1.title': '6 цветовых тем',
    'f1.desc':  'Золотой, Розовый, Лунный свет, Аврора, Сапфир — или создай свою палитру из трёх цветов.',
    'f2.title': 'Полный контроль',
    'f2.desc':  'Настраивай плотность, скорость, размер, прозрачность, время жизни, дрейф и направление ветра.',
    'f3.title': 'Бережёт батарею',
    'f3.desc':  'Автоматически останавливается при работе от батареи. Заряд твоего MacBook — прежде всего.',
    'f4.title': 'Чистые скриншоты',
    'f4.desc':  'Отключи частицы на скриншотах и записях экрана одним переключателем.',
    'f5.title': 'Аддитивное свечение',
    'f5.desc':  'Режим аддитивного смешивания создаёт эфирный эффект свечения — особенно красиво на тёмных обоях.',
    'f6.title': 'Автообновление',
    'f6.desc':  'Встроенный Sparkle обновляет Wisp автоматически — без App Store и лишних действий.',
    'req.1': '🍎 macOS 14 Sonoma и новее',
    'req.2': '⚡ Apple Silicon и Intel',
    'req.3': '🪶 ~4 МБ',
    'req.4': '🔒 Без слежки и сбора данных',
    'cta.h2': 'Сделай рабочий стол<br>живым.',
    'cta.p':  'Бесплатно. Без регистрации.',
    'cta.btn': 'Скачать Wisp — Бесплатно',
    'footer.releases': 'Релизы',
    'footer.github':   'GitHub',
  }
};

let currentLang = localStorage.getItem('lang') || 'en';

function applyLang(lang) {
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const t = translations[lang][el.dataset.i18n];
    if (t !== undefined) el.textContent = t;
  });
  document.querySelectorAll('[data-i18n-html]').forEach(el => {
    const t = translations[lang][el.dataset.i18nHtml];
    if (t !== undefined) el.innerHTML = t;
  });
  document.documentElement.lang = lang;
  const btn = document.getElementById('lang-btn');
  if (btn) btn.textContent = lang === 'en' ? 'RU' : 'EN';
  localStorage.setItem('lang', lang);
  currentLang = lang;
}

function toggleLang() {
  applyLang(currentLang === 'en' ? 'ru' : 'en');
}

// ── Particle canvas animation ─────────────────────────────────────────────

const canvas = document.getElementById('canvas');
const ctx = canvas.getContext('2d');

let W, H, particles = [];

const THEMES = [
  ['#F0A500','#FF6B00','#FFE566'],
  ['#FF73B3','#FF3366','#FF99CC'],
  ['#E0E8FF','#B0C8FF','#88AAFF'],
  ['#1AF08C','#00D0F0','#A020F0'],
  ['#4D8CFF','#00D4FF','#1A4FE6'],
  ['#FF6EFF','#7B61FF','#00FFC8'],
];

let themeIdx = 3;
let themeColors = THEMES[3];
let themeTimer = 0;
let userPicked = false;

function resize() {
  W = canvas.width  = window.innerWidth;
  H = canvas.height = window.innerHeight;
}

function randomColor() {
  return themeColors[Math.floor(Math.random() * themeColors.length)];
}

function spawn() {
  const x = Math.random() * W;
  const y = Math.random() * H;
  const size = Math.random() * 1.8 + 0.3;
  const speed = Math.random() * 0.25 + 0.08;
  const drift = (Math.random() - 0.5) * 0.2;
  const life  = Math.random() * 0.9 + 0.5;
  const color = randomColor();
  particles.push({ x, y, size, speed, drift, life, maxLife: life, color, alpha: 0 });
}

function frame(t) {
  requestAnimationFrame(frame);

  // Auto-rotate through themes every 6 seconds (stops if user picked one)
  if (!userPicked) {
    themeTimer += 1;
    if (themeTimer > 1800) {
      themeTimer = 0;
      themeIdx = (themeIdx + 1) % THEMES.length;
      themeColors = THEMES[themeIdx];
      setActiveSwatchUI(themeIdx);
    }
  }

  ctx.clearRect(0, 0, W, H);

  // Spawn
  if (particles.length < 160) spawn();

  // Update + draw
  for (let i = particles.length - 1; i >= 0; i--) {
    const p = particles[i];
    p.y     -= p.speed;
    p.x     += p.drift;
    p.life  -= 0.003;
    p.alpha  = Math.min(1, p.life / p.maxLife * 3) * Math.min(1, (p.maxLife - p.life) / p.maxLife * 4);

    if (p.life <= 0) { particles.splice(i, 1); continue; }

    const gradient = ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, p.size * 2.5);
    gradient.addColorStop(0, p.color + Math.round(p.alpha * 140).toString(16).padStart(2,'0'));
    gradient.addColorStop(1, p.color + '00');

    ctx.beginPath();
    ctx.arc(p.x, p.y, p.size * 2.5, 0, Math.PI * 2);
    ctx.fillStyle = gradient;
    ctx.fill();

    // Bright core
    ctx.beginPath();
    ctx.arc(p.x, p.y, p.size * 0.4, 0, Math.PI * 2);
    ctx.fillStyle = '#ffffff' + Math.round(p.alpha * 130).toString(16).padStart(2,'0');
    ctx.fill();
  }
}

function setActiveSwatchUI(idx) {
  document.querySelectorAll('.swatch[data-theme]').forEach(el => {
    el.classList.toggle('active', parseInt(el.dataset.theme) === idx);
  });
}

document.querySelectorAll('.swatch[data-theme]').forEach(el => {
  el.style.cursor = 'pointer';
  el.addEventListener('click', () => {
    const idx = parseInt(el.dataset.theme);
    themeIdx    = idx;
    themeColors = THEMES[idx];
    userPicked  = true;
    setActiveSwatchUI(idx);
  });
});

window.addEventListener('resize', resize);
resize();
applyLang(currentLang);
requestAnimationFrame(frame);
