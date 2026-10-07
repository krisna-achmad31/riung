# Riung — landing page (English)

Static site built from the `Web — Landing Page Riung (1440) · EN` frame in
`design/riung.pen`, served by Firebase Hosting (Spark/free plan) on project
`riung-5e979` → https://riung-5e979.web.app

## Deploy

```
npm i -g firebase-tools        # once
cd landing
firebase deploy --only hosting
```

In CI or a cloud session, auth comes from `FIREBASE_TOKEN`
(`firebase login:ci`): `firebase deploy --only hosting --token "$FIREBASE_TOKEN"`.

## Waitlist form

`public/waitlist.js` writes `{email, lang, source, createdAt}` to the Firestore
collection `waitlist`. It reads the Firebase web config from Hosting's
reserved `/__/firebase/init.json`. Both one-time steps are done (Oct 2026):

1. Web app **Riung Landing** (`1:809457116609:web:3210353f3e683f7e47fb40`)
   is registered, so `init.json` is served.
2. `riung/firestore.rules` is deployed. It replaced the open test-mode rules;
   `waitlist` is create-only with no client reads.

If either step is undone, the form shows "couldn't save your email right now"
instead of pretending to succeed. Read entries in the Console (Firestore →
`waitlist`).

### Redeploying Firestore rules

`riung/` has no `firebase.json`. Either paste `riung/firestore.rules` into
Console → Firestore → Rules, or create a throwaway config next to it:

```
cd riung
echo '{"firestore":{"rules":"firestore.rules"}}' > firebase.json
firebase deploy --only firestore:rules --project riung-5e979
rm firebase.json
```

Rules always replace the whole ruleset. The wallet check
(`isValidWalletDelta`) only allows listed earn/spend amounts, so a new price
or reward in `economy.dart` must be added there too.

## Legal pages

`public/privacy.html` and `public/terms.html` (served as `/privacy`, `/terms`)
describe what the app actually does with data. Keep them in sync with the
in-app privacy screen (`riung/lib/features/profil/screens/kebijakan_privasi_screen.dart`
and `ProfilStrings.privacy*`). Bump `styles.css?v=` in all three HTML pages
whenever `styles.css` changes.

## Assets

`public/assets/*.webp` are resized from `design/aset3d_cut/`; the phone
mockups (`phone_home`, `step_*`) are renders of the phone frames inside the
landing design.

`public/assets/misteri_*.webp` are the hidden Habit Monster silhouettes for
the "Still hiding" teaser. They're built by
`design/aset3d_cut/siluet/build_siluet.py` from the wild art and numbered in
Big Quiz order on purpose, so the file names don't give the monsters away.
