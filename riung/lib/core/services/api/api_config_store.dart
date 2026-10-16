import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'riung_api.dart';
import 'api_client.dart';

/// Cached server economy/catalog. Built-in constants are display fallbacks;
/// all mutations are still checked and priced by the backend.
class ApiConfigStore {
  ApiConfigStore._();
  static final instance = ApiConfigStore._();
  Map<String, dynamic> raw = {};
  String? etag;
  Map<String, dynamic> get catalog => jsonObject(raw['catalog']);
  int value(String section, String key, int fallback) =>
      (jsonObject(jsonObject(raw['economy'])[section])[key] as num?)?.toInt() ??
      fallback;
  int itemPrice(String section, String id, int fallback) {
    for (final item in catalog[section] as List? ?? []) {
      final row = jsonObject(item);
      if (row['id'] == id || row['inventoryId'] == id) {
        return (row['price'] as num?)?.toInt() ?? fallback;
      }
    }
    return fallback;
  }

  Future<void> load(RiungApi api) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'api_config_${api.client.baseUri.origin}';
    final cache = prefs.getString(cacheKey);
    if (cache != null) raw = jsonObject(jsonDecode(cache));
    etag = prefs.getString('${cacheKey}_etag');
    try {
      final response = await api.config(etag: raw.isEmpty ? null : etag);
      if (response.status != 304) {
        raw = response.object;
        etag = response.headers['etag'];
        await prefs.setString(cacheKey, jsonEncode(raw));
        if (etag != null) await prefs.setString('${cacheKey}_etag', etag!);
      }
      final minimum = raw['minAppVersion'] as String?;
      if (minimum != null && _older(api.client.appVersion, minimum)) {
        throw ApiException(
          426,
          'upgrade_required',
          'App update required',
          details: {'minAppVersion': minimum},
        );
      }
    } on ApiException catch (e) {
      if (!e.retryable) rethrow;
    }
  }

  bool _older(String actual, String minimum) {
    List<int> parts(String v) =>
        v.split('+').first.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final a = parts(actual), b = parts(minimum);
    for (var i = 0; i < 3; i++) {
      final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
      if (x != y) return x < y;
    }
    return false;
  }
}
