# Landing-page CMS

The marketing site (`web/public/index.html`) is now hydrated from a
single Firestore doc at `site_content/landing`. Admins edit the doc
through the admin portal at `/admin/landing-page`; the public web
loads the doc on first paint via `assets/js/cms.js` and overwrites
matching DOM nodes.

## Data model

```
site_content/landing
  hero: {
    eyebrow                : string
    title                  : string
    subtitle               : string
    ctaPrimaryLabel        : string
    ctaPrimaryHref         : string
    ctaSecondaryLabel      : string
    ctaSecondaryHref       : string
    imageUrl               : string?
  }
  instruments: [
    { slug: 'guitar'|'piano'|'violin', title, description }
  ]
  features: [
    { icon: string, title: string, description: string }
  ]
  pricingTiers: [
    {
      name           : string
      priceLabel     : string
      billingNote    : string
      ctaLabel       : string
      ctaHref        : string
      isFeatured     : bool
      perks          : [string]
    }
  ]
  faqs: [
    { question: string, answer: string }
  ]
  about: {
    eyebrow                : string
    title                  : string
    paragraph1             : string
    paragraph2             : string
    paragraph2LinkLabel    : string
    paragraph2LinkHref     : string
  }
  aboutStats: [
    { value: string, label: string }
  ]
  instructorCallout: {
    eyebrow                : string
    title                  : string
    subtitle               : string
    perks                  : [string]
    ctaLabel               : string  (e.g. "Become an instructor")
    ctaHref                : string  → admin portal login URL
    secondaryCtaLabel      : string
    secondaryCtaHref       : string
  }
  nav: {
    links: [ { label: string, href: string } ]
    ctaLabel               : string
    ctaHref                : string
  }
  footer: {
    tagline                : string
    columns: [
      { heading, links: [ { label, href } ] }
    ]
    copyrightSuffix        : string
    credit                 : string
  }
  storeBadges: {
    appStoreHref           : string  ('#' until live)
    playStoreHref          : string
  }
  meta: {
    pageTitle              : string  → <title>
    description            : string  → <meta name="description">
    ogTitle                : string  → <meta property="og:title">
    ogDescription          : string  → <meta property="og:description">
    ogImageUrl             : string  → <meta property="og:image">
    canonicalUrl           : string  → <link rel="canonical"> + og:url
  }
  contact: {
    email          : string
    phone          : string
    address        : string
    twitterUrl     : string
    instagramUrl   : string
    youtubeUrl     : string
  }
  updatedAt        : Timestamp
```

We use one fat document instead of subcollections because the static
landing site needs every section in a single round-trip — splitting
adds round-trip latency without buying us anything (the editorial
scope is small).

### Become-an-instructor funnel

The `instructorCallout` section funnels prospective teachers from the
marketing page into the existing instructor-application pipeline that
already lives in the admin portal:

```
landing page                        admin portal
  Become-an-instructor CTA   ─►    /login  (Google / Apple / email)
                                     │  new user → role: 'student'
                                     ▼
                                   /apply  (InstructorApplyPage)
                                     │  writes instructor_applications/{uid}
                                     │  status: 'pending'
                                     ▼
                                   /pending  (waits for admin review)
                                     │
                                     ▼ admin approves at /admin/applications
                                     │  role flips to 'instructor'
                                     ▼
                                   /         (dashboard)
                                   /my-courses  → can author courses
```

No new backend was needed — the apply flow ships with the existing
admin portal (see `docs/admin_portal.md`). The CMS section is just
the marketing front door. To re-route to the prod admin portal once
it's live on a custom domain, edit `instructorCallout.ctaHref` in
`/admin/landing-page`.

### Live data — featured courses

`cms.js` also queries `courses where isFeatured == true limit 6`
independently of the CMS doc and renders the result into
`<section id="featured-courses">`. There's no admin editing for *which*
courses are featured — flip `courses/{id}.isFeatured = true` in the
existing courses admin and the marketing site picks it up on the next
visitor (no save / publish on the landing-page editor needed).

