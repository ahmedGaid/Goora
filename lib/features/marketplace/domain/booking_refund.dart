/// The money a one-off booking gets back (005 research R7). Twinned in
/// supabase/functions/_shared/marketplace.ts (`refundAmount`).
abstract final class BookingRefund {
  /// What goes back to the wallet. [owed] = 003's cancel charge on the
  /// contribution (0 before the cut-off, half after; the full share for a
  /// no-show). The fee always comes back — Goora takes no fee on a trip that
  /// didn't happen — because it sits inside [paidTotal] and is never part of
  /// [owed]. Never negative, never above [paidTotal]; 0 for a cash booking
  /// (paidTotal 0). Full refunds (reclaim, driver cancel) pass `owed: 0`.
  static int amount({required int paidTotal, required int fee, required int owed}) {
    final back = paidTotal - owed;
    if (back < 0) return 0;
    return back > paidTotal ? paidTotal : back;
  }
}
