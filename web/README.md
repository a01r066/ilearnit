# iLearnIt — Marketing site (`ilearnit.info`)

Static landing site deployed to **Firebase Hosting**, served at
[https://ilearnit.info](https://ilearnit.info).

## Pages

| URL              | File                  | Purpose                                  |
| ---------------- | --------------------- | ---------------------------------------- |
| `/`              | `public/index.html`   | Hero, instruments, features, pricing, FAQ, about, contact |
| `/about`         | `public/about.html`   | Company story, instructor philosophy     |
| `/help`          | `public/help.html`    | Help center — accounts, purchases, playback |
| `/contact`       | `public/contact.html` | Email + mailing address                  |
| `/privacy`       | `public/privacy.html` | Privacy policy                           |
| `/terms`         | `public/terms.html`   | Terms of service                         |
| `/404`           | `public/404.html`     | Custom 404 page                          |

Routing relies on Firebase Hosting's [`cleanUrls`](https://firebase.google.com/docs/hosting/full-config#clean_urls)
so the `.html` extension is stripped at the edge. Both `/about` and
`/about.html` resolve to the same file; the canonical form is the clean URL.

## Layout

```
web/
├── public/                 # what Firebase deploys
│   ├── index.html
│   ├── about.html
│   ├── help.html
│   ├── contact.html
│   ├── privacy.html
│   ├── terms.html
│   ├── 404.html
│   ├── robots.txt
│   ├── sitemap.xml
│   └── assets/
│       ├── css/styles.css
│       ├── js/main.js
│       └── img/favicon.svg
├── firebase.json           # hosting config (caching, headers, redirects)
├── .firebaserc             # project alias (prod → ilearnit-31f41)
├── package.json            # firebase-tools + convenience scripts
└── README.md               # this file
```

Design tokens (`--c-primary`, instrument colours, type scale) deliberately
mirror the Flutter app's `AppColors` / `AppTextStyles` so the brand reads
the same on web and mobile.

## Local preview

```bash
cd web
npx firebase emulators:start --only hosting
# → http://localhost:5000
```

Edit any HTML/CSS/JS file and refresh — no build step required.

## First-time setup

```bash
cd web

# 1. Install the CLI (or use npx — it's listed under devDependencies).
npm install

# 2. Sign in to the Google account that owns the Firebase project.
npx firebase login

# 3. Confirm the project alias picks up the right Firebase project.
npx firebase projects:list
# Expect: ilearnit-31f41 (default / prod), ilearnit-dev

# 4. (Optional) link the prod project to a Hosting "site" called
#    "ilearnit-info" — the target in .firebaserc points to it.
npx firebase target:apply hosting main ilearnit-info --project prod
```

## Deploy

```bash
# Deploy to prod (writes to ilearnit-31f41 → ilearnit.info)
npm run deploy

# Or deploy to dev for staging
npm run deploy:dev
```

The first prod deploy will hand you a temporary URL like
`ilearnit-31f41.web.app`. The custom domain step below makes `ilearnit.info`
point at the same files.

## Custom domain — `ilearnit.info`

### 1. Add the domain in Firebase Console

1. Firebase Console → your prod project (`ilearnit-31f41`) → **Hosting**.
2. Click **Add custom domain**.
3. Enter `ilearnit.info` and press **Continue**.
4. Optionally add `www.ilearnit.info` and redirect it to the apex domain.

Firebase will show you two ownership records and the IPs you'll need.
Don't close that page until DNS is set.

### 2. Update DNS at your registrar

You bought `ilearnit.info` from a registrar (Namecheap / Cloudflare / Google
Domains / Porkbun, etc.). Open its DNS panel and add:

| Type  | Name                        | Value                              | TTL   |
| ----- | --------------------------- | ---------------------------------- | ----- |
| A     | `@` (apex / ilearnit.info)  | `199.36.158.100`                   | 3600  |
| A     | `@`                         | `199.36.158.101`                   | 3600  |
| CNAME | `www`                       | `ilearnit-31f41.web.app`           | 3600  |
| TXT   | `@` (only if Firebase asks) | _(the ownership token from step 1)_| 3600  |

> The two `A` records are Firebase Hosting's edge IPs; they are the same
> for every Firebase Hosting site. The exact values Firebase shows you in
> the console are authoritative — copy them, not these.

### 3. Wait for SSL provisioning

Firebase auto-issues a Let's Encrypt SSL certificate once DNS propagates.
That typically takes **10–60 minutes**, sometimes up to 24 hours for slow
TLDs. While it's pending, the console will show "Provisioning certificate";
once green, `https://ilearnit.info` serves the site with a valid cert.

### 4. (Optional) Force www → apex redirect

If you added `www.ilearnit.info` to Firebase Hosting, set its "Connected
hosts" mode to **Redirect** in the console. That makes `www.ilearnit.info`
issue a 301 to `ilearnit.info`.

## Smoke-test checklist post-deploy

- [ ] `https://ilearnit.info/` loads with a valid cert.
- [ ] `/about`, `/help`, `/contact`, `/privacy`, `/terms` all resolve and
      render the right page (cleanUrls).
- [ ] Mobile nav opens/closes on a 360-wide viewport.
- [ ] FAQ accordion expands.
- [ ] `/help-center`, `/privacy-policy`, `/tos` issue 301 redirects to the
      canonical URLs.
- [ ] `/some-random-url` returns the custom 404 page.
- [ ] `curl -I https://ilearnit.info/assets/css/styles.css` shows
      `Cache-Control: public, max-age=31536000, immutable`.
- [ ] `curl -I https://ilearnit.info/` shows
      `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`.

## Updating content

1. Edit the relevant `public/*.html` (or the shared CSS / JS).
2. `npx firebase emulators:start --only hosting` to preview locally.
3. `npm run deploy` to push live.

Hosting deploys are atomic — visitors mid-request finish on the old version,
new requests get the new files. Roll back via the Firebase Console → Hosting
→ release history → **Rollback** if anything goes wrong.

## Headers & caching at a glance

| File type      | `Cache-Control`                             |
| -------------- | ------------------------------------------- |
| `.html`        | `public, max-age=300, must-revalidate`      |
| `.css`, `.js`, `.svg`, `.woff2` | `public, max-age=31536000, immutable` |
| images         | `public, max-age=2592000` (30 days)         |

The HTML cache is short so content updates appear within ~5 minutes. Static
assets are versioned by filename — if you ever bump CSS aggressively, rename
the file (e.g. `styles.v2.css`) so the long cache is bypassed cleanly.
