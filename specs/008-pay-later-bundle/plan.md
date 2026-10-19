# Implementation Plan: Pay Later and Trip Bundle

**Branch**: `008-pay-later-bundle` (stacked on 007) | **Date**: 2026-10-19 | **Spec**: [spec.md](spec.md)

## Summary

Goora's fee already lands on the ledger (007). 008 adds the collection side: one-shot settlement,
a due/overdue rule (150 / month-end ≥ 30 / 3-day grace) that blocks new bookings when overdue, and
a never-expiring 20-trip bundle for 75 that covers fees. Pure rules `FeeBalancePolicy` and
`TripBundle` get a TS twin + vectors; the wallet walk consumes bundle trips; the gate gains
`feeOverdue`; Wallet gets a fee card (owed, due, Pay), a settle sheet (wallet / InstaPay / Fawry /
card), a bundle card and the new nudge copy.

## Technical Context

Dart 3.12 / Flutter 3.44, Riverpod; TS twin on Node 24; storage shared_preferences (activity rows
only); no new dependencies; fakes only.

## Constitution Check

I commute-first ✔ (no card to ride) · II cost-sharing ✔ (fee only, cap untouched) · III ARB/RTL ✔ ·
IV privacy ✔ · V safety ✔ · VI tokens ✔ · VII a11y ✔ (44 px, words not colour) · VIII twins ✔.

## Structure

`lib/features/wallet/domain/fee_balance.dart` (NEW, twinned) · `wallet.dart`, `activity_entry.dart`,
`wallet_repository.dart` (CHG) · `fake_wallet_repository.dart` (CHG: walk with bundle, settle,
buyBundle, due) · `booking_gate.dart` + marketplace/commute callers (CHG) ·
`presentation/wallet/fee_card.dart`, `settle_sheet.dart`, `bundle_card.dart` (NEW) ·
`supabase/functions/_shared/fee_balance.ts` + test (NEW) · vectors (NEW) · ARB.
