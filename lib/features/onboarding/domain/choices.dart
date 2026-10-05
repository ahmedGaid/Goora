enum Role { driver, rider }

enum Frequency { everyDay, once }

/// Private: used only for the women-only preference, never shown to others.
enum Gender { male, female }

T? enumByName<T extends Enum>(List<T> values, String? name) {
  if (name == null) return null;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}
