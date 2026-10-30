# Contract: PickupMapRenderer

```dart
abstract interface class PickupMapRenderer {
  /// True when this renderer fetches map tiles (and so must show attribution).
  bool get usesNetwork;

  /// Draws [scene]'s pins filling the given box. Must not add its own legend
  /// (GooraPickupMap draws the legend), must not show any point not in
  /// [scene], and must not accept user-picked locations.
  Widget render(BuildContext context, PickupMapScene scene);
}

final pickupMapRendererProvider = Provider<PickupMapRenderer>(...);
```

## Rules every implementation keeps

1. Draw exactly `scene.pins`, in order; pickup pins show their number, the arrival pin a flag icon.
2. `usesNetwork == true` ⇒ the attribution chip (`mapAttribution` + `MapConfig.extraAttribution`) is visible inside the rendered box.
3. `usesNetwork == false` ⇒ zero network calls (no `NetworkImage`, no `HttpClient`).
4. Background behind tiles = `AppColors.mapLand` (failed tiles never look grey).
5. `scene.expanded == false` ⇒ no gestures (the card owns the tap).
6. Directional: in RTL the first pin is on the right (sketch); tiles keep real geography.

## Implementations

| Class | usesNetwork | Notes |
|---|---|---|
| `OfflinePickupRenderer` | false | ordered sketch; default when `MapConfig.hasTiles == false` |
| `FlutterMapPickupRenderer` | true | `TileLayer` from `MapConfig`; `tileProvider` injectable for tests |
