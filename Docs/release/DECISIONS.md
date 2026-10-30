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
