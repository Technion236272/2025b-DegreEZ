import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';

class GeocodeCacheService {
  static const _storageKey = 'geocode_cache';

  final Map<String, LatLng> _cache = {};

  Future<void> loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      final map = json.decode(raw) as Map<String, dynamic>;
      map.forEach((key, value) {
        final coords = value as Map<String, dynamic>;
        _cache[key] = LatLng(coords['lat'], coords['lon']);
      });
    }
  }

  Future<void> saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _cache.map((key, value) => MapEntry(
      key,
      {'lat': value.latitude, 'lon': value.longitude},
    ));
    await prefs.setString(_storageKey, json.encode(encoded));
  }

  LatLng? get(String key) => _cache[key];

  void put(String key, LatLng value) {
    _cache[key] = value;
    saveCache();
  }

  bool containsKey(String key) => _cache.containsKey(key);
}
