# Goora brand assets

Mark: **Daily Loop**. An open ring stands for the daily route, and the dot in the gap is the rider it picks up. It is a single flat color: forest `#0E3B2F` on paper `#F5F4EF`, or reversed. Mint `#2BC275` is for marketing accents only and never goes inside the logo.
PNG scale suffixes are `-1x`, `-2x`, `-3x`. All text is outlined in the SVGs, so no fonts are needed.

`brand-sheet.png` is the one-page rules sheet: clear space, minimum size, color, type, usage, home screens.

## logo/
| File | Use |
|---|---|
| goora-symbol-{primary,reversed}.svg / .png | Symbol alone (avatars, in-app header, watermark). PNG base 256 px |
| goora-symbol-small-16-{primary,reversed}.svg | Small-size master for sizes under 24 px (wider gap, lighter stroke) |
| goora-wordmark-{primary,reversed} | Wordmark alone (where the symbol already appears nearby) |
| goora-lockup-horizontal-{primary,reversed} | Default logo: web header, documents, email |
| goora-lockup-stacked-{primary,reversed} | Square and centered layouts: splash, posters |
| goora-lockup-arabic-{primary,reversed} | RTL lockup, symbol + «مشوارك.. سوا.» in Cairo Bold |

## app-icons/
| File | Use |
|---|---|
| ios/AppIcon-1024.png (+ .svg) | iOS App Store / Xcode single-size icon. Opaque, square (iOS applies the mask) |
| android/mipmap-*/ic_launcher_foreground.png | Adaptive icon foreground, 108dp per density (432 px at xxxhdpi) |
| android/mipmap-*/ic_launcher_background.png | Adaptive icon background, solid #0E3B2F |
| android/mipmap-*/ic_launcher_monochrome.png | Android 13+ themed icon (only the alpha channel is used) |
| android/ic_launcher_{foreground,background,monochrome}.svg | Vector sources (convert to VectorDrawable in Android Studio) |
| android/adaptive-safe-zone-guide | Reference only: ⌀264 safe circle, 288 visible area |
| android/play-store-512.png | Google Play listing icon |

## web/
| File | Use |
|---|---|
| favicon.svg | `<link rel="icon" type="image/svg+xml">`, built on the 16 px master |
| favicon-16/32/48.png | PNG favicons / fallback (bundle into favicon.ico if needed) |
| apple-touch-icon-180.png | `<link rel="apple-touch-icon">` |
| pwa-192.png, pwa-512.png, pwa-icon.svg | Web manifest icons, `purpose: "any"` |
| pwa-maskable-192/512.png, pwa-maskable.svg | Web manifest icons, `purpose: "maskable"` (mark inside the 80% safe circle) |
| og-image-1200x630 | `og:image` / `twitter:image` |

## social/
| File | Use |
|---|---|
| avatar-400 | Profile picture on every network (circle-safe) |
| cover-1500x500 | X header / LinkedIn cover (content kept to the center) |
| instagram-post-template-1080 | Base layout for feed posts. Replace the headline per post |

## marketing/
| File | Use |
|---|---|
| play-feature-graphic-1024x500 | Google Play feature graphic |
| splash-390x844 (-1x/-2x/-3x) | App launch screen on #0B3B2E |
| hero-1920x1080 | Website hero, decks, press |

Flutter: point `flutter_launcher_icons` at `app-icons/ios/AppIcon-1024.png` (iOS) plus the adaptive foreground, background and monochrome PNGs (Android), and point `flutter_native_splash` at `logo/goora-lockup-stacked-reversed-3x.png` with color `#0B3B2E`.
