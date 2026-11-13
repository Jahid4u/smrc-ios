import 'package:dio/dio.dart';
import 'api/smrc_repository.dart';

/// Classifies any exception thrown by an SmrcRepository call into a
/// consistent, human-readable message plus an optional short technical
/// [detail] safe to show on screen.
///
/// This exists because, before it did, nearly every screen's error handling
/// looked like:
///
///   } catch (_) {
///     setState(() => _error = 'Could not reach the Circle. Check your connection.');
///   }
///
/// That `catch (_)` discards the actual exception — so a genuine backend
/// bug (HTTP 500), a certificate problem, a timeout, and "no internet at
/// all" were all indistinguishable from the person's point of view, and
/// from ours too once the app was already built and out of a debug
/// console's reach. [describeError] is the one place that tells them apart;
/// every screen should use this instead of writing its own generic catch.
class ErrorInfo {
  /// The main, friendly message — safe to show as-is.
  final String message;

  /// A short technical detail (e.g. "HTTP 500", "connection timeout") to
  /// append in parentheses. Null when [message] already says everything
  /// useful (e.g. the server's own validation message via ApiException).
  final String? detail;

  const ErrorInfo(this.message, [this.detail]);

  /// The message with the detail appended, ready to show directly —
  /// e.g. "Could not reach the server (connection timeout)."
  String get display => detail == null ? message : '$message ($detail)';
}

ErrorInfo describeError(Object error) {
  // The backend was reached and it gave us its own specific reason (a
  // validation failure, "not configured yet", etc.) — that message is
  // already the most accurate thing we can show, use it as-is.
  if (error is ApiException) {
    return ErrorInfo(error.message);
  }

  if (error is DioException) {
    if (error.type == DioExceptionType.badResponse) {
      // validateStatus in ApiClient only accepts codes under 500, so
      // reaching this branch means the server responded with 5xx. Some
      // backend error paths intentionally return a specific, readable
      // reason at 5xx (e.g. a Stripe API call the server correctly
      // rejected) rather than only ever using 5xx for a genuine crash —
      // read that message when present instead of always showing a
      // generic "server error" that looks identical to a real PHP fatal.
      final status = error.response?.statusCode;
      final body = error.response?.data;
      final serverMessage = body is Map ? body['message'] : null;
      if (serverMessage is String && serverMessage.isNotEmpty) {
        return ErrorInfo(serverMessage, status != null ? 'HTTP $status' : null);
      }
      return ErrorInfo('Server error. Please try again shortly.', status != null ? 'HTTP $status' : null);
    }
    final detail = switch (error.type) {
      DioExceptionType.connectionTimeout => 'connection timeout',
      DioExceptionType.sendTimeout => 'send timeout',
      DioExceptionType.receiveTimeout => 'receive timeout',
      DioExceptionType.connectionError => 'connection error: ${error.error ?? "host unreachable"}',
      DioExceptionType.badCertificate => 'certificate error',
      DioExceptionType.cancel => 'request cancelled',
      DioExceptionType.unknown => error.message ?? 'unknown error',
      // ignore: unreachable_switch_default
      _ => error.message ?? 'unknown network error',
    };
    return ErrorInfo('Could not reach the server.', detail);
  }

  // Anything else (a bug in our own code, a type error, etc.) — still show
  // *something* specific rather than a generic string, so a mistake here
  // is visible instead of silently looking identical to "no internet".
  return ErrorInfo('Something went wrong. Please try again.', error.toString());
}
