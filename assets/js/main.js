// Интерактивность сайта: мобильное меню, слайдеры карточек, копирование.
(function () {
  'use strict';

  /* ---------- Мобильное меню ---------- */
  var header = document.getElementById('siteHeader');
  var toggle = header ? header.querySelector('.nav-toggle') : null;

  function closeNav() {
    header.classList.remove('nav-open');
    toggle.setAttribute('aria-expanded', 'false');
  }

  if (header && toggle) {
    toggle.addEventListener('click', function () {
      var open = header.classList.toggle('nav-open');
      toggle.setAttribute('aria-expanded', String(open));
    });

    header.addEventListener('click', function (e) {
      if (e.target.closest('.site-nav a')) closeNav();
    });

    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && header.classList.contains('nav-open')) {
        closeNav();
        toggle.focus();
      }
    });
  }

  /* ---------- Слайдеры карточек ---------- */
  document.querySelectorAll('[data-cards-target]').forEach(function (btn) {
    var scroller = document.getElementById(btn.dataset.cardsTarget);
    if (!scroller) return;
    btn.addEventListener('click', function () {
      var dir = btn.dataset.cardsDir === 'prev' ? -1 : 1;
      scroller.scrollBy({ left: 320 * dir, behavior: 'smooth' });
    });
  });

  /* ---------- Копирование ---------- */
  function legacyCopy(text) {
    return new Promise(function (resolve, reject) {
      var ta = document.createElement('textarea');
      ta.value = text;
      ta.setAttribute('readonly', '');
      ta.style.position = 'fixed';
      ta.style.opacity = '0';
      document.body.appendChild(ta);
      ta.select();
      try {
        document.execCommand('copy') ? resolve() : reject(new Error('copy failed'));
      } catch (e) {
        reject(e);
      } finally {
        document.body.removeChild(ta);
      }
    });
  }

  function copyToClipboard(text) {
    if (navigator.clipboard && window.isSecureContext) {
      return navigator.clipboard.writeText(text).catch(function () { return legacyCopy(text); });
    }
    return legacyCopy(text);
  }

  function flashButton(btn, text) {
    var label = btn.textContent;
    btn.textContent = text;
    setTimeout(function () { btn.textContent = label; }, 2000);
  }

  // Кнопка «Скопировать ссылку»
  document.querySelectorAll('[data-copy]').forEach(function (btn) {
    btn.addEventListener('click', function () {
      copyToClipboard(btn.dataset.copy).then(function () {
        flashButton(btn, 'Скопировано!');
      }).catch(function () {
        flashButton(btn, 'Не удалось скопировать');
      });
    });
  });

  // Кнопка копирования у блоков кода
  document.querySelectorAll('.highlight').forEach(function (block) {
    var pre = block.querySelector('pre');
    if (!pre) return;
    var btn = document.createElement('button');
    btn.className = 'copy-code';
    btn.type = 'button';
    btn.textContent = 'копировать';
    btn.addEventListener('click', function () {
      copyToClipboard(pre.innerText).then(function () {
        btn.classList.add('copied');
        btn.textContent = '✓ скопировано';
        setTimeout(function () {
          btn.classList.remove('copied');
          btn.textContent = 'копировать';
        }, 2000);
      }).catch(function () { });
    });
    block.appendChild(btn);
  });
})();
