---
name: goora-brand
description: Goora brand & Arabic-copy enforcement — the standing "is this on-brand?" discipline for ANY UI, styling, copy, Arabic term, RTL layout, color, or state work on the daily-commute app at C:\AhmedGaid\Goora. Recall when building or reviewing any user-facing screen or string in either language, choosing a color/icon/word, or judging whether something feels like Goora. Pairs with goora-stack (implementation) and goora-status (live state).
---

# goora-brand — Goora brand & voice

**Personality**: calm, trustworthy, premium-but-accessible — never reads as a taxi company
(Constitution II/VI). Tagline: "Go together. Every day." / "مشوارك.. سوا."
**Canon**: `GOORA_SPEC_KIT_BRIEF.md` (repo root) is the single source of truth for color, font,
component and copy decisions — read it, don't guess, before inventing new UI.

## Tokens — `lib/core/theme/` (raw hex lives ONLY here, everywhere else references the token)
- Brand green family: `forest` `#0B3B2E` (darkest), `primary` `#0E3B2F`, `green` `#1FA463` (fill/
  accent), `mint` `#2BC275` (brighter accent), `greenText` `#0E6B45` (text-safe green — use this,
  not `green`, for text on light surfaces — contrast tested), `mintSurface` `#E7F5EC` (chip bg).
- Neutrals: `background` `#F5F4EF`, `surface` `#FFFFFF`, `border`/`borderStrong`/`divider` for
  hairlines, `textPrimary`/`textBody`/`textSecondary`/`textMuted` for the reading hierarchy.
- On-dark set (`onDarkSecondary`/`onDarkBody`/`onDarkBorder`/`onDarkDivider`) for forest/primary
  backgrounds — don't reuse the light-surface text colors there.
- Status: `warning*`, `info*`, `danger*` triads (bg/border/title-or-text/body) — always pair color
  with a word or icon (Constitution VII: never color alone).
- Map: `mapLand` (base), `mapDestination` (pin). Avatar fallback palette is 4 fixed colors with
  white initials text.
- `AppTypography`: Cairo family. `AppRadii`, `AppSpacing`, `AppSizes`: the only source of radius/
  spacing/size values — feature code never hardcodes a number here.

## Contrast
Text pairs are held to ≥4.5:1, non-text UI parts to ≥3:1 — both enforced by
`test/unit/contrast_test.dart`, which lists every real pairing in the app. Before adding a new
color pairing, add it to that test's list rather than eyeballing it. One documented exception:
`GooraProgressBar`'s fill-vs-track ratio is below 3:1 on purpose, because the same value is always
also shown as text (`valueLabel`) and read out via semantics — color is never the only signal
there, so the strict non-text bar doesn't apply. Don't "fix" that pairing without re-reading the
test's comment first.

## Arabic lexicon — one canonical word per concept
Egyptian colloquial, not formal MSA, for in-app copy (`notNextWeekConfirm`'s "مش جاي الأسبوع
الجاي" register, not "لن أحضر"). Established words — reuse them, don't invent synonyms:
- **مشوار** = the trip/commute (never رحلة for the same concept — رحلة is used only for
  "رحلة الذهاب/الرجوع" meaning the *leg*, a distinct concept from the whole commute).
- **السواق** = the driver (consistent everywhere; never سائق in user-facing copy).
- **الركاب / راكب** = passengers/rider-count. **English side must say "passenger(s)" for this
  same concept, not "rider(s)"** — `weekDriveLine` drifted to "rider" once (fixed 2026-10-06,
  see `goora-status`); check new strings against `heroDriver`/`tlPassengers` before adding more.
- **بديل** = backup/replacement (driver). **موثّق / مش موثّق** = verified/not verified.
- **كرسي** = seat (not مقعد). **إجازة** = taking a day off (not the seat/trip itself).
- Money lines always name who gets paid: "{amount} ج للسواق" (to the driver), never a bare number.

## Rules that apply to every screen (Constitution, binding)
- **RTL-correct, directional-only**: `EdgeInsetsDirectional` / `AlignmentDirectional` / start·end —
  never `left`/`right`. Every screen must read correctly in both ar (RTL) and en (LTR).
- **No hardcoded strings** — every user-facing string is an ARB key in both `app_ar.arb` and
  `app_en.arb` (parity checked; see `goora-stack`).
- **Privacy by design** — never show a home address (pickup points only); hide a rider's name/
  photo from drivers until accepted/boarded.
- **Designed states** — every empty/error/loading state is a designed state, not a bare
  "no data"/blank screen (same standard as `ag-ui-standard`).
- **Accessible by default** — ≥44px touch targets, semantic labels on icon-only buttons.

## Before shipping a user-facing change
1. New word for an existing concept? Check the lexicon above first — reuse, don't duplicate.
2. New color pairing? Add it to `contrast_test.dart`'s list, don't eyeball contrast.
3. New string? Key in both `app_ar.arb` and `app_en.arb`, Egyptian-colloquial register in Arabic.
4. Would a driver ever see this as implying profit, or a rider see pressure/bidding? That's a
   Constitution II violation — stop and flag it rather than shipping.

## Where detail lives
Full copy canon + colors/fonts/components → `GOORA_SPEC_KIT_BRIEF.md`. Drafted copy awaiting
founder review per feature → `specs/NNN-*/research.md` § R14 + addenda. Live state → [[goora-status]].
Architecture/gates → [[goora-stack]]. House-wide UI rules shared across all projects → `ag-ui-standard`.