When the query is empty or fails (rules denied, network down, project
without a `courses` collection), the section self-hides via
`data-cms-hide-when-empty` so a dead heading never renders.

### Page metadata + SEO note

`<title>`, `<meta name="description">`, the `og:*` tags, and the
canonical URL are bound via `data-cms-meta` / `data-cms-meta-attr` and
rewritten client-side after the Firestore fetch. This works for
browsers and JS-rendering crawlers (Googlebot / Bingbot) but **some
legacy bots only read the static HTML**. Keep the baseline tags in
`web/public/index.html` current as a fallback. Long-term, a Cloud
Function trigger on `site_content/landing` write can pre-render the
HTML for static crawlers — filed as polish.

## How the static site hydrates

`assets/js/cms.js` runs on every visit:

1. Reads `firebaseConfig` (inlined at the top of `cms.js` — populate
   it from Firebase Console → Project Settings → Web).
2. Calls `firebase.firestore().collection('site_content').doc('landing').get()`.
3. For each element with `data-cms="path.to.field"`, replaces
   `textContent` with the resolved value.
4. For each element with `data-cms-href="..."` / `data-cms-src="..."`,
   replaces the attribute.
5. For each `data-cms-list="features"` container, clones the matching
   `<template id="cms-tpl-feature">` once per item and substitutes
   `{{field}}` placeholders. Arrays inside an item iterate via
   `{{#perks}}<li>{{.}}</li>{{/perks}}`.

**Failure modes — by design:**

- Firebase SDK didn't load (ad blocker, network) → static fallback HTML stays. The page never appears broken.
- `firebaseConfig` not populated → cms.js warns in console, fallback stays.
- `site_content/landing` doc missing → fallback stays.
- A specific path returns `undefined` or `''` → that DOM node keeps its static text.

## Admin editor

Path: `/admin/landing-page` (admin role required).

Twelve sections — Hero, Instruments, Features (reorderable), Pricing,
FAQ (reorderable), About + stats, Become an instructor, Top nav,
Footer (with link columns), Store badges, SEO/page metadata, Contact
+ social. Save publishes
immediately; there is no separate draft / publish state. The "Save
changes" button only lights up when the form draft diverges from the
last loaded state (deep equality on the Freezed entities).

A "Discard changes" button reverts the draft to the last-saved
snapshot. Refreshing the page also discards local edits because the
notifier rebootstraps from Firestore on mount.

## Firestore rules

```
match /site_content/{slug} {
  allow read: if true;     // public — landing site fetches anonymously
  allow write: if isAdmin();
}
```

Instructors cannot tamper with the marketing copy. The `isAdmin()`
helper already requires `users/{uid}.role == 'admin'` and
`!isSuspended()`.

## Seeding a new project

```
node sample_data/seed_site_content.js
```

Uses the Firebase Admin SDK with application-default credentials.
Sets the full doc to the defaults already baked into the static
fallback HTML so the live site looks identical before any editorial
work happens.

## Adding new fields

1. Add the field to `LandingContent` / its sub-entities in
   `lib/admin/site_content/domain/entities/landing_content.dart`.
2. Mirror it on the model in
   `lib/admin/site_content/data/models/landing_content_model.dart`
   and wire `fromEntity` / `toEntity`.
3. Run `dart run build_runner build --delete-conflicting-outputs`.
4. Surface a TextField in
   `lib/admin/site_content/presentation/pages/admin_landing_content_page.dart`.
5. Add a `data-cms="newField"` binding in `web/public/index.html`.
6. Optionally update `sample_data/seed_site_content.js`.

## Testing checklist

- Open `/admin/landing-page` as an admin. Loading spinner clears,
  fields populate from the seed doc.
