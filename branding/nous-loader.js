/* =====================================================================
   Nous - Customizacoes de comportamento (gancho oficial de JS)
   O Open WebUI carrega este arquivo no index.html:
       <script src="/static/loader.js" defer crossorigin="use-credentials"></script>
   Ele vem vazio de fabrica, justamente para customizacoes.
   Reaplicado em qualquer maquina por branding/apply_branding.py.

   Recursos:
     - Botao flutuante de tema CLARO/ESCURO na tela inicial.
       (replica fielmente o applyTheme do Open WebUI -
        src/lib/components/chat/Settings/General.svelte - para manter 100%
        de compatibilidade e persistencia via localStorage.theme).
   ===================================================================== */
(function () {
	'use strict';

	/* ---------- Aplicacao de tema (igual ao Open WebUI) ---------- */
	function applyTheme(_theme) {
		var themeToApply =
			_theme === 'oled-dark' ? 'dark' : _theme === 'her' ? 'light' : _theme;
		if (_theme === 'system') {
			themeToApply = window.matchMedia('(prefers-color-scheme: dark)').matches
				? 'dark'
				: 'light';
		}
		if (themeToApply === 'dark' && _theme.indexOf('oled') === -1) {
			var st = document.documentElement.style;
			st.setProperty('--color-gray-800', '#333');
			st.setProperty('--color-gray-850', '#262626');
			st.setProperty('--color-gray-900', '#171717');
			st.setProperty('--color-gray-950', '#0d0d0d');
		}
		['dark', 'light', 'oled-dark']
			.filter(function (e) { return e !== themeToApply; })
			.forEach(function (e) {
				e.split(' ').forEach(function (c) {
					document.documentElement.classList.remove(c);
				});
			});
		themeToApply.split(' ').forEach(function (c) {
			document.documentElement.classList.add(c);
		});
		var meta = document.querySelector('meta[name="theme-color"]');
		if (meta) {
			meta.setAttribute('content', themeToApply === 'dark' ? '#171717' : '#ffffff');
		}
	}

	function isDark() {
		return document.documentElement.classList.contains('dark');
	}

	function setTheme(_theme) {
		try { localStorage.setItem('theme', _theme); } catch (e) {}
		applyTheme(_theme);
		paintToggle();
	}

	/* ---------- Botao flutuante ---------- */
	/* sol = clique leva ao tema claro (estamos no escuro); lua = leva ao escuro */
	var SUN =
		'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" ' +
		'stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="4"/>' +
		'<path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2' +
		'M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41"/></svg>';
	var MOON =
		'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" ' +
		'stroke-linecap="round" stroke-linejoin="round">' +
		'<path d="M21 12.79A9 9 0 1 1 11.21 3 7 9 0 0 0 21 12.79z"/></svg>';

	var btn = null;
	var lastDark = null;

	function paintToggle() {
		if (!btn) return;
		var dark = isDark();
		if (dark === lastDark) return;
		lastDark = dark;
		btn.innerHTML = dark ? SUN : MOON;
		btn.setAttribute('aria-label', dark ? 'Mudar para tema claro' : 'Mudar para tema escuro');
		btn.setAttribute('title', dark ? 'Tema claro' : 'Tema escuro');
	}

	function ensureToggle() {
		if (btn && document.body && document.body.contains(btn)) return;
		if (!document.body) return;
		btn = document.createElement('button');
		btn.id = 'nous-theme-toggle';
		btn.type = 'button';
		btn.style.display = 'none';
		lastDark = null;
		btn.addEventListener('click', function () {
			setTheme(isDark() ? 'light' : 'dark');
		});
		document.body.appendChild(btn);
		paintToggle();
	}

	/* ===================== Painel de recursos (Nous Monitor) ===================== */
	var MON_URL = 'http://127.0.0.1:8990';
	var monEl = null, monModels = null, monBtn = null, monBars = {};
	var monCollapsed = false;
	try { monCollapsed = localStorage.getItem('nous-monitor-collapsed') === '1'; } catch (e) {}

	function fmtGB(n) { return (Number(n || 0) / 1073741824).toFixed(1); }

	function injectMonitorStyle() {
		if (document.getElementById('nous-monitor-style')) return;
		var css =
			'#nous-monitor{position:fixed;left:14px;bottom:90px;z-index:9998;width:212px;' +
			'font-family:Inter,system-ui,sans-serif;font-size:12px;color:#eee;' +
			'background:rgba(18,18,22,.82);backdrop-filter:blur(10px);' +
			'border:1px solid rgba(200,150,46,.35);border-radius:12px;' +
			'box-shadow:0 8px 24px rgba(0,0,0,.35);overflow:hidden;user-select:none}' +
			'#nous-mon-head{display:flex;align-items:center;gap:7px;padding:8px 10px;cursor:pointer}' +
			'#nous-mon-title{font-weight:600;letter-spacing:.04em;flex:1}' +
			'.nous-mon-dot{width:7px;height:7px;border-radius:50%;background:#3ad07a;box-shadow:0 0 6px #3ad07a}' +
			'#nous-monitor.nous-mon-off .nous-mon-dot{background:#888;box-shadow:none}' +
			'#nous-mon-caret{width:0;height:0;border-left:4px solid transparent;border-right:4px solid transparent;' +
			'border-top:5px solid #c8962e;transition:transform .2s}' +
			'#nous-monitor.nous-collapsed #nous-mon-caret{transform:rotate(180deg)}' +
			'#nous-monitor.nous-collapsed #nous-mon-body{display:none}' +
			'#nous-mon-body{padding:0 10px 10px}' +
			'.nous-mon-row{display:flex;justify-content:space-between;margin:6px 0 3px;opacity:.85}' +
			'.nous-mon-val{font-variant-numeric:tabular-nums}' +
			'.nous-mon-track{height:6px;border-radius:4px;background:rgba(255,255,255,.1);overflow:hidden}' +
			'.nous-mon-fill{height:100%;width:0;background:linear-gradient(90deg,#c8962e,#e7c069);transition:width .5s}' +
			'.nous-mon-fill2{background:linear-gradient(90deg,#6b7280,#9ca3af)}' +
			'#nous-mon-models{margin:9px 0 4px;display:flex;flex-direction:column;gap:5px}' +
			'.nous-mon-model{display:flex;flex-direction:column;background:rgba(255,255,255,.05);border-radius:7px;padding:5px 7px}' +
			'.nous-mon-model span{opacity:.7;font-size:11px}' +
			'.nous-mon-empty{opacity:.5;font-style:italic;padding:4px 0}' +
			'#nous-mon-stop{width:100%;margin-top:4px;padding:6px;border:0;border-radius:8px;cursor:pointer;' +
			'background:rgba(200,150,46,.18);color:#e7c069;font-weight:600;font-size:12px;transition:background .15s}' +
			'#nous-mon-stop:hover:not(:disabled){background:rgba(200,150,46,.32)}' +
			'#nous-mon-stop:disabled{opacity:.4;cursor:default}';
		var st = document.createElement('style');
		st.id = 'nous-monitor-style';
		st.textContent = css;
		document.head.appendChild(st);
	}

	function buildMonitor() {
		if (monEl && document.body && document.body.contains(monEl)) return;
		if (!document.body) return;
		monEl = document.createElement('div');
		monEl.id = 'nous-monitor';
		monEl.innerHTML =
			'<div id="nous-mon-head"><span class="nous-mon-dot"></span>' +
			'<span id="nous-mon-title">Recursos</span><span id="nous-mon-caret"></span></div>' +
			'<div id="nous-mon-body">' +
			'<div class="nous-mon-row"><span>VRAM (GPU)</span><span class="nous-mon-val" data-k="ded">—</span></div>' +
			'<div class="nous-mon-track"><div class="nous-mon-fill" data-k="ded"></div></div>' +
			'<div class="nous-mon-row"><span>Compartilhada</span><span class="nous-mon-val" data-k="shr">—</span></div>' +
			'<div class="nous-mon-track"><div class="nous-mon-fill nous-mon-fill2" data-k="shr"></div></div>' +
			'<div id="nous-mon-models"></div>' +
			'<button id="nous-mon-stop" type="button" disabled>Parar modelos</button></div>';
		document.body.appendChild(monEl);
		monModels = monEl.querySelector('#nous-mon-models');
		monBtn = monEl.querySelector('#nous-mon-stop');
		monBars = {
			dedVal: monEl.querySelector('.nous-mon-val[data-k="ded"]'),
			shrVal: monEl.querySelector('.nous-mon-val[data-k="shr"]'),
			dedFill: monEl.querySelector('.nous-mon-fill[data-k="ded"]'),
			shrFill: monEl.querySelector('.nous-mon-fill[data-k="shr"]')
		};
		monEl.querySelector('#nous-mon-head').addEventListener('click', function () {
			monCollapsed = !monCollapsed;
			try { localStorage.setItem('nous-monitor-collapsed', monCollapsed ? '1' : '0'); } catch (e) {}
			monEl.classList.toggle('nous-collapsed', monCollapsed);
		});
		monBtn.addEventListener('click', function () {
			monBtn.disabled = true; monBtn.textContent = 'Liberando…';
			fetch(MON_URL + '/unload', { method: 'POST' })
				.catch(function () {})
				.then(function () { setTimeout(refreshMonitor, 700); });
		});
		monEl.classList.toggle('nous-collapsed', monCollapsed);
	}

	function refreshMonitor() {
		if (!monEl) return;
		fetch(MON_URL + '/stats', { cache: 'no-store' })
			.then(function (r) { return r.json(); })
			.then(function (s) {
				monEl.classList.remove('nous-mon-off');
				var g = s.gpu || {};
				if (g.ded_total) {
					monBars.dedVal.textContent = fmtGB(g.ded_used) + ' / ' + fmtGB(g.ded_total) + ' GB';
					monBars.dedFill.style.width = Math.min(100, 100 * g.ded_used / g.ded_total) + '%';
				}
				if (g.shr_total) {
					monBars.shrVal.textContent = fmtGB(g.shr_used) + ' / ' + fmtGB(g.shr_total) + ' GB';
					monBars.shrFill.style.width = Math.min(100, 100 * g.shr_used / g.shr_total) + '%';
				}
				var models = s.models || [];
				if (!models.length) {
					monModels.innerHTML = '<div class="nous-mon-empty">Nenhum modelo na memoria</div>';
					monBtn.disabled = true; monBtn.textContent = 'Parar modelos';
				} else {
					monModels.innerHTML = models.map(function (m) {
						var left = (m.seconds_left != null) ? (' · libera em ' + m.seconds_left + 's') : '';
						return '<div class="nous-mon-model"><b>' + m.name + '</b><span>' +
							fmtGB(m.vram) + ' GB VRAM' +
							(m.shared > 0 ? ' + ' + fmtGB(m.shared) + ' compart.' : '') +
							left + '</span></div>';
					}).join('');
					monBtn.disabled = false; monBtn.textContent = 'Parar modelos';
				}
			})
			.catch(function () {
				monEl.classList.add('nous-mon-off');
				if (monModels) monModels.innerHTML = '<div class="nous-mon-empty">Monitor offline</div>';
			});
	}

	/* Mostra o botao apenas na tela inicial (rota "/") */
	function onHome() {
		var p = location.pathname;
		return p === '/' || p === '' || p === '/index.html';
	}

	/* Injeta o wordmark "NOUS" abaixo da coruja na tela inicial.
	   O CSS suprime o body::after fixo quando este elemento esta' presente,
	   mantendo os dois sempre alinhados. */
	function injectHomeWordmark() {
		var wm = document.querySelector('.nous-home-wordmark');
		if (!onHome()) {
			if (wm) wm.remove();
			return;
		}
		if (wm) return;
		var owlRow = document.querySelector('.flex.flex-row.justify-center.max-w-xl');
		if (!owlRow || !owlRow.querySelector('img.rounded-full')) return;
		var div = document.createElement('div');
		div.className = 'nous-home-wordmark';
		div.textContent = 'NOUS';
		owlRow.parentNode.insertBefore(div, owlRow.nextSibling);
	}

	function tick() {
		ensureToggle();
		if (btn) btn.style.display = onHome() ? 'flex' : 'none';
		paintToggle();
		buildMonitor();
		injectHomeWordmark();
	}

	function start() {
		injectMonitorStyle();
		tick();
		setInterval(tick, 500);
		refreshMonitor();
		setInterval(refreshMonitor, 3000);
	}

	if (document.readyState === 'loading') {
		document.addEventListener('DOMContentLoaded', start);
	} else {
		start();
	}
})();
