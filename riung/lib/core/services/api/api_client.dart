import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

typedef TokenProvider = Future<String?> Function(bool forceRefresh);

class ApiException implements Exception {
  const ApiException(
    this.status,
    this.code,
    this.message, {
    this.requestId,
    this.details,
  });
  final int status;
  final String code;
  final String message;
  final String? requestId;
  final Object? details;
  bool get retryable =>
      status == 0 ||
      status == 408 ||
      status == 429 ||
      status >= 500 ||
      code == 'request_in_progress';
  @override
  String toString() => 'ApiException($status, $code, requestId: $requestId)';
}

class ApiResponse {
  const ApiResponse(this.status, this.data, this.headers);
  final int status;
  final dynamic data;
  final Map<String, String> headers;
  Map<String, dynamic> get object =>
      data is Map ? Map<String, dynamic>.from(data as Map) : {};
}

/// Owns only transport. Credentials are obtained fresh for each request and
/// never stored in preferences, logged, or sent to a different host.
class ApiClient {
  ApiClient({
    required String baseUrl,
    this.token,
    this.appCheckToken,
    http.Client? client,
    this.appVersion = '1.0.0',
    this.platform = 'android',
    this.timeout = const Duration(seconds: 15),
    this.onError,
    this.retryDelay = const Duration(milliseconds: 500),
    this.accountId,
    bool allowPrivateHttp = false,
  }) : baseUri = Uri.parse(baseUrl),
       _client = client ?? http.Client() {
    final octets = baseUri.host.split('.').map(int.tryParse).toList();
    final privateIp =
        octets.length == 4 &&
        octets.every((n) => n != null && n >= 0 && n <= 255) &&
        (octets[0] == 10 ||
            (octets[0] == 172 && octets[1]! >= 16 && octets[1]! <= 31) ||
            (octets[0] == 192 && octets[1] == 168));
    if (baseUri.scheme != 'https' &&
        !(baseUri.scheme == 'http' &&
            (const {
                  'localhost',
                  '127.0.0.1',
                  '10.0.2.2',
                  '::1',
                }.contains(baseUri.host) ||
                (allowPrivateHttp && privateIp)))) {
      throw ArgumentError(
        'HTTPS required except for a local development server',
      );
    }
  }
  final Uri baseUri;
  final TokenProvider? token;
  final String? Function()? accountId;
  final Future<String?> Function(bool limitedUse, bool forceRefresh)?
  appCheckToken;
  final http.Client _client;
  final String appVersion;
  final String platform;
  final Duration timeout;
  final Duration retryDelay;
  final void Function(ApiException)? onError;

