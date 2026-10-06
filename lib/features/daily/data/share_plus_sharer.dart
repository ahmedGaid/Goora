import 'package:share_plus/share_plus.dart';

import '../domain/trip_sharer.dart';

/// System share sheet (research R9).
final class SharePlusSharer implements TripSharer {
  const SharePlusSharer();

  @override
  Future<void> share(String text) => SharePlus.instance.share(ShareParams(text: text));
}
