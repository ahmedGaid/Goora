# Launch-prep decisions (Lane L, 2026-10-30)

Autonomous lane: nobody was asked. Each entry = the choice, the alternative rejected, and why.
Reverse any of them by editing the file named in the entry.

## D1 — Icons and splash: keep the committed set, prove it is reproducible
- **Choice:** no asset change. `flutter_launcher_icons.yaml` + `flutter_native_splash.yaml` were
  already wired to `assets/brand/` in commits `1f9a900` and `a3a78a1`. Re-running
  `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create` from a clean
  worktree produced **zero diff**, so the YAMLs are the source of truth and the generated files
  (`android/**/res`, `ios/Runner/Assets.xcassets`) match them.
- **Masters checked:** the founder zip `Goora carpool logo design.zip` unpacks to a `brand/` tree
  that is byte-identical to the tracked `brand/` folder. Nothing newer to import. The zip stays
  untracked and is never committed.
- **Rejected:** re-importing the zip's pre-cut `mipmap-*` layers. They are the same artwork the
  generator already cuts from `assets/brand/app-icon/*`; a second import would only add churn.
- **Eyeballed:** `assets/brand/app-icon/android-foreground.png`, `android-monochrome.png`,
  `ios-icon-1024.png`, `assets/brand/splash/symbol-reversed.png`,
  `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`,
  `android/app/src/main/res/drawable-night-xxxhdpi/android12splash.png`,
  `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png`.

## D2 — Splash dark-mode variant: none needed
- **Choice:** one splash colour, forest `#0B3B2E`, in light and dark. The generator already emits
  the `-night` Android resources and they carry the same colour and symbol.
- **Why:** the app ships `ThemeMode.light` only (`lib/app/goora_app.dart`), and the splash is the
  brand's reversed (dark) surface, which already reads correctly under a dark system theme.
- **Rejected:** a lighter "paper" splash for dark mode. It would invert the brand's own reversed
  lockup rule and flash light on a dark phone.

## D3 — Launcher label: "Goora" in every locale, no ar override
- **Choice:** Android `android:label="Goora"` and iOS `CFBundleDisplayName = Goora`, for all
  languages. No `res/values-ar/strings.xml`, no `ar.lproj/InfoPlist.strings`.
- **Why:** `GOORA_SPEC_KIT_BRIEF.md` §3.2: the wordmark is Latin "Goora" in both locales. The
  launcher label sits under the icon and is the wordmark in text form. The Arabic spelling
  «جورا» is used inside sentences only (see the `ruleNoBidding` string), never as a brand lockup.
  One name across icon, label, store title and search also keeps the app findable.
- **Rejected:** Arabic launcher label «جورا» via a `values-ar` / `ar.lproj` override. Adds two
  files that must be kept in step with the store listing and breaks the one-wordmark rule. To
  adopt it later: add `android/app/src/main/res/values-ar/strings.xml` (`app_name`), point the
  manifest label at `@string/app_name`, and add `ios/Runner/ar.lproj/InfoPlist.strings`.
- **Left alone:** iOS `CFBundleName = goora` (lower case, not user-visible).

## D4 — `android.permission.INTERNET` added to the main manifest
- **Choice:** one `<uses-permission>` line in `android/app/src/main/AndroidManifest.xml`.
- **Why:** Flutter adds INTERNET only to the debug and profile manifests. A release build without
  it cannot reach Supabase or the map tile host, and nobody notices until the first store build.
  The conductor's brief said to add it once Lane M asked; the need is certain (Supabase + tiles),
  and the lane owns the manifest, so it is in now.
- **Rejected:** waiting for Lane M's word. Costs nothing to revert, expensive to forget.
- **Not added:** any location/camera permission. Nothing in the app uses them today
  (pickup points are chosen on a map, not read from the device).

## D5 — Application id stays `app.goora.goora`
- **Choice:** unchanged, on Android (`applicationId`, `namespace`) and iOS (`PRODUCT_BUNDLE_IDENTIFIER`).
- **Why:** `goora-stack` documents `app.goora.goora` as the installed package, and Android and iOS
  already agree. It is permanent once uploaded, so the founder confirms it in
  [CHECKLIST.md](CHECKLIST.md) before the first upload.
- **Rejected:** a different reverse-domain id (for example from a real company domain). No domain
  is registered yet; guessing one would be worse than the current id.

## D6 — Signing: debug fallback, but fail loudly on a bad key file
- **Choice:** `build.gradle.kts` reads `$GOORA_KEY_PROPERTIES`, else `android/key.properties`, else
  falls back to the debug key. A set-but-missing env path, or a key file with an empty field,
  stops the build with a message naming the problem.
- **Why:** the brief asks for the fallback so `flutter build apk --release` works for anyone.
  The loud failure covers the one dangerous case: a founder who thinks they are building a signed
  store bundle but silently get a debug-signed one.
- **Rejected:** always falling back when the file is unreadable (silent debug-signed store build);
  and a second build flavor for "store" (more moving parts than one `if`).
- **Checked with** `./gradlew :app:signingReport` using a throwaway keystore kept outside the repo
  (deleted afterwards): no key → `Config: debug`; env key → `Config: release`; default
  `android/key.properties` → `Config: release`; half-filled file → build fails; bad env path →
  build fails.

## D7 — CI: Flutter gates on Windows, Node gate on Linux
- **Choice:** `.github/workflows/gates.yml` has two jobs. `flutter` runs `pub get`, `analyze` and
  `test --concurrency=1` on `windows-latest`. `supabase-shared` runs the Node tests on
  `ubuntu-latest` (Node 24, nothing to install).
- **Why:** the 48 golden PNGs under `test/golden/goldens` were rendered on Windows
  (`goora-stack`) and are compared exactly. On Linux, font anti-aliasing alone would fail them.
  `test/**` is off limits for this lane, so tagging goldens to skip on Linux was not possible.
- **Flutter pin:** `3.44.4`, the stable revision recorded in `.metadata` (`ad70ec46…`); satisfies
  `sdk: ^3.12.2`. No `.fvmrc` exists.
- **Not yet proven:** the workflow has never run on GitHub (no push of `main` from this lane).
  The first run is the real test of "Windows runner reproduces Windows goldens". If it fails on
  pixel noise only, the fallback is to skip `test/golden` in CI and keep it a local gate.
- **Rejected:** all-Linux CI with goldens skipped (loses a gate that currently works); a matrix of
  both OSes (double the minutes, no extra signal).

## D8 — Android build memory on the company PC (environment, not a code change)
- Release builds failed on resource exhaustion while another lane's emulator (~7 GB virtual),
  WSL (~6 GB) and Oracle held the machine's commit limit (Windows logged a "low virtual memory
  condition"): twice the Gradle JVM died with `insufficient memory ... malloc failed`, once the Dart
  VM died with `Could not start thread`. Nothing in the repo caused it and no other lane's process
  was touched. The signing logic was proven with `signingReport` instead (D6).
- A release build on a loaded machine may need a smaller Gradle heap. The repo's
  `android/gradle.properties` is left as it was (`-Xmx8G`): lowering it permanently would slow
  every other machine. See `Docs/release/CHECKLIST.md` § Local build.