  Future<ApiResponse> request(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool authenticated = true,
    bool limitedUse = false,
    bool appCheck = true,
    String? idempotencyKey,
    Map<String, String> headers = const {},
    bool reportErrors = true,
    int maxRetries = 2,
  }) async {
    final mutation = method != 'GET' && method != 'HEAD';
    final excluded =
        (method == 'DELETE' && path == '/v1/me') ||
        path == '/v1/me/journal-pin-backup/verify' ||
        path == '/v1/waitlist';
    final key = mutation && !excluded
        ? idempotencyKey ?? const Uuid().v4()
        : null;
    final initialAccount = accountId?.call();
    for (var attempt = 0; ; attempt++) {
      try {
        return await _request(
          method,
          path,
          query: query,
          body: body,
          authenticated: authenticated,
          limitedUse: limitedUse,
          appCheck: appCheck,
          idempotencyKey: key,
          headers: headers,
          expectedAccount: initialAccount,
        );
      } on ApiException catch (e) {
        if (!e.retryable || attempt >= maxRetries) {
          if (reportErrors) onError?.call(e);
          rethrow;
        }
        final details = e.details;
        final retryAfter = details is Map
            ? details['retryAfterSeconds'] as num?
            : null;
        if (retryAfter != null && retryAfter > 5) {
          if (reportErrors) onError?.call(e);
          rethrow;
        }
        await Future<void>.delayed(
          retryAfter != null
              ? Duration(seconds: retryAfter.toInt().clamp(0, 5))
              : retryDelay * (1 << attempt),
        );
        if (accountId != null && accountId!() != initialAccount) {
          throw const ApiException(
            401,
            'account_changed',
            'Account changed during retry',
          );
        }
      }
    }
  }

  Future<ApiResponse> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool authenticated = true,
    bool limitedUse = false,
    bool appCheck = true,
    String? idempotencyKey,
    Map<String, String> headers = const {},
    String? expectedAccount,
  }) async {
    if (!path.startsWith('/') ||
        path.startsWith('//') ||
        path.contains('://')) {
      throw ArgumentError('Only relative API paths are accepted');
    }
    final uri = baseUri.replace(path: path, queryParameters: query);
    final key = idempotencyKey;
    for (var attempt = 0; attempt < 2; attempt++) {
      if (accountId != null && accountId!() != expectedAccount) {
        throw const ApiException(
          401,
          'account_changed',
          'Account changed during request',
        );
      }
      final requestHeaders = <String, String>{
        'Accept': 'application/json',
        'X-App-Version': appVersion,
        'X-Platform': platform,
        ...headers,
        if (body != null) 'Content-Type': 'application/json',
        'Idempotency-Key': ?key,
      };
      if (authenticated) {
        String? idToken;
        try {
          idToken = await token?.call(attempt > 0).timeout(timeout);
        } on TimeoutException {
          throw const ApiException(0, 'timeout', 'Authentication token timed out');
        }
        if (idToken == null || idToken.isEmpty) {
          throw const ApiException(
            401,
            'unauthenticated',
            'Authentication required',
          );
        }
        requestHeaders['Authorization'] = 'Bearer $idToken';
      }
      if (appCheck) {
        String? check;
        try {
          check = await appCheckToken?.call(limitedUse, attempt > 0).timeout(timeout);
        } on TimeoutException {
          throw const ApiException(0, 'timeout', 'App Check token timed out');
        }
        if (check != null && check.isNotEmpty) {
          requestHeaders['X-Firebase-AppCheck'] = check;
        }
      }
      try {
        final req = http.Request(method, uri)
          ..headers.addAll(requestHeaders)
          ..followRedirects = false;
        if (body != null) req.body = jsonEncode(body);
        final response = await (() async => http.Response.fromStream(
          await _client.send(req),
        ))().timeout(timeout);
        dynamic decoded;
        if (response.body.isNotEmpty && response.statusCode != 304) {
          try {
            decoded = jsonDecode(response.body);
          } on FormatException {
            throw ApiException(
              response.statusCode,
              'invalid_response',
              'Expected JSON response',
            );
          }
        }
        if ((response.statusCode < 200 || response.statusCode >= 300) &&
            response.statusCode != 304) {
          final error = decoded is Map && decoded['error'] is Map
              ? decoded['error'] as Map
              : const {};
          if (response.statusCode == 401 &&
              attempt == 0 &&
              error['code'] != 'recent_login_required') {
            continue;
          }
          throw ApiException(
            response.statusCode,
            error['code'] as String? ?? 'http_error',
            error['message'] as String? ?? 'Request failed',
            requestId:
                error['requestId'] as String? ??
                response.headers['x-request-id'],
            details: {
              if (error['details'] is Map)
                ...Map<String, dynamic>.from(error['details'] as Map),
              if (response.headers['retry-after'] != null)
                'retryAfterSeconds': int.tryParse(
                  response.headers['retry-after']!,
                ),
            },
          );
        }
        final data = decoded is Map && decoded.containsKey('data')
            ? decoded['data']
            : decoded;
        return ApiResponse(response.statusCode, data, response.headers);
      } on TimeoutException {
        throw const ApiException(0, 'timeout', 'Request timed out');
      } on http.ClientException {
        throw const ApiException(0, 'network', 'Network unavailable');
      }
    }
    throw const ApiException(401, 'unauthenticated', 'Authentication expired');
  }

  void close() => _client.close();
}
