# Implementation Plan: Rider ID Check Before the First Trip

**Branch**: `009-rider-id-first-trip` (stacked on 008) | **Date**: 2026-10-19 | **Spec**: [spec.md](spec.md)

## Summary

The trust fake gains a rider ID status (`trust.riderId`: notVerified | pending | verified).
`TrustProfile` reports it as the `nationalId` item for riders; drivers stay verified. The booking
gate gains `needsId` after the debt/overdue checks; Book, Post, demo accept and Join route to a new
ID-check screen (`/id-check?next=`) with fake front/back capture. Legacy riders (payment already set
up) read as verified. No server twin: the gate is app-side (005 R8), the server writes its own.

## Technical Context

Dart 3.12 / Flutter 3.44, Riverpod, go_router; shared_preferences; no new dependencies.

## Constitution Check

V Trust & safety ✔ (no one rides unverified; ID still required, just later) · III ARB/RTL ✔ ·
VII a11y ✔ · VIII testable ✔ (gate unit tests, screen widget tests ar/en). No violations.

## Research (inline)

- **R1 — status store**: `trust.riderId` in the trust fake; absent = verified if `wallet.since.me`
  exists (legacy), else notVerified. Rationale: FR-006 without a migration.
- **R2 — fake capture**: two tappable cards ("صوّر الوش" / "صوّر الضهر") mark captured; Submit sets
  verified. A real provider would set `pending` first; the gate already treats pending as held.
- **R3 — gate**: `BookingCheck.needsId`; results `BookNeedsId` / `PostNeedsId`; accept withdraws.

## Structure

`lib/features/daily/domain/trust.dart`, `trust_repository.dart`, `data/fake_trust_repository.dart`
(CHG) · `lib/features/trust/presentation/id_check_screen.dart` (NEW) · `booking_gate.dart`,
marketplace repo + screens, match result (CHG) · router + routes (CHG) · ARB · tests.
