# Feature Specification: Foundation, Design System and Onboarding

**Feature Branch**: `feature/001-foundation-onboarding`

**Created**: 2026-10-05

**Status**: Draft

**Input**: User description: "Read GOORA_SPEC_KIT_BRIEF.md (sections 3, 6, 7). Build the Goora app
foundation and onboarding: 1. Design system: all tokens and every shared component from section
3.4, plus a hidden debug 'Design gallery' screen showing every component in AR and EN.
2. Localization: Arabic (default, RTL) and English (LTR); a globe-icon language pill in the top end
corner of onboarding screens and in Settings. Seed ARB files with section 7 strings.
3. Splash/Welcome: forest background, Goora logo + wordmark, Arabic tagline 'مشوارك.. سوا.' as the
big line in AR (English tagline secondary) and vice versa in EN, a short description, primary CTA
'Get started' (mint fill) and outline 'Log in'. Nothing else, so the welcome screen stays simple.
4. Phone sign-up: Egyptian mobile (+20) with OTP, then first name + last name + gender (used only
for women-only preference). 5. Role choice: two radio cards, 'I can drive' (car icon) / 'I need a
ride' (person icon), with the note 'You can switch anytime.' Users can switch roles later from
Settings. 6. Frequency choice, right after the role: 'Every day or just once?' (subline 'You can
always do the other one later.'). Two radio cards. 'Every day' (calendar icon) carries a 'Best
value' chip and is selected by default. 'Just one trip' (route icon). Sublines change by role
(rider/driver × every day/once). Routing: every day → commute setup (feature 002). Rider + once →
Empty seats today (feature 005-A). Driver + once → Offer a trip (feature 005-C). Until feature 005
exists, the once paths show a placeholder. 7. Onboarding progress dots across role → frequency →
commute setup. Acceptance: every screen passes the RTL/LTR widget tests; no hard-coded strings or
colors in feature code; touch targets at least 44 px."

**Sources of truth**: `GOORA_SPEC_KIT_BRIEF.md` (sections 3, 6, 7) and the approved prototype
(`Goora Prototype.html` / `.pdf`). Where the prototype supplies copy the brief does not list
(welcome description, role-card sublines, "Continue", "Back"), the prototype copy is used verbatim.

## Clarifications

### Session 2026-10-05

- Q: Where does phone sign-up go (brief lists it after "Get started"; prototype skips it)? →
  A: Right after "Get started": welcome → phone → code → name/gender → role → frequency → setup.
- Q: Who writes the phone, code and name/gender copy (absent from brief and prototype)? →
  A: Claude drafts it in the brief's tone; the founder reviews every string in the feature summary.
- Q: Progress dots: finished steps green (prototype) or grey (brief text)? → A: Finished steps stay
  green; the current step is the wide bar; future steps are grey.
- Q: §3.4 values missing from the token tables (radius 18 / 14, padding 18, font 13.5 / 13 / 14)? →
  A: Add them as named tokens.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - First look: welcome screen in my language (Priority: P1)

A new person opens Goora for the first time. They see a calm, branded welcome screen in Egyptian
Arabic (right-to-left) with the Goora logo, the tagline and a short description, and two actions:
"Get started" and "Log in". If they prefer English, one tap on the language pill switches the whole
app to English (left-to-right), and the app remembers that choice next time.

**Why this priority**: It proves the app looks like Goora and works in both languages, which is the
stated goal of this feature. Every later screen depends on the design system and the language
switch built here.

**Independent Test**: Install fresh, open the app, check the welcome screen in Arabic, tap the
language pill, check the same screen in English, close and reopen the app, confirm English is kept.

**Acceptance Scenarios**:

1. **Given** a first launch, **When** the app opens, **Then** the welcome screen shows in Arabic,
   right-to-left: forest background, Goora logo and wordmark, "مشوارك.. سوا." as the big line,
   "Go together. Every day." as the smaller secondary line, the short description, a "يلا نبدأ"
   button (mint fill) and a "تسجيل الدخول" outline button, and nothing else besides the language
   pill.
2. **Given** the welcome screen in Arabic, **When** the person taps the language pill (labelled
   "English" with a globe icon), **Then** every visible string switches to English, the layout
   flips to left-to-right, the big line becomes "Go together. Every day." and the secondary line
   becomes "مشوارك.. سوا.".
3. **Given** the person chose English, **When** they close and reopen the app, **Then** the app
   opens in English.
4. **Given** either language, **When** the welcome screen renders, **Then** the "Goora" wordmark
   uses the English brand font at its fixed weight and letter spacing in both languages, and all
   numbers use Western digits.

---

### User Story 2 - Sign up with my Egyptian phone number (Priority: P1)

After "Get started", the person enters their Egyptian mobile number (+20), receives a one-time
code, enters it, then gives their first name, last name and gender. Gender is used only for the
women-only preference and is never shown to other users in this feature.

**Why this priority**: The constitution requires phone verification for every user; without it no
user exists to onboard.

**Independent Test**: From the welcome screen, complete phone entry, code entry and the name/gender
step using the development test code, and arrive at the role screen with a signed-in account.

**Acceptance Scenarios**:

1. **Given** the phone screen, **When** the person enters a valid Egyptian mobile number, **Then**
   the continue action becomes available and sends a one-time code.
2. **Given** the phone screen, **When** the number is not a valid Egyptian mobile number, **Then**
   the continue action stays unavailable and a clear, blame-free hint explains the expected format.
3. **Given** the code screen, **When** the person enters the correct code, **Then** they move to the
   name and gender step.
4. **Given** the code screen, **When** the code is wrong, **Then** an inline error shows and the
   person can retry; **When** the resend wait has passed, **Then** they can request a new code.
5. **Given** the name and gender step, **When** first name, last name and gender are all provided,
   **Then** the person moves to the role screen; otherwise continue stays unavailable.
6. **Given** the welcome screen, **When** a returning person taps "Log in" and verifies their phone
   with a code, **Then** they skip the name/gender step and land on the post-login placeholder
   (the main app arrives in feature 003).

---

### User Story 3 - Tell Goora how I travel and how often (Priority: P1)

The person picks a role ("I can drive" or "I need a ride"), then picks a frequency ("Every day",
preselected with a "Best value" chip, or "Just one trip"). The frequency card sublines match the
chosen role. Progress dots show where they are across role → frequency → commute setup. Their
choice routes them onward: every day goes to commute setup (feature 002, a placeholder for now);
just one trip goes to the rider or driver one-off flow (feature 005, a placeholder for now).

**Why this priority**: It completes onboarding and sets the two choices every later feature reads.

**Independent Test**: As a rider and as a driver, pick each frequency and confirm the sublines, the
default selection, the progress dots and the destination placeholder for all four combinations.

**Acceptance Scenarios**:

1. **Given** the role screen, **When** it opens, **Then** it shows the title "How do you travel?",
   the note "You can switch anytime.", two radio cards ("I can drive" with a car icon and "I need a
   ride" with a person icon, each with its subline), the progress dots with step 1 active, a back
   action and a "Continue" button.
2. **Given** the role screen with no role picked, **When** the person looks at "Continue", **Then**
   it is unavailable until a role is picked.
3. **Given** a role is picked, **When** the person continues, **Then** the frequency screen shows
   "Every day or just once?", the subline "You can always do the other one later.", the "Every day"
   card (calendar icon, "Best value" chip) selected by default, and the "Just one trip" card (route
   icon), with step 2 of the progress dots active.
4. **Given** the frequency screen, **Then** the card sublines are exactly:
   - Rider, every day: "A fixed group for your daily commute. First month free."
   - Rider, once: "Book an empty seat or post your trip. No subscription."
   - Driver, every day: "Share your daily commute with a fixed group. Always free."
   - Driver, once: "Offer your empty seats on a trip you're already making."
   (and their Arabic equivalents from the prototype in Arabic).
5. **Given** "Every day" is chosen, **When** the person continues, **Then** they reach the commute
   setup placeholder with step 3 of the progress dots active.
6. **Given** rider + "Just one trip", **When** the person continues, **Then** they reach the
   "Empty seats today" placeholder; **Given** driver + "Just one trip", **Then** they reach the
   "Offer a trip" placeholder. Back from either placeholder returns to the frequency screen.
7. **Given** the frequency screen, **When** the person taps back, **Then** they return to the role
   screen with their role still selected.

---

### User Story 4 - Change language or role later from Settings (Priority: P2)

From a Settings screen the person can switch language with the same globe pill and switch between
driver and rider roles.

**Why this priority**: The brief promises "You can switch anytime"; this feature must keep that
promise for the two choices it creates.

**Independent Test**: Open Settings, switch language and role, confirm both are applied and kept
after restart.

**Acceptance Scenarios**:

1. **Given** Settings, **When** the person taps the language pill, **Then** the app switches
   language and direction immediately and remembers it.
2. **Given** Settings, **When** the person switches role, **Then** the stored role changes and is
   kept after restart.

---

### User Story 5 - Design gallery for the team (Priority: P2)

A hidden debug-only "Design gallery" screen shows every shared component and token sample in
Arabic and English so the team can check the design system at a glance.

**Why this priority**: The design system must be built and visible before any other screen, and the
gallery is how it is reviewed; it is not user-facing.

**Independent Test**: In a debug build, open the gallery and check every component from brief
section 3.4 appears in both languages; in a release build, confirm the gallery cannot be reached.

**Acceptance Scenarios**:

1. **Given** a debug build, **When** a team member opens the Design gallery, **Then** it shows every
   shared component in its states (e.g. selected/unselected, enabled/disabled, warning/info) plus
   the color, type, radius and spacing tokens.
2. **Given** the gallery, **When** the language is switched, **Then** every component re-renders in
   that language and direction.
3. **Given** a release build, **Then** there is no way to reach the gallery.

---

### Edge Cases

- The person switches language mid-onboarding: the current screen and its selections stay, only
  language and direction change.
- The device has no network during sign-up: a calm, blame-free message explains the code could not
  be sent and offers retry; nothing is lost.
- The person enters the number with a leading 0 (010…), with +20, or with spaces: all valid forms of
  the same Egyptian mobile number are accepted and normalised to one format.
- The person leaves the app mid-onboarding and returns: they resume at the last completed step
  rather than starting over (account, role and frequency kept).
- Very long first or last names do not break the layout in either direction.
- Large system text size: screens stay usable and touch targets stay at least 44 px.
- Directional icons (back, forward arrow on "Get started") mirror in RTL; non-directional icons
  (globe, car, calendar) do not.

## Requirements *(mandatory)*

### Functional Requirements

**Design system**

- **FR-001**: The app MUST define the exact color, typography, radius and spacing tokens from brief
  section 3 as the only source of these values; feature screens MUST NOT contain any other colors,
  font sizes or radii.
- **FR-002**: The app MUST provide every shared component listed in brief section 3.4
  (primary, ghost and dashed buttons; card; hero card; pill; chip; radio card; avatar; banner;
  stepper; progress dots; bottom navigation; timeline row; logo) with the sizes, colors and states
  stated there. Values §3.4 uses that are not in the §3 token tables (banner radius 18, dashed
  button radius 14, list-card padding 18, font sizes 13.5, 13 and 14) MUST be added as named
  tokens, so components match §3.4 exactly and feature code still uses tokens only.
- **FR-003**: Arabic text MUST use Cairo and English text MUST use Plus Jakarta Sans, both bundled
  with the app and working offline; the "Goora" wordmark MUST always use Plus Jakarta Sans 800 with
  letter spacing −2.
- **FR-004**: Numbers MUST use Western digits in both languages.
- **FR-005**: The app MUST be light mode only.
- **FR-006**: Icons MUST be outline stroke icons (2 px stroke, round caps); no emoji and no filled
  icons; directional icons MUST mirror in RTL.
- **FR-007**: A debug-only Design gallery MUST show every shared component and token in both
  languages and MUST be unreachable in release builds.

**Localization**

- **FR-008**: Arabic MUST be the default language with right-to-left layout; English MUST be
  available with left-to-right layout.
- **FR-009**: All user-facing text MUST come from the localization files, seeded with every brief
  section 7 string plus the prototype copy used by this feature.
- **FR-010**: A globe-icon language pill MUST appear in the top end corner of every onboarding
  screen (including the welcome screen) and in Settings; tapping it MUST switch language and
  direction immediately.
- **FR-011**: The chosen language MUST persist across app restarts.

**Welcome**

- **FR-012**: The welcome screen MUST show only: forest background, logo and wordmark, the two
  taglines (current language's tagline large, the other secondary), the short description, the
  "Get started" primary button (mint fill, forward arrow) and the "Log in" outline button, plus the
  language pill.

**Sign-up and log-in**

- **FR-013**: Sign-up MUST verify an Egyptian mobile number (+20) with a one-time code.
- **FR-014**: After code verification, a new user MUST provide first name, last name and gender;
  all three are required.
- **FR-015**: Gender MUST be stored only for the women-only preference and MUST NOT be shown to
  other users.
- **FR-016**: "Log in" MUST verify an existing user's phone with a one-time code and MUST skip the
  profile step.
- **FR-017**: Until real backend credentials are provided, sign-up and log-in MUST work end-to-end
  against a fake account service with a documented development code, with no real keys in the
  app.

**Role and frequency**

- **FR-018**: The role screen MUST offer exactly two choices, "I can drive" and "I need a ride",
  as radio cards with the note "You can switch anytime."
- **FR-019**: The frequency screen MUST follow the role screen, offer "Every day" (default,
  "Best value" chip) and "Just one trip", and show the role-specific sublines listed in User
  Story 3.
- **FR-020**: Routing MUST be: every day → commute setup; rider + once → Empty seats today;
  driver + once → Offer a trip. Each destination is a placeholder screen in this feature.
- **FR-021**: Progress dots MUST show three steps (role → frequency → commute setup): the current
  step is the wide green bar, completed steps are short green bars, future steps are short grey
  bars.
- **FR-022**: The chosen role and frequency MUST be saved to the person's profile and kept across
  restarts.
- **FR-023**: Settings MUST let the person switch role (driver ↔ rider) and language.

**Quality**

- **FR-024**: Every screen in this feature MUST render correctly in Arabic (RTL) and English (LTR),
  proven by automated widget tests in both languages.
- **FR-025**: Every touch target MUST be at least 44 px; every icon-only button MUST have a spoken
  label; text contrast MUST be at least 4.5:1; selection MUST NOT be shown by color alone (the
  radio mark and border change too).

### Key Entities

- **User account**: a verified Egyptian mobile number; created at first code verification.
- **Profile**: first name, last name, gender (private, women-only preference only), role
  (driver / rider), commute frequency (every day / just one trip), onboarding progress.
- **App preferences**: chosen language (Arabic / English), stored on the device.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new person can go from first launch to the commute setup placeholder in under 2
  minutes using the development code.
- **SC-002**: 100% of screens in this feature have passing automated rendering tests in both Arabic
  and English.
- **SC-003**: Zero user-facing strings, colors, font sizes or radii appear in feature code outside
  the shared theme and localization files (verified by an automated scan).
- **SC-004**: Static analysis reports zero issues and the full automated test suite passes.
- **SC-005**: Switching language takes effect on the current screen in one tap, with no restart,
  and is kept after relaunch in 100% of tries.
- **SC-006**: All four role × frequency combinations reach their correct destination in 100% of
  tries.
- **SC-007**: The app runs fully without network credentials (fake services) so any team member can
  try onboarding on a fresh install.

## Assumptions

- Onboarding order: welcome → phone → code → name/gender → role → frequency → destination
  (see Clarifications).
- Copy for the phone, code and name/gender screens is drafted in the brief's tone and listed for
  founder review in the feature summary (see Clarifications).
- "Log in" with a number that has no account continues as sign-up (name/gender step next).
- Gender choices are "Male" and "Female" (the brief needs gender only to support women-only
  matching).
- The one-time code is 6 digits; a new code can be requested after 60 seconds.
- Accepted number formats: 01XXXXXXXXX, +201XXXXXXXXX, 00201XXXXXXXXX, with optional spaces;
  Egyptian mobile prefixes 010, 011, 012, 015.
- ID verification (national ID, license, vehicle) is required by the constitution but is collected
  in later features (Trust tab, feature 003); this feature only verifies the phone.
- The post-login screen for returning users, commute setup, Empty seats today and Offer a trip are
  simple placeholders until features 002, 003 and 005 exist.
- Settings in this feature contains only language and role switching; it is reachable from the
  post-login and placeholder screens.
- The Design gallery is opened by a hidden gesture in debug builds only (e.g. long-press on the
  welcome logo).
- The bottom navigation and timeline row components are built and shown in the gallery now, but
  are first used on real screens in feature 003.
