// clp_tfp · survival · CUSTOM HUD (SVG-Ringe)
const GAUGES = [
    { key: 'health',      icon: '❤️', color: '#ff5b5b' },
    { key: 'blood',       icon: '🩸', color: '#c0392b' },
    { key: 'hunger',      icon: '🍖', color: '#e6a33b' },
    { key: 'thirst',      icon: '💧', color: '#3aa6e0' },
    { key: 'stamina',     icon: '⚡', color: '#43d17a' },
    { key: 'temperature', icon: '🌡️', color: '#7fb3ff' },
];
const DISEASE = {
    cold: 'Erkältung / Fieber', food: 'Lebensmittelvergiftung',
    infection: 'Wundinfektion', cholera: 'Cholera',
};
const R = 19, CIRC = 2 * Math.PI * R;

function clamp(v) { return Math.max(0, Math.min(100, Math.round(v || 0))); }

const root = document.getElementById('survival-hud');
const condWrap = document.createElement('div'); condWrap.id = 'tfp-conditions'; root.appendChild(condWrap);
const gaugeWrap = document.createElement('div'); gaugeWrap.id = 'tfp-gauges'; root.appendChild(gaugeWrap);

const gaugeEls = {};
GAUGES.forEach(function (g) {
    const el = document.createElement('div');
    el.className = 'g';
    el.innerHTML =
        '<svg viewBox="0 0 46 46">' +
            '<circle class="trk" cx="23" cy="23" r="' + R + '"></circle>' +
            '<circle class="prg" cx="23" cy="23" r="' + R + '" stroke="' + g.color + '"></circle>' +
        '</svg>' +
        '<span class="ic">' + g.icon + '</span>' +
        '<span class="v"></span>';
    const prg = el.querySelector('.prg');
    prg.style.strokeDasharray = CIRC;
    prg.style.strokeDashoffset = 0;
    gaugeEls[g.key] = el;
    gaugeWrap.appendChild(el);
});

function renderGauges(d) {
    GAUGES.forEach(function (g) {
        const el = gaugeEls[g.key];
        const v = clamp(d[g.key] !== undefined ? d[g.key] : 100);
        el.querySelector('.prg').style.strokeDashoffset = CIRC * (1 - v / 100);
        el.querySelector('.v').textContent = v;
        el.classList.toggle('low', v <= 25);
    });
}

function renderConditions(d) {
    const conds = [];
    if ((d.wetness || 0) > 10) conds.push({ icon: '🌧️', text: 'Nass ' + clamp(d.wetness) + '%', cls: 'wet' });
    if ((d.sickness || 0) > 0) conds.push({ icon: '🤢', text: (DISEASE[d.sicknessType] || 'Krank') + ' · ' + clamp(d.sickness) + '%', cls: 'sick', pulse: d.sickness >= 50 });
    if ((d.bleeding || 0) > 0) conds.push({ icon: '🩸', text: 'Blutung ' + clamp(d.bleeding) + '%', cls: 'bleed', pulse: true });
    if ((d.fracture || 0) > 0) conds.push({ icon: '🦴', text: (d.fractureType === 'arm' ? 'Armbruch' : 'Beinbruch'), cls: 'frac', pulse: true });
    if (d.oxygen !== undefined && d.oxygen < 100) conds.push({ icon: '🫧', text: 'Luft ' + clamp(d.oxygen) + '%', cls: 'air', pulse: d.oxygen <= 30 });
    if ((d.fatigue || 0) >= 50) conds.push({ icon: '😴', text: 'Müde ' + clamp(d.fatigue) + '%', cls: 'tired', pulse: d.fatigue >= 85 });
    condWrap.innerHTML = conds.map(function (c) {
        return '<div class="badge ' + c.cls + (c.pulse ? ' pulse' : '') + '"><span class="bic">' + c.icon + '</span><span>' + c.text + '</span></div>';
    }).join('');
}

function render(d) { renderGauges(d); renderConditions(d); }

// ─── Wetter/Zeit/Temp-Widget ─────────────────────────────────────────────────
let envEl = null;
function weatherIcon(label) {
    const m = { 'Sonnig': '☀️', 'Klar': '🌙', 'Bewölkt': '⛅', 'Bedeckt': '☁️', 'Neblig': '🌫️',
        'Regen': '🌧️', 'Gewitter': '⛈️', 'Aufklarend': '🌦️', 'Schnee': '🌨️', 'Schneesturm': '❄️' };
    return m[label] || '🌡️';
}
function renderEnv(d) {
    if (!envEl) {
        envEl = document.createElement('div'); envEl.id = 'survival-env';
        envEl.innerHTML = '<span class="w"></span><span class="sep"></span><span class="t"></span><span class="sep"></span><span class="c"></span>';
        document.body.appendChild(envEl);
    }
    envEl.querySelector('.w').textContent = weatherIcon(d.weather) + ' ' + (d.weather || '');
    envEl.querySelector('.t').textContent = '🕒 ' + (d.time || '');
    const c = envEl.querySelector('.c');
    c.textContent = '🌡️ ' + (d.temp === undefined ? '' : d.temp + '°C');
    c.style.color = (d.temp <= 5) ? '#7FB3FF' : (d.temp >= 30 ? '#FF8A6A' : '#ffffff');
}

// ─── Death/Downed-Overlay ────────────────────────────────────────────────────
let downedEl = null;
function renderDowned(msg) {
    if (!downedEl) {
        downedEl = document.createElement('div'); downedEl.id = 'survival-downed';
        downedEl.innerHTML = '<div class="dtitle"></div><div class="dsub"></div><div class="dhint"></div>';
        document.body.appendChild(downedEl);
    }
    if (!msg.show) { downedEl.style.display = 'none'; return; }
    const dead = msg.mode === 'dead';
    downedEl.style.display = 'flex';
    downedEl.classList.toggle('dead', dead);
    downedEl.querySelector('.dtitle').textContent = dead ? 'GESTORBEN' : 'VERWUNDET';
    downedEl.querySelector('.dsub').textContent = dead ? '' : ('Du verblutest in ' + (msg.seconds || 0) + 's');
    downedEl.querySelector('.dhint').textContent = dead ? '' : 'Warte auf Hilfe  ·  [X] zum Aufgeben';
}

// ─── Realismus-Vignetten ─────────────────────────────────────────────────────
let fxRed = null, fxBlue = null;
function renderFx(msg) {
    if (!fxRed) { fxRed = document.createElement('div'); fxRed.id = 'survival-vignette-red'; document.body.appendChild(fxRed); }
    if (!fxBlue) { fxBlue = document.createElement('div'); fxBlue.id = 'survival-vignette-blue'; document.body.appendChild(fxBlue); }
    fxRed.style.opacity = Math.max(0, Math.min(1, msg.red || 0));
    fxBlue.style.opacity = Math.max(0, Math.min(1, msg.blue || 0));
    fxRed.classList.toggle('beat', (msg.red || 0) >= 0.55);
}

window.addEventListener('message', function (e) {
    const msg = e.data || {};
    if (msg.action === 'update') { root.style.display = 'flex'; render(msg.data || {}); }
    if (msg.action === 'env') renderEnv(msg);
    if (msg.action === 'downed') renderDowned(msg);
    if (msg.action === 'fx') renderFx(msg);
    if (msg.action === 'display') root.style.display = msg.show ? 'flex' : 'none';
});
