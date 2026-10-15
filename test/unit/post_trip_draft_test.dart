import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/marketplace/domain/offered_trip.dart';
import 'package:goora/features/marketplace/presentation/post_trip/post_trip_controller.dart';

void main() {
  test('the draft survives the Routes link', () {
    final q = Uri.parse(Routes.postTripDraft(from: 'october', to: 'smartVillage', at: 17 * 60, repeat: 'daily')).queryParameters;
    final d = PostTripDraft.parse(from: q['from'], to: q['to'], at: q['at'], repeat: q['repeat'])!;
    expect(d.from, Area.october);
    expect(d.to, Area.smartVillage);
    expect(d.departure, const Clock.hm(17, 0));
    expect(d.repeat, Repeat.daily);
  });

  test('a bare or broken link starts fresh', () {
    expect(PostTripDraft.parse(), isNull);
    expect(PostTripDraft.parse(from: 'nowhere', to: 'october', at: '420', repeat: 'once'), isNull);
    expect(PostTripDraft.parse(from: 'october', to: 'sheikhZayed', at: '99999', repeat: 'once'), isNull);
    expect(PostTripDraft.parse(from: 'october', to: 'sheikhZayed', at: 'x', repeat: 'once'), isNull);
  });
}
