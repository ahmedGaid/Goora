# Before a store build — checklist

A list of what is still open, not a promise of dates. Items marked **founder** need an account,
a secret or a decision that code cannot make. Tick them here as they land.

## Already in the repo (nothing to do)

- [x] App icon (Android adaptive + monochrome, iOS) and native splash, from `assets/brand/`
      through `flutter_launcher_icons.yaml` and `flutter_native_splash.yaml`.
- [x] Launcher name "Goora" on Android and iOS ([DECISIONS.md](DECISIONS.md) D3).
- [x] Release signing reads a key from outside the repo ([SIGNING.md](SIGNING.md)).
- [x] `INTERNET` permission in the main Android manifest (D4).
- [x] CI runs the three gates on every push and PR (`.github/workflows/gates.yml`, D7).

## Accounts and keys (founder)

- [ ] **Upload key.** Create the keystore and `key.properties` in `D:\Secrets\Goora\`, back it up
      ([SIGNING.md](SIGNING.md)).
- [ ] **Google Play Console** developer account, then create the app and enrol in Play App Signing.
- [ ] **Apple Developer** account, an App Store Connect app record, a Mac with Xcode for the iOS
      build and signing. iOS cannot be built or signed from the Windows PC.
- [ ] **Application id.** Confirm `app.goora.goora` is the final id. It cannot change after the
      first upload (D5).
- [ ] **Privacy policy URL.** Both stores require a public page. The app handles phone numbers and
      commute routes, so it must say what is stored, who sees it (pickup points only, never home
      addresses) and how a user deletes their account.
- [ ] **Support contact** (email or page) for the store listings.
- [ ] **Domain for shared trip links.** `SHARE_BASE_URL` falls back to the placeholder
      `https://goora.example`. Pick the real domain; if links should open the app directly, that
      also needs Android App Links and iOS Universal Links (not set up yet).

## Backend (founder + the real-backend work)

- [ ] **Supabase project** created. Apply the migrations in `supabase/migrations/` and deploy the
      Edge Functions in `supabase/functions/` (`match`, `commute-day`, `evening-cutoff`). Check
      each function's schedule or trigger after deploy.
- [ ] **`SUPABASE_URL` and `SUPABASE_ANON_KEY`** (the anon key only; never the service-role key in
      an app build).
- [ ] **The build uses the real backend.** Today the app can run on fake in-memory repositories
      (`lib/features/*/data/fake_*`). Confirm the store build wires the Supabase ones.
- [ ] **Phone-code (OTP) provider.** `OTP_PROVIDER` empty or unknown means `fake`, which accepts the
      code `123456` for any number. A store build must set a real value (`whatsapp`, `firebase` or
      `sms`) and have that provider's account and credentials ready. Never ship `fake`.
- [ ] **Payment providers.** The wallet screens name InstaPay and Fawry. Merchant accounts, API
      keys and the server-side settlement are not something the app build can supply.
- [ ] **Map tile key.** `MAP_TILE_URL_TEMPLATE` and `MAP_TILE_API_KEY` for a commercial tile host.
      The public OpenStreetMap tile servers forbid production use.

## Build configuration

- [ ] Put the production values in a file outside the repo (for example
      `D:\Secrets\Goora\prod.env`, same keys as `.env.example`) and pass it with
      `--dart-define-from-file`. Do not commit it.
- [ ] Bump `version:` in `pubspec.yaml` for each upload (`0.1.0+1` today).
- [ ] Build the signed bundle: `flutter build appbundle --release --dart-define-from-file=...`
      ([SIGNING.md](SIGNING.md)).
- [ ] Confirm the bundle is signed by the upload key, not the debug key
      (`keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab`).
- [ ] Install the release build on a real phone and walk sign-in, a commute, and the wallet once,
      with the real backend. Release mode differs from debug (permissions, code shrinking).

## Store listing (founder)

- [ ] Listing text in Arabic and English. Tone and words: `goora-brand`; the product is
      cost-sharing, never a taxi.
- [ ] Graphics already in the repo: `store_assets/play-store-icon-512.png` and
      `store_assets/play-feature-graphic-1024x500.png`.
- [ ] Phone screenshots in both languages (the brand rules sheet is `brand/brand-sheet.png`).
- [ ] Play **Data safety** form and Apple **App privacy** answers, consistent with the privacy policy.
- [ ] Content rating questionnaire (Play) and age rating (Apple).
- [ ] Legal sign-off that the cost-sharing positioning fits Egyptian rules for ride services
      (the constitution cites Law 87/2018).

## Local build (company PC)

Release builds can die with `insufficient memory`, `Could not start thread` or a vanished Gradle
daemon when an emulator, WSL and a database are all running. Close what you can, or give Gradle
a smaller heap for this machine only, without touching the repo, in
`%USERPROFILE%\.gradle\gradle.properties`:

```properties
org.gradle.jvmargs=-Xmx3G -XX:MaxMetaspaceSize=1G
```

That file wins over `android/gradle.properties`, which keeps `-Xmx8G` for other machines.
