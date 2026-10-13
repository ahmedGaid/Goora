/// What a driver sees of a rider before they board (005 research R15,
/// FR-023). It never carries a name, initials, photo or member id, so no
/// driver-facing widget built from it can leak one.
final class AnonymousRider {
  const AnonymousRider({required this.isWoman, this.rating});

  final bool isWoman;

  /// 0–5 stars; null shows "New".
  final double? rating;

  Map<String, Object?> toJson() => {'isWoman': isWoman, 'rating': rating};

  static AnonymousRider fromJson(Map<String, Object?> j) =>
      AnonymousRider(isWoman: j['isWoman']! as bool, rating: (j['rating'] as num?)?.toDouble());

  @override
  bool operator ==(Object other) => other is AnonymousRider && other.isWoman == isWoman && other.rating == rating;

  @override
  int get hashCode => Object.hash(isWoman, rating);
}
