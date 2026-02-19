import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Result type so providers can pattern-match on the outcome.
sealed class GuardedResult<T> {
  const GuardedResult();
}

class GuardedSuccess<T> extends GuardedResult<T> {
  final T data;
  GuardedSuccess(this.data);
}

class GuardedOfflineError<T> extends GuardedResult<T> {
  const GuardedOfflineError();
}

class GuardedApiError<T> extends GuardedResult<T> {
  final String message;
  final int? statusCode;
  GuardedApiError(this.message, {this.statusCode});
}

class GuardedUnknownError<T> extends GuardedResult<T> {
  final Object error;
  GuardedUnknownError(this.error);
}

/// Add this mixin to any ChangeNotifier:
///
///   class DriverProvider extends ChangeNotifier with NetworkGuardMixin { … }
///
mixin NetworkGuardMixin {
  final _checker = InternetConnection.createInstance(
    checkInterval: const Duration(seconds: 4),
  );

  Future<bool> _hasInternet() => _checker.hasInternetAccess;

  /// Wraps [call] with a connectivity guard and optional retry.
  ///
  /// [call] should return a `Map<String, dynamic>` with
  /// `{'success': bool, 'data': ..., 'message': ...}` — matching
  /// your existing ApiService convention.
  Future<GuardedResult<T>> guardedCall<T>({
    required Future<Map<String, dynamic>> Function() call,

    /// How to extract T from the raw response map.
    required T Function(Map<String, dynamic> response) parse,

    /// Max attempts (1 = no retry).
    int maxAttempts = 2,

    /// Base delay between retries; doubles on each attempt.
    Duration retryDelay = const Duration(seconds: 2),

    /// Optional label for logging.
    String? tag,
  }) async {
    int attempt = 0;

    while (attempt < maxAttempts) {
      attempt++;

      // ── Connectivity pre-flight ──────────────────────────────────────────
      final online = await _hasInternet();
      if (!online) {
        if (attempt < maxAttempts) {
          // Wait and retry
          await Future.delayed(
            Duration(seconds: retryDelay.inSeconds * attempt),
          );
          continue;
        }
        return const GuardedOfflineError();
      }

      // ── Network call ─────────────────────────────────────────────────────
      try {
        final raw = await call();

        if (raw['success'] == true) {
          return GuardedSuccess(parse(raw));
        }

        final message = (raw['message'] as String?) ?? 'Something went wrong';
        final statusCode = raw['statusCode'] as int?;

        // Decide whether to retry on server error
        final retryable =
            statusCode != null && statusCode >= 500 && statusCode < 600;

        if (retryable && attempt < maxAttempts) {
          await Future.delayed(
            Duration(seconds: retryDelay.inSeconds * attempt),
          );
          continue;
        }

        return GuardedApiError(message, statusCode: statusCode);
      } catch (e) {
        if (attempt < maxAttempts) {
          await Future.delayed(
            Duration(seconds: retryDelay.inSeconds * attempt),
          );
          continue;
        }
        return GuardedUnknownError(e);
      }
    }

    // Exhausted all attempts — still offline
    return const GuardedOfflineError();
  }
}
