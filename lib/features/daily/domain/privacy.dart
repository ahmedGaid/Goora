/// Who can ride with me (FR-024 – FR-026, research R7). Default: verified users.
enum PrivacyPreference { verifiedUsers, sameCompany, sameCompound, womenOnly }

/// The 002 matching constraint each preference turns on (FR-024).
extension PrivacyFlags on PrivacyPreference {
  bool get wantsWomenOnly => this == PrivacyPreference.womenOnly;
  bool get wantsSameCompany => this == PrivacyPreference.sameCompany;
  bool get wantsSameCompound => this == PrivacyPreference.sameCompound;
}

/// What privacy rules may know about a person. [company] is set only when the
/// work email is verified; [compound] only when the person added one.
final class PersonFacts {
  const PersonFacts({required this.isWoman, this.company, this.compound});

  final bool isWoman;
  final String? company;
  final String? compound;
}

/// Pure privacy checks shared by matching (as `Seeker` flags) and backup.
abstract final class PrivacyRules {
  /// Whether [owner], with preference [p], accepts riding with [other].
  static bool accepts(PrivacyPreference p, PersonFacts owner, PersonFacts other) => switch (p) {
        PrivacyPreference.verifiedUsers => true,
        PrivacyPreference.womenOnly => other.isWoman,
        PrivacyPreference.sameCompany => owner.company != null && other.company == owner.company,
        PrivacyPreference.sameCompound => owner.compound != null && other.compound == owner.compound,
      };

  /// Whether [me] may choose [p].
  static bool available(PrivacyPreference p, PersonFacts me) => switch (p) {
        PrivacyPreference.verifiedUsers => true,
        PrivacyPreference.womenOnly => me.isWoman,
        PrivacyPreference.sameCompany => me.company != null,
        PrivacyPreference.sameCompound => me.compound != null,
      };

  /// "Women only" is not offered to men at all; other unavailable options
  /// stay visible with a hint.
  static bool shown(PrivacyPreference p, PersonFacts me) => p != PrivacyPreference.womenOnly || me.isWoman;
}
