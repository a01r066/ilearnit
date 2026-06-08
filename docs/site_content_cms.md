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

Five sections — Hero, Features (reorderable), Pricing, FAQ
(reorderable), Contact + social. Save publishes immediately; there is
no separate draft / publish state. The "Save changes" button only
lights up when the form draft diverges from the last loaded state
(deep equality on the Freezed entities).

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

## Build steps after editing entities

```
dart run build_runner build --delete-conflicting-outputs
```

to regenerate `landing_content.freezed.dart`,
`landing_content_model.freezed.dart`, and `landing_content_model.g.dart`.
