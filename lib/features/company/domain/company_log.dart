import '../../../core/time/wall_time.dart';

/// Goora staff show as "Goora" to HR (FR-031).
enum LogActor { hr, employee, goora }

enum LogKind {
  approved,
  domainAdded,
  domainRemoved,
  employeeRemoved,
  employeeLeft,
  invoiceIssued,
  invoicePaid,
  suspended,
  resumed,
  contractEnded,
  hrContactChanged,
}

/// One company-side change (FR-031, data-model.md "Company log entry"). HR
/// sees their company's log.
final class LogEntry {
  const LogEntry({required this.companyId, required this.at, required this.actor, required this.kind, this.detail});

  final String companyId;
  final WallTime at;
  final LogActor actor;
  final LogKind kind;

  /// The roster name for employeeRemoved / employeeLeft, the domain for
  /// domainAdded / domainRemoved, the month (`yyyy-mm`) for invoiceIssued /
  /// invoicePaid; otherwise null. Never a reason for a self-leave.
  final String? detail;

  Map<String, Object?> toJson() =>
      {'companyId': companyId, 'at': at.toJson(), 'actor': actor.name, 'kind': kind.name, 'detail': detail};

  static LogEntry fromJson(Map<String, Object?> j) => LogEntry(
        companyId: j['companyId']! as String,
        at: WallTime.fromJson(j['at']! as String),
        actor: LogActor.values.byName(j['actor']! as String),
        kind: LogKind.values.byName(j['kind']! as String),
        detail: j['detail'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is LogEntry &&
      other.companyId == companyId &&
      other.at == at &&
      other.actor == actor &&
      other.kind == kind &&
      other.detail == detail;

  @override
  int get hashCode => Object.hash(companyId, at, actor, kind, detail);

  @override
  String toString() => 'LogEntry(${kind.name} by ${actor.name} at $at)';
}
