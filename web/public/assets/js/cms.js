// ─────────────────────────────────────────────────────────────────────
//  Landing-page CMS hydration
// ─────────────────────────────────────────────────────────────────────
//
//  Fetches the single Firestore doc at `site_content/landing` and
//  rewrites the page from it. Designed to be 100% additive: if the
//  fetch fails (offline, ad blocker, missing doc), the static HTML
//  defaults baked into index.html stay visible.
//
//  Binding conventions:
//    <h1 data-cms="hero.title">Static fallback</h1>
//    <a  data-cms="hero.ctaPrimaryLabel"
//        data-cms-attr="ctaPrimaryHref"
//        href="/fallback">Start</a>
//    <div data-cms-list="features"     ← rendered from JS template
//         data-cms-template="feature">
//      <!-- static fallback feature cards -->
//    </div>
//
//  Templates are defined in `cmsTemplates` below.
//
//  Production config:
//    1. Copy `firebaseConfig` from your Firebase console
//       (Project settings → General → Your apps → Web).
//    2. The doc must exist at site_content/landing — either create it
//       in the admin portal Landing page editor, or run the seed
//       script under `scripts/seed_site_content.js`.

(function () {
  'use strict';

  // ---- Edit me --------------------------------------------------------
  const firebaseConfig = {
    apiKey: 'AIzaSyCJZia_hYNCBVZb8q6G2db26QkJdK7W438',
    authDomain: 'ilearnit-31f41.firebaseapp.com',
    projectId: 'ilearnit-31f41',
    storageBucket: 'ilearnit-31f41.appspot.com',
    appId: '1:941373047874:web:5311deb56e35e878f319db',
  };
  // --------------------------------------------------------------------

  // Bail early if Firebase SDK didn't load — leave the static page alone.
  if (typeof firebase === 'undefined' || !firebase?.firestore) {
    console.warn('[cms] Firebase SDK missing — keeping static defaults.');
    return;
  }
  if (firebaseConfig.apiKey === 'REPLACE_ME') {
    console.warn('[cms] firebaseConfig not populated — keeping static defaults.');
    return;
  }

  firebase.initializeApp(firebaseConfig);

  /**
   * Resolve `"hero.title"` against `{ hero: { title: '…' } }`.
   * Returns undefined for missing paths (callers fall back to the
   * existing DOM content).
   */
  function dig(obj, path) {
    if (!obj || !path) return undefined;
    return path.split('.').reduce(
      (acc, k) => (acc && acc[k] !== undefined ? acc[k] : undefined),
      obj,
    );
  }

  function bindScalars(root, data) {
    root.querySelectorAll('[data-cms]').forEach((el) => {
      const path = el.getAttribute('data-cms');
      const value = dig(data, path);
      if (value === undefined || value === '') return;
      el.textContent = value;
    });

    root.querySelectorAll('[data-cms-href]').forEach((el) => {
      const path = el.getAttribute('data-cms-href');
      const value = dig(data, path);
      if (value === undefined || value === '') return;
      el.setAttribute('href', value);
    });

    root.querySelectorAll('[data-cms-src]').forEach((el) => {
      const path = el.getAttribute('data-cms-src');
      const value = dig(data, path);
      if (value === undefined || value === '') return;
      el.setAttribute('src', value);
    });
  }

  /**
   * Template-based list rendering. The HTML inside `<template
   * id="cms-tpl-{name}">` is cloned for each item in the array, with
   * `{{field}}` placeholders substituted from the item.
   */
  function bindLists(root, data) {
    root.querySelectorAll('[data-cms-list]').forEach((container) => {
      const listPath = container.getAttribute('data-cms-list');
      const templateName = container.getAttribute('data-cms-template');
      const items = dig(data, listPath);
      if (!Array.isArray(items) || items.length === 0) return;

      const tpl = document.getElementById(`cms-tpl-${templateName}`);
      if (!tpl) {
        console.warn(`[cms] No <template id="cms-tpl-${templateName}">`);
        return;
      }

      const html = items
        .map((item) => renderTemplate(tpl.innerHTML, item))
        .join('');
      container.innerHTML = html;
    });
  }

  /**
   * Minimal mustache-ish: `{{field}}` for text, `{{#perks}}…{{/perks}}`
   * for one-level array iteration over the current item's array.
   *
   * Templates should NOT be user-provided — they live in the static
   * HTML and pre-render only short strings into HTML, so XSS surface
   * is limited. Even so, we HTML-escape every value.
   */
  function renderTemplate(template, item) {
    // Iteration block first so the value loop below doesn't try to
    // interpret the block's own `{{field}}` references against the
    // outer item.
    let result = template.replace(
      /\{\{#(\w+)\}\}([\s\S]*?)\{\{\/\1\}\}/g,
      (_, key, inner) => {
        const arr = item[key];
        if (!Array.isArray(arr)) return '';
        return arr.map((v) => inner.replace(/\{\{\.\}\}/g, escape(v))).join('');
      },
    );

    result = result.replace(/\{\{(\w+)\}\}/g, (_, key) => {
      const v = item[key];
      return v === undefined || v === null ? '' : escape(String(v));
    });

    // Booleans for class toggling: `data-if-featured` → strip the
    // attribute if `item.featured` is falsy.
    result = result.replace(
      /data-if-(\w+)="([^"]*)"/g,
      (_, key, classes) => (item[key] ? `class="${classes}"` : ''),
    );

    return result;
  }

  function escape(s) {
    return String(s)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  // ---- Run ------------------------------------------------------------
  const db = firebase.firestore();
  db.collection('site_content')
    .doc('landing')
    .get()
    .then((snap) => {
      if (!snap.exists) {
        console.warn(
          '[cms] site_content/landing not found — keeping static defaults.',
        );
        return;
      }
      const data = snap.data();
      bindScalars(document, data);
      bindLists(document, data);
    })
    .catch((err) => {
      console.warn('[cms] Fetch failed, keeping static defaults:', err);
    });
})();