- Edit the hero title. The "Save changes" button enables. Save.
  Snackbar confirms.
- Hard-refresh `https://ilearnit.info` (or your local hosting). The
  hero title shows the new value within ~1 second.
- Disable network on devtools → reload → static fallback content
  shows. Console logs the SDK fetch failure.
- Try writing as a non-admin signed-in user → Firestore rule denies.
- Confirm `updatedAt` ticks on every save (visible in Firestore
  console).

## Troubleshooting: "I saved in admin but the landing page still shows old data"

99% of the time this is one of three things, in order of likelihood:

### 1. The admin and the public site are on different Firebase projects

The admin portal writes to whichever Firestore the **admin** build is
configured for (`Flavor.dev` → `ilearnit-dev`, `Flavor.prod` →
`ilearnit-31f41`). The static landing page reads from whichever
Firestore the **`cms.js`** is configured for. If they don't match, the
edits go to one doc and the page reads from a completely different
one.

`cms.js` now picks `FIREBASE_CONFIGS.dev` vs `.prod` automatically
from `window.location.hostname`:

| Hostname | Flavor |
|---|---|
| `localhost`, `127.0.0.1`, `ilearnit-dev.*` | `dev` |
| `ilearnit.info`, `www.ilearnit.info`, `ilearnit-31f41.*` | `prod` |
| Anything else | `dev` |

Verify which project your browser tab is reading from — `cms.js` logs
a single line on every page load:

```
[cms] Using Firebase project "ilearnit-dev" (flavor=dev).
```

If the project name there doesn't match the project you edited, fix
the hostname or override in DevTools:

```js
localStorage.setItem('ilearnit:cms_flavor', 'prod');
location.reload();
```

The `prod` config in `cms.js` starts with an empty `apiKey:` —
deliberate, so deploying to prod without filling it in falls back to
dev *with a console warning* instead of silently failing at SDK init.
Paste the prod web app config from Firebase Console → Project
`ilearnit-31f41` → Settings → General → Your apps → Web before the
first prod deploy.

### 2. The browser cached the old `cms.js` or HTML

Firebase Hosting caches `/assets/js/**` for 7 days with
`immutable` per `firebase.json`. After a `firebase deploy` your
browser may still hold the previous JS until you bust the cache.

Force a fresh load:
- Cmd+Shift+R / Ctrl+Shift+R (hard reload).
- DevTools → Network tab → check "Disable cache" → reload.
- In production, append a cache-buster: `https://ilearnit.info/?v=2`.

The HTML itself is `max-age=0, must-revalidate` so it always re-fetches,
but the script tag inside still references the cached JS URL.

### 3. The Firestore web SDK persistence cache

If you previously had IndexedDB persistence enabled (we don't by
default, but a `firebase.firestore().enablePersistence()` call would
turn it on), the first read after a write might hit the local cache.
Clear it in DevTools → Application → IndexedDB → delete
`firestoreexp` (or close all tabs of the site for ~30 seconds).

## Build steps after editing entities

```
dart run build_runner build --delete-conflicting-outputs
```

to regenerate `landing_content.freezed.dart`,
`landing_content_model.freezed.dart`, and `landing_content_model.g.dart`.

After extending the schema (new sub-entity types or new top-level
fields), also:

1. Add a parallel `<Type>Model` in `landing_content_model.dart` with
   `fromJson` / `toJson` / `toEntity` / `fromEntity`.
2. Add the new top-level key to `SiteContentDataSource.save`'s manual
   map (otherwise the field never reaches Firestore — freezed's
   nested toJson can drop child models).
3. Add a `<Section>Card` widget + a section helper on
   `SiteContentFormNotifier`.
4. Add a `<template id="cms-tpl-X">` and `data-cms-list="X"` or
   `data-cms="X.field"` binding in `web/public/index.html`.
5. Refresh the defaults in `sample_data/seed_site_content.js`.
6. Update this doc's Data model section.
