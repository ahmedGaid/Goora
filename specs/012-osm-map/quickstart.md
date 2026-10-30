# Quickstart: Pickup-point map (012)

## Gates

```
flutter analyze
flutter test --concurrency=1
node --test "supabase/functions/_shared/*.test.ts"
```

## 1. Default (no tiles) — sketch

1. `flutter run` (no `--dart-define`). Sign in with any Egyptian mobile, code `123456`.
2. Set up a commute → **match result**: under the group summary, a "نقط التجمع" card shows a drawn sketch with pin 1 (pickup) and a flag (arrival), the names + times below and "رسم تقريبي، مش بالمقاس".
3. Tap the card → a bigger sheet with the same points; close it.
4. Join → **Today** (rider): the meeting-point card sits after the trip timeline. Switch to a driver account → the card lists every stop in driving order.
5. Switch language to English: same cards, left-to-right, first pin on the left.

## 2. With a tile provider (founder supplies the URL/key — never commit it)

```
flutter run --dart-define=MAP_TILE_URL_TEMPLATE="https://tiles.example.com/{z}/{x}/{y}.png?key={key}" --dart-define=MAP_TILE_API_KEY=YOUR_KEY --dart-define=MAP_TILE_ATTRIBUTION="© Example Tiles"
```

Expected: the same cards show real map tiles with the pins on them and a "© OpenStreetMap contributors · © Example Tiles" chip at the bottom end. The big sheet pans and zooms. Turn the network off: the brand map colour stays behind the pins; the legend is still readable.
