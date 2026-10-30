/// What a backend call can fail with (011 research D7). Repositories turn
/// these into their own interface's types where it names one; anything left
/// is rethrown, as "storage failures throw" in the 004/005 contracts.
sealed class BackendFailure implements Exception {
  const BackendFailure();
}

/// No network, a timeout, or the server unreachable.
final class BackendOffline extends BackendFailure {
  const BackendOffline();

  @override
  String toString() => 'BackendOffline';
}

/// Signed out, a wrong password, or a row-level rule said no.
final class BackendUnauthorized extends BackendFailure {
  const BackendUnauthorized([this.detail]);

  final String? detail;

  @override
  String toString() => 'BackendUnauthorized($detail)';
}

/// A database constraint: `23505` unique, `23514` check (e.g. contactsFull).
final class BackendConflict extends BackendFailure {
  const BackendConflict(this.code, [this.detail]);

  final String code;
  final String? detail;

  @override
  String toString() => 'BackendConflict($code, $detail)';
}

/// A server function refused: `refused:<reason>[:<detail>]` from SQL, or an
/// Edge Function's HTTP 409 `{ refused }`.
final class BackendRefused extends BackendFailure {
  const BackendRefused(this.reason, [this.detail]);

  final String reason;
  final String? detail;

  /// Parses `refused:<reason>[:<detail>]`; null for any other message.
  static BackendRefused? parse(String message) {
    const prefix = 'refused:';
    if (!message.startsWith(prefix)) return null;
    final rest = message.substring(prefix.length);
    final colon = rest.indexOf(':');
    return colon < 0 ? BackendRefused(rest) : BackendRefused(rest.substring(0, colon), rest.substring(colon + 1));
  }

  @override
  String toString() => 'BackendRefused($reason, $detail)';
}

final class BackendError extends BackendFailure {
  const BackendError(this.message);

  final String message;

  @override
  String toString() => 'BackendError($message)';
}
