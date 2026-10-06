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
reserved `/__/firebase/init.json`, so two one-time steps are needed before it
works:

1. Firebase Console → Project settings → Your apps → **Add app → Web**
   (no Hosting setup needed there). This makes `init.json` available.
2. Deploy the `waitlist` rule added to `riung/firestore.rules`
   (create-only, no client reads): from `riung/`, `firebase deploy --only firestore:rules`.

Until then the form shows "couldn't save your email right now" instead of
pretending to succeed. Read entries in the Console (Firestore → `waitlist`).

## Assets

`public/assets/*.webp` are resized from `design/aset3d_cut/`; the phone
mockups (`phone_home`, `step_*`) are renders of the phone frames inside the
landing design.
