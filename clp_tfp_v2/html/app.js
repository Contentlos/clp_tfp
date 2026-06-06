// clp_tfp · HUD (Stahlblau-Balken). NUI-Protokoll: update/env/downed/fx/objective/display.
const GAUGES = [
    { key: 'health',      icon: '❤️' },
    { key: 'blood',       icon: '🩸' },
    { key: 'hunger',      icon: '🍖' },
    { key: 'thirst',      icon: '💧' },
    { key: 'stamina',     icon: '⚡' },
    { key: 'temperature', icon: '🌡️' },
];
const DISEASE = { cold: 'Erkältung / Fieber', food: 'Lebensmittelvergiftung', infection: 'Wundinfektion', cholera: 'Cholera' };

function clamp(v) { return Math.max(0, Math.min(100, Math.round(v || 0))); }

const root = document.getElementById('survival-hud');
const condWrap = document.createElement('div'); condWrap.id = 'tfp-conditions'; root.appendChild(condWrap);
const gaugeWrap = document.createElement('div'); gaugeWrap.id = 'tfp-gauges'; root.appendChild(gaugeWrap);

const gaugeEls = {};
GAUGES.forEach(function (g) {
    const el = document.createElement('div');
    el.className = 'g';
    el.innerHTML = '<span class="ic">' + g.icon + '</span><div class="bar"><div class="fill"></div></div><span class="v"></span>';
    gaugeEls[g.key] = el;
    gaugeWrap.appendChild(el);
});

function renderGauges(d) {
    GAUGES.forEach(function (g) {
        const el = gaugeEls[g.key];
        const v = clamp(d[g.key] !== undefined ? d[g.key] : 100);
        el.querySelector('.fill').style.height = v + '%';
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
    if ((d.wounds || 0) >= 2) conds.push({ icon: '🩹', text: d.wounds + ' Wunden', cls: 'bleed' });
    if (d.oxygen !== undefined && d.oxygen < 100) conds.push({ icon: '🫧', text: 'Luft ' + clamp(d.oxygen) + '%', cls: 'air', pulse: d.oxygen <= 30 });
    if ((d.fatigue || 0) >= 50) conds.push({ icon: '😴', text: 'Müde ' + clamp(d.fatigue) + '%', cls: 'tired', pulse: d.fatigue >= 85 });
    condWrap.innerHTML = conds.map(function (c) {
        return '<div class="badge ' + c.cls + (c.pulse ? ' pulse' : '') + '"><span class="bic">' + c.icon + '</span><span>' + c.text + '</span></div>';
    }).join('');
}

function render(d) { renderGauges(d); renderConditions(d); }

// ── Wetter/Zeit/Temp ──
let envEl = null;
function weatherIcon(label) {
    const m = { 'Sonnig': '☀️', 'Klar': '🌙', 'Bewölkt': '⛅', 'Bedeckt': '☁️', 'Neblig': '🌫️', 'Regen': '🌧️', 'Gewitter': '⛈️', 'Schnee': '❄️' };
    return m[label] || '🌡️';
}
function renderEnv(msg) {
    if (!envEl) { envEl = document.createElement('div'); envEl.id = 'survival-env'; document.body.appendChild(envEl); }
    envEl.innerHTML =
        '<span>' + weatherIcon(msg.weather) + ' ' + (msg.weather || '') + '</span><span class="sep"></span>' +
        '<span>🕓 ' + (msg.time || '--:--') + '</span><span class="sep"></span>' +
        '<span>🌡️ ' + (msg.temp !== undefined ? msg.temp + '°' : '--') + '</span>';
}

// ── Death/Downed ──
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

// ── Vignetten ──
let fxRed = null, fxBlue = null;
function renderFx(msg) {
    if (!fxRed) { fxRed = document.createElement('div'); fxRed.id = 'survival-vignette-red'; document.body.appendChild(fxRed); }
    if (!fxBlue) { fxBlue = document.createElement('div'); fxBlue.id = 'survival-vignette-blue'; document.body.appendChild(fxBlue); }
    fxRed.style.opacity = Math.max(0, Math.min(1, msg.red || 0));
    fxBlue.style.opacity = Math.max(0, Math.min(1, msg.blue || 0));
    fxRed.classList.toggle('beat', (msg.red || 0) >= 0.55);
}

// ── Ziel-Tracker (Story-Flucht, ab Phase 7) ──
let objEl = null;
function renderObjective(msg) {
    const d = msg.data || {};
    if (!objEl) { objEl = document.createElement('div'); objEl.id = 'survival-objective'; document.body.appendChild(objEl); }
    if (!d.active) { objEl.style.display = 'none'; return; }
    objEl.style.display = 'block';
    let needs = '';
    (d.needs || []).forEach(function (n) {
        const ok = (n.have || 0) >= n.need;
        needs += '<div class="oneed' + (ok ? ' ok' : '') + '"><span>' + n.label + '</span>' +
                 '<span class="oc">' + Math.min(n.have || 0, n.need) + '/' + n.need + '</span></div>';
    });
    objEl.innerHTML =
        '<div class="ohead"><span class="otag">◢ FLUCHT</span><span class="ostep">Schritt ' + (d.step || 1) + '/' + (d.total || 1) + '</span></div>' +
        '<div class="otitle">' + (d.label || '') + '</div>' +
        (d.story ? '<div class="ostory">' + d.story + '</div>' : '') +
        (needs ? '<div class="oneeds">' + needs + '</div>' : '') +
        (d.hint ? '<div class="ohint">' + d.hint + '</div>' : '');
}

window.addEventListener('message', function (e) {
    const msg = e.data || {};
    if (msg.action === 'update') { root.style.display = 'flex'; render(msg.data || {}); }
    if (msg.action === 'env') renderEnv(msg);
    if (msg.action === 'downed') renderDowned(msg);
    if (msg.action === 'fx') renderFx(msg);
    if (msg.action === 'objective') renderObjective(msg);
    if (msg.action === 'display') root.style.display = msg.show ? 'flex' : 'none';
});
