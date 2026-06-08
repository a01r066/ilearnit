#!/usr/bin/env node
// One-shot seeder for the landing-page CMS doc.
//
// Run:
//   node sample_data/seed_site_content.js
//
// Reads the same service-account credentials as seed_firestore.js — set
// GOOGLE_APPLICATION_CREDENTIALS to point at your downloaded
// service-account JSON, or run inside a Firebase project that has
// application default credentials.

const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

const payload = {
  hero: {
    eyebrow: 'Online classical lessons',
    title:
      'Master guitar, piano, and violin with concert-level instructors.',
    subtitle:
      'iLearnIt brings world-class classical musicians into your living room. ' +
      'Stream structured courses, download sheet music and exercises, and ' +
      'practice on your own schedule.',
    ctaPrimaryLabel: 'Start learning today',
    ctaPrimaryHref: '#download',
    ctaSecondaryLabel: 'Browse instruments',
    ctaSecondaryHref: '#instruments',
    imageUrl: '',
  },
  features: [
    {
      icon: '▶',
      title: 'Stream-quality video',
      description:
        'Multi-angle close-ups of bow technique, hand position, and ' +
        'fingering — recorded in studio.',
    },
    {
      icon: '♪',
      title: 'Audio lessons + backing tracks',
      description:
        "Listen on the commute, then practice along with the " +
        "instructor's accompaniment.",
    },
    {
      icon: '📑',
      title: 'Annotated sheet music',
      description:
        "Downloadable PDFs with the instructor's markings, fingerings, " +
        'and practice annotations.',
    },
    {
      icon: '🎯',
      title: 'Structured curriculum',
      description:
        'Every course is broken into sections with clear learning ' +
        'outcomes — no aimless scrolling.',
    },
    {
      icon: '🔒',
      title: 'One purchase, forever',
      description:
        'Buy a course once. It stays in your library across devices.',
    },
    {
      icon: '🌙',
      title: 'Offline & dark mode',
      description:
        'Pre-download resources for travel. Bright stage lights or dim ' +
        'practice room — we look right.',
    },
  ],
  pricingTiers: [
    {
      name: 'Basic',
      priceLabel: '$9.99 / course',
      billingNote: 'Introductory courses — perfect for first-time students.',
      ctaLabel: 'See basic courses',
      ctaHref: '#download',
      isFeatured: false,
      perks: [
        'Single instructor track',
        '~10 lessons per course',
        'Sheet music PDFs included',
        'Lifetime access',
      ],
    },
    {
      name: 'Standard',
      priceLabel: '$19.99 / course',
      billingNote:
        'Intermediate courses with extended exercises and live Q&A clips.',
      ctaLabel: 'See standard courses',
      ctaHref: '#download',
      isFeatured: true,
      perks: [
        '20+ lessons per course',
        'Audio backing tracks',
        'Annotated sheet music',
        'Instructor practice prompts',
        'Lifetime access',
      ],
    },
    {
      name: 'Premium',
      priceLabel: '$39.99 / course',
      billingNote:
        'Concert-level courses with deep interpretive analysis.',
      ctaLabel: 'See premium courses',
      ctaHref: '#download',
      isFeatured: false,
      perks: [
        '30+ lessons per course',
        'Multi-camera recordings',
        'Annotated full scores',
        'Advanced repertoire',
        'Lifetime access',
      ],
    },
  ],
  faqs: [
    {
      question: 'Is there a free trial?',
      answer:
        'Every course includes free preview lectures — typically the first ' +
        'two of each section. Browse the curriculum, watch the previews, ' +
        'and only pay for the course if you find it useful.',
    },
    {
      question: 'Do I have to subscribe?',
      answer:
        'No subscriptions required. Each course is a one-time purchase and ' +
        'stays in your library forever.',
    },
    {
      question: 'What devices does iLearnIt support?',
      answer:
        'iLearnIt runs on iOS 13+ and Android 8+. The same purchase works ' +
        'across all your devices on the same store account.',
    },
    {
      question: 'Can I download lessons for offline practice?',
      answer:
        'Yes — sheet music and exercise PDFs are downloadable from the ' +
        'lecture page. Offline video downloads are on the roadmap.',
    },
    {
      question: 'How do I restore purchases on a new device?',
      answer:
        'Sign in with the same account, open Profile → Restore purchases, ' +
        "and the app re-downloads every course you've ever bought.",
    },
    {
      question: 'Who are the instructors?',
      answer:
        'Each instructor is a working professional with conservatory ' +
        'training and concert experience.',
    },
  ],
  contact: {
    email: 'hello@ilearnit.info',
    phone: '+84 24 0000 0000',
    address: 'iLearnIt, 1 Conservatory Way, Hanoi, Vietnam',
    twitterUrl: '',
    instagramUrl: '',
    youtubeUrl: '',
  },
  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
};

async function main() {
  await db.collection('site_content').doc('landing').set(payload);
  console.log('✅ site_content/landing seeded.');
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
