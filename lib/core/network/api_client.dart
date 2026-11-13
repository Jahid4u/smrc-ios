import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

/// Dio client for the SM Royal Circle WordPress backend (namespace smrc/v1).
/// Attaches the member Bearer token from secure storage on every request.
class ApiClient {
  /// Backend URL, chosen at BUILD time, not by editing this file.
  ///
  /// Defaults to production if nothing is specified, so a normal build
  /// command always ships correctly even if someone forgets to pass a flag
  /// — there's no way to accidentally leave a staging URL in a release build.
  ///
  /// To build against the staging site instead:
  ///   flutter run  --dart-define=API_BASE_URL=https://smr.apifeldigi.com/wp-json/smrc/v1/
  ///   flutter build apk --dart-define=API_BASE_URL=https://smr.apifeldigi.com/wp-json/smrc/v1/
  ///
  /// In VS Code: add the same "--dart-define=API_BASE_URL=..." entry under
  /// "args" for a launch configuration in .vscode/launch.json (a "Staging"
  /// configuration alongside the default one), then just pick which
  /// configuration to run/build from VS Code's Run panel — no code edits.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://app.smroyalcircle.club/wp-json/smrc/v1/',
  );
  static const _tokenKey = 'smrc_member_token';

  final Dio client;
  final FlutterSecureStorage storage;

  ApiClient._(this.client, this.storage);

  factory ApiClient.create() {
    // encryptedSharedPreferences is NOT the default on Android: without it
    // the plugin falls back to a plain SharedPreferences file with only the
    // value obfuscated, which is readable on a rooted or backed-up device.
    // This routes storage through AndroidX EncryptedSharedPreferences, keyed
    // from the hardware-backed KeyStore. first_unlock_this_device on iOS
    // keeps the token out of iCloud/iTunes backups so it cannot be lifted
    // off a restored device.
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
    );
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
      // Treat 4xx as data (we read the backend's success/message JSON).
      validateStatus: (s) => s != null && s < 500,
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: _tokenKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        // Cache busting: chat polling must never hit a CDN/hosting cache.
        options.headers['Cache-Control'] = 'no-cache';
        if (options.method == 'GET') {
          options.queryParameters = {
            ...options.queryParameters,
            '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
          };
        }
        handler.next(options);
      },
    ));
    // Debug builds only. In a release build this writes every request line
    // to the device log, and the on-request work happens on every single
    // call for output nobody reads. kDebugMode is a compile-time constant,
    // so the release compiler drops this block (and the logger) entirely.
    if (kDebugMode) {
      dio.interceptors.add(PrettyDioLogger(
        requestBody: false,
        responseBody: false,
        compact: true,
      ));
    }
    return ApiClient._(dio, storage);
  }

  Future<void> saveToken(String token) => storage.write(key: _tokenKey, value: token);
  Future<String?> readToken() => storage.read(key: _tokenKey);
  Future<void> clearToken() => storage.delete(key: _tokenKey);
}
