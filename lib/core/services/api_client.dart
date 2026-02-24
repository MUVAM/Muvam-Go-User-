import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:muvam/core/utils/app_logger.dart';
import 'auth_service.dart';

/// A centralized HTTP client that transparently handles token refresh.
///
/// Behaviour:
/// 1. Before every request it obtains a (possibly pre-refreshed) token via
///    [AuthService.getToken].
/// 2. If the server returns **401 Unauthorized** the client tries once more:
///    it calls [AuthService.refreshToken], updates the stored token, then
///    retries the original request with the new token.
/// 3. If the retry also fails with 401, or if there is no refresh token, the
///    exception is propagated to the caller.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final _authService = AuthService();

  // ─────────────────────────────────── helpers ────────────────────────────
  Future<String?> _freshToken() => _authService.getToken();

  Map<String, String> _buildHeaders(
    String? token, {
    Map<String, String>? extra,
  }) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?extra,
    };
  }

  /// Attempts to refresh the token and returns the new access token, or null
  /// if the refresh fails.
  Future<String?> _tryRefresh() async {
    AppLogger.log('🔄 401 received – attempting token refresh…', tag: 'API');
    final refreshed = await _authService.refreshToken();
    if (refreshed) {
      final prefs = await _authService
          .getToken(); // reads the newly stored token
      AppLogger.log('✅ Token refreshed, retrying request.', tag: 'API');
      return prefs;
    }
    AppLogger.log('❌ Token refresh failed.', tag: 'API');
    return null;
  }

  bool _isUnauthorized(http.Response response) => response.statusCode == 401;

  // ─────────────────────────────────── GET ────────────────────────────────
  Future<http.Response> get(
    Uri uri, {
    Map<String, String>? extraHeaders,
  }) async {
    var token = await _freshToken();
    var response = await http.get(
      uri,
      headers: _buildHeaders(token, extra: extraHeaders),
    );

    if (_isUnauthorized(response)) {
      token = await _tryRefresh();
      if (token != null) {
        response = await http.get(
          uri,
          headers: _buildHeaders(token, extra: extraHeaders),
        );
      }
    }
    return response;
  }

  // ─────────────────────────────────── POST ───────────────────────────────
  Future<http.Response> post(
    Uri uri, {
    Object? body,
    Map<String, String>? extraHeaders,
  }) async {
    var token = await _freshToken();
    var response = await http.post(
      uri,
      headers: _buildHeaders(token, extra: extraHeaders),
      body: body,
    );

    if (_isUnauthorized(response)) {
      token = await _tryRefresh();
      if (token != null) {
        response = await http.post(
          uri,
          headers: _buildHeaders(token, extra: extraHeaders),
          body: body,
        );
      }
    }
    return response;
  }

  // ─────────────────────────────────── PUT ────────────────────────────────
  Future<http.Response> put(
    Uri uri, {
    Object? body,
    Map<String, String>? extraHeaders,
  }) async {
    var token = await _freshToken();
    var response = await http.put(
      uri,
      headers: _buildHeaders(token, extra: extraHeaders),
      body: body,
    );

    if (_isUnauthorized(response)) {
      token = await _tryRefresh();
      if (token != null) {
        response = await http.put(
          uri,
          headers: _buildHeaders(token, extra: extraHeaders),
          body: body,
        );
      }
    }
    return response;
  }

  // ─────────────────────────────────── PATCH ──────────────────────────────
  Future<http.Response> patch(
    Uri uri, {
    Object? body,
    Map<String, String>? extraHeaders,
  }) async {
    var token = await _freshToken();
    var response = await http.patch(
      uri,
      headers: _buildHeaders(token, extra: extraHeaders),
      body: body,
    );

    if (_isUnauthorized(response)) {
      token = await _tryRefresh();
      if (token != null) {
        response = await http.patch(
          uri,
          headers: _buildHeaders(token, extra: extraHeaders),
          body: body,
        );
      }
    }
    return response;
  }

  // ─────────────────────────────────── DELETE ─────────────────────────────
  Future<http.Response> delete(
    Uri uri, {
    Object? body,
    Map<String, String>? extraHeaders,
  }) async {
    var token = await _freshToken();
    var response = await http.delete(
      uri,
      headers: _buildHeaders(token, extra: extraHeaders),
      body: body,
    );

    if (_isUnauthorized(response)) {
      token = await _tryRefresh();
      if (token != null) {
        response = await http.delete(
          uri,
          headers: _buildHeaders(token, extra: extraHeaders),
          body: body,
        );
      }
    }
    return response;
  }

  // ──────────────────────── Multipart (file upload) ───────────────────────
  /// Sends a [http.MultipartRequest] with automatic 401-retry.
  ///
  /// [buildRequest] is called each time a request must be built (initial +
  /// retry), receiving the current access token so the caller can attach it.
  Future<http.Response> sendMultipart(
    Future<http.MultipartRequest> Function(String? token) buildRequest,
  ) async {
    var token = await _freshToken();
    var req = await buildRequest(token);
    var streamed = await req.send();
    var response = await http.Response.fromStream(streamed);

    if (_isUnauthorized(response)) {
      token = await _tryRefresh();
      if (token != null) {
        req = await buildRequest(token);
        streamed = await req.send();
        response = await http.Response.fromStream(streamed);
      }
    }
    return response;
  }
}
