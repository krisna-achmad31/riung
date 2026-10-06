# Riung — landing page (English)

Static site served by Firebase Hosting (Spark/free plan) on project `riung-5e979`.

```
cd landing
firebase deploy --only hosting
```

The live URL is `https://riung-5e979.web.app`. Page content lives in `public/`.
In CI or a cloud session, auth comes from the `FIREBASE_TOKEN` env var
(`firebase login:ci`) or a service account in `GOOGLE_APPLICATION_CREDENTIALS`.
