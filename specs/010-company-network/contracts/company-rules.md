# Contract: company rules (Dart ↔ TS twin)

Dart: `lib/features/company/domain/company_rules.dart` (pure, no Flutter).
TS: `supabase/functions/_shared/company.ts` + `company.test.ts`.
Vectors: `test/fixtures/company_vectors.json` (generated; both sides read the same file).
Minute scale: `SharePolicy.minuteOf` / `minuteOf` in `direct_pay.ts` (days since 2000-01-01 × 1440).

```dart
typedef Window = ({int from, int? to}); // half-open [from, to); to == null = open

abstract final class CompanyRules {
  static const graceDays = 7;        // Q10 default
  static const dueAfterDays = 15;    // Q10 default
  static const suppressBelow = 5;    // spec clarification

  /// Enrollment windows ∩ company active windows, merged, sorted.
  static List<Window> coverage(List<Window> enrolled, List<Window> companyActive);

  /// [minute] inside any window.
  static bool covered(List<Window> windows, int minute);

  /// For each day of [monthFromDay, monthToDay): distinct people enrolled at any moment of that
  /// day; returns the max over the month's days (spec Q2/FR-010: "on any day"). Each person's
  /// windows given as a list; one person counts once per day.
  static int peakEnrolled(Map<String, List<Window>> byPerson, int monthFromDay, int monthToDay);

  static int billedSeats(int peak, int minimumSeats);          // max
  static int invoiceTotal(int billedSeats, int pricePerSeat);  // product

  static int dueDay(int issueDay);              // issueDay + 15 (day scale)
  static int suspendFromDay(int dueDay);        // dueDay + graceDays + 1, at 00:00

  /// Active windows = [approvedAt, endedAt) minus every [suspendFrom, paidAt) of an invoice
  /// still unpaid at its suspendFrom.
  static List<Window> activeWindows({
    required int approvedAt,
    int? endedAt,
    required List<({int suspendFrom, int? paidAt})> overdue,
  });

  /// null = "fewer than 5".
  static int? suppress(int count);
}
```

```ts
export type Window = { from: number; to: number | null };
export function coverage(enrolled: Window[], companyActive: Window[]): Window[];
export function covered(windows: Window[], minute: number): boolean;
export function peakEnrolled(byPerson: Record<string, Window[]>, monthFromDay: number, monthToDay: number): number;
export function billedSeats(peak: number, minimumSeats: number): number;
export function invoiceTotal(billedSeats: number, pricePerSeat: number): number;
export function dueDay(issueDay: number): number;
export function suspendFromDay(dueDay: number): number;
export function activeWindows(a: { approvedAt: number; endedAt: number | null;
  overdue: { suspendFrom: number; paidAt: number | null }[] }): Window[];
export function suppress(count: number): number | null;
```

## Required vector cases (minimum)

- coverage: enrolled before approval; enrolled inside a suspension; leave and re-join; open windows.
- covered: exactly at `from` (true), exactly at `to` (false).
- peakEnrolled: 12 people all month → 12; one person leaves on the 20th and re-joins on the 25th →
  counts once; two people with non-overlapping halves of the month → 1; A leaves at 10:00 and B
  joins at 14:00 the same day → 2 (day-based); nobody → 0.
- billedSeats/invoiceTotal: (12, 20) → 20 → 1,980 at 99; (34, 20) → 34 → 3,366; (0, 20) → 20.
- dueDay/suspendFromDay: issued 1 Nov → due 16 Nov → suspended from 24 Nov 00:00.
- activeWindows: paid before suspension (no gap); paid during suspension (gap closes at paidAt);
  never paid (open gap); contract ended.
- suppress: 4 → null, 5 → 5, 0 → null.
