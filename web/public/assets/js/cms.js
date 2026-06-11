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
//        data-cms-href="hero.ctaPrimaryHref"
//        href="/fallback">Start</a>
//    <div data-cms-list="features"     ← rendered from JS template
//         data-cms-template="feature">
//      <li data-cms-keep>…</li>        ← preserved across list replacement
//      <!-- static fallback feature cards -->
//    </div>
//    <title data-cms-meta="pageTitle">…</title>            ← <head> text
//    <meta data-cms-meta-attr="description" content="…" /> ← <head> attr
//
//  Templates are defined inline in index.html as <template id="cms-tpl-{name}">.
//
//  Also renders a LIVE "Featured courses" rail by querying
//  `courses where isFeatured == true limit 6` — independent of the
//  CMS doc. The grid self-hides when no featured courses exist.
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
  // One Firebase project per flavor. The active config is picked at load
  // time based on the hostname (or an explicit override in localStorage).
  // This is what stops the "I edited in admin, but the landing page
  // still shows old data" bug: the admin writes to whichever project
  // it was built for (Flavor.dev → ilearnit-dev, Flavor.prod →
  // ilearnit-31f41), so the public site MUST read from the SAME
  // project — otherwise the doc the editor saved doesn't even exist
  // in the project the JS is querying.
  //
  // Every field below must be internally consistent (same project on
  // every line). Pull these from Firebase Console → Project settings
  // → General → Your apps → Web. The fastest sanity check is:
  //   `1:<projectNumber>:web:…` ← compare projectNumber to firebase.json
  //   `<projectId>.firebaseapp.com` ← authDomain prefix matches projectId
  const FIREBASE_CONFIGS = {
    dev: {
      apiKey: 'AIzaSyCJZia_hYNCBVZb8q6G2db26QkJdK7W438',
      authDomain: 'ilearnit-dev.firebaseapp.com',
      projectId: 'ilearnit-dev',
      storageBucket: 'ilearnit-dev.appspot.com',
      appId: '1:941373047874:web:5311deb56e35e878f319db',
    },
    prod: {
      // TODO: paste prod web app config from Firebase Console → Project
      // ilearnit-31f41 → Settings → General → Your apps → Web. Every
      // field must reference project ilearnit-31f41 (project number
      // 539584702115). Until then prod deploys will fall back to dev
      // with a console warning.
      apiKey: '',
      authDomain: 'ilearnit-31f41.firebaseapp.com',
      projectId: 'ilearnit-31f41',
      storageBucket: 'ilearnit-31f41.appspot.com',
      appId: '1:539584702115:web:e5edeb0e9f8403ab4ac116',
    },
  };

  /**
   * Pick dev vs prod by hostname. Override via DevTools:
   *   localStorage.setItem('ilearnit:cms_flavor', 'prod')
   * then reload. Useful when QA-testing prod content from localhost.
   */
  function pickFlavor() {
    try {
      const forced = localStorage.getItem('ilearnit:cms_flavor');
      if (forced === 'dev' || forced === 'prod') return forced;
    } catch (_) {/* SSR-safe */}

    const host = (window.location.hostname || '').toLowerCase();
    // Prod is the custom domain + the prod project's auto domains.
    if (
      host === 'ilearnit.info'
      || host === 'www.ilearnit.info'
      || host.startsWith('ilearnit-31f41.')
    ) return 'prod';
    // Dev covers localhost, the dev project's auto domains, and any
    // preview channel of the dev project.
    return 'dev';
  }

  const flavor = pickFlavor();
  let firebaseConfig = FIREBASE_CONFIGS[flavor];

  // If prod was selected but its config wasn't filled in, fall back to
  // dev with a loud warning. Avoids a silent SDK init failure.
  if (!firebaseConfig.apiKey) {
    console.warn(
      `[cms] firebaseConfig.${flavor} is empty — falling back to dev. ` +
      'Fill in FIREBASE_CONFIGS.prod in cms.js before deploying to prod.',
    );
    firebaseConfig = FIREBASE_CONFIGS.dev;
  }
  console.info(
    `[cms] Using Firebase project "${firebaseConfig.projectId}" (flavor=${flavor}).`,
  );
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
   *
   * Children of the list container with `data-cms-keep` are preserved
   * across the replacement and re-appended at the end. Used for the
   * top-nav CTA (kept on the right) and the footer brand column (kept
   * on the left — preserved at the start when it appears before the
   * list items in document order).
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

      // Snapshot preserved children, then their position relative to the
      // first replaced item (so brand-column-before stays first, nav-CTA-
      // after stays last). We index by original DOM order at snapshot.
      const keepNodes = Array.from(
        container.querySelectorAll(':scope > [data-cms-keep]'),
      );
      const firstKeptIndex = keepNodes.length === 0
        ? -1
        : Array.from(container.children).indexOf(keepNodes[0]);
      const wasFirst = firstKeptIndex === 0;

      const html = items
        .map((item) => renderTemplate(tpl.innerHTML, item))
        .join('');
      container.innerHTML = html;

      // Re-attach the preserved nodes. If the first kept node was the
      // first child originally (e.g. footer brand column), prepend the
      // whole group to keep them on the left; otherwise append.
      if (wasFirst) {
        for (let i = keepNodes.length - 1; i >= 0; i--) {
          container.insertBefore(keepNodes[i], container.firstChild);
        }
      } else {
        for (const node of keepNodes) container.appendChild(node);
      }
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
        // Inside iteration, support both `{{.}}` for primitives and
        // `{{field}}` for object fields (so footer.columns[i].links
        // can render its NavLink {label, href} pairs).
        return arr
          .map((v) => {
            if (v === null || v === undefined) return '';
            if (typeof v === 'object') {
              return inner.replace(/\{\{(\w+)\}\}/g, (_, k) => {
                const innerVal = v[k];
                return innerVal === undefined || innerVal === null
                  ? ''
                  : escape(String(innerVal));
              });
            }
            return inner.replace(/\{\{\.\}\}/g, escape(String(v)));
          })
          .join('');
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

  /**
   * Apply page-metadata (SEO) edits to the <head>:
   *   <title data-cms-meta="pageTitle">…</title>
   *     → textContent overwritten with meta.pageTitle.
   *   <meta data-cms-meta-attr="description" content="…">
   *     → `content` (or `href` for <link>) overwritten with meta[key].
   *
   * Client-side meta updates work for browsers and JS-rendering
   * crawlers (Googlebot/Bingbot). Legacy bots that don't run JS see
   * the static fallback tags — keep those current as a safety net.
   */
  function applyMeta(meta) {
    if (!meta) return;
    document.querySelectorAll('[data-cms-meta]').forEach((el) => {
      const key = el.getAttribute('data-cms-meta');
      const v = meta[key];
      if (v === undefined || v === '') return;
      el.textContent = v;
    });
    document.querySelectorAll('[data-cms-meta-attr]').forEach((el) => {
      const key = el.getAttribute('data-cms-meta-attr');
      const v = meta[key];
      if (v === undefined || v === '') return;
      // <link rel="canonical"> uses href; <meta> uses content.
      const attr = el.tagName === 'LINK' ? 'href' : 'content';
      el.setAttribute(attr, v);
    });
  }

  /**
   * Live "Featured courses" grid. Queries the public `courses`
   * collection (readable by anonymous browsers per Firestore rules),
   * renders the first 6 isFeatured docs into #cms-featured-courses-grid
   * using <template id="cms-tpl-featured-course">. The wrapping
   * <section data-cms-hide-when-empty> self-hides on:
   *   - Firestore reachable but no featured courses exist (yet).
   *   - Firestore unreachable / rules denied / SDK missing.
   *
   * Self-hiding prevents a dead "Featured courses" headline on a cold
   * project.
   */
  function renderFeaturedCourses(db) {
    const grid = document.getElementById('cms-featured-courses-grid');
    const tpl = document.getElementById('cms-tpl-featured-course');
    const section = grid && grid.closest('[data-cms-hide-when-empty]');
    if (!grid || !tpl || !section) return;

    const hide = () => { section.style.display = 'none'; };

    db.collection('courses')
      .where('isFeatured', '==', true)
      .limit(6)
      .get()
      .then((snap) => {
        if (snap.empty) return hide();
        const html = snap.docs
          .map((doc) => {
            const c = doc.data() || {};
            const view = {
              href: '#download', // mobile-only app for now
              title: c.title || '(untitled)',
              instructorName: c.instructorName || '',
              thumbnailUrl:
                c.thumbnailUrl
                || 'https://ilearnit.info/assets/img/og-cover.png',
              level: (c.level || '').toUpperCase(),
              categoryUpper: (c.category || '').toUpperCase(),
            };
            return renderTemplate(tpl.innerHTML, view);
          })
          .join('');
        grid.innerHTML = html;
      })
      .catch((err) => {
        console.warn('[cms] featured-courses fetch failed:', err);
        hide();
      });
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
      } else {
        const data = snap.data();
        bindScalars(document, data);
        bindLists(document, data);
        applyMeta(data.meta);
      }
    })
    .catch((err) => {
      console.warn('[cms] Fetch failed, keeping static defaults:', err);
    })
    .finally(() => {
      // Featured courses is independent of the CMS doc — run it even if
      // the CMS fetch failed.
      renderFeaturedCourses(db);
    });
})();
