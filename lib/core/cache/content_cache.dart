import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Raw-JSON disk cache for "content" data (events, announcements, benefits,
/// tiers, member directory, billing…). This is what makes the app feel
/// instant on every launch after the first: instead of re-downloading and
/// showing a spinner every single time a screen builds, whatever was last
/// downloaded is saved here and shown immediately, while a fresh copy is
/// quietly fetched in the background and only swapped in once it lands.
class ContentCache {
  static SharedPreferences? _prefs;
  static Future<SharedPreferences> _p() async => _prefs ??= await SharedPreferences.getInstance();
  static const _prefix = 'smrc_content_cache_';

  static Future<dynamic> read(String key) async {
    final p = await _p();
    final raw = p.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null; // corrupt cache entry → treat as no cache
    }
  }

  static Future<void> write(String key, dynamic value) async {
    final p = await _p();
    try {
      await p.setString('$_prefix$key', jsonEncode(value));
    } catch (_) {/* non-fatal — worst case this piece stays uncached */}
  }

  /// Drops one cached entry — use before invalidating a provider right
  /// after a mutation (e.g. uploading a new photo, recording a payment) so
  /// the rebuild does a real fetch instead of briefly showing the old
  /// cached copy first.
  static Future<void> clear(String key) async {
    final p = await _p();
    await p.remove('$_prefix$key');
  }
}

/// Cache-first replacement for a plain FutureProvider. Subclass this instead
/// of writing `FutureProvider<T>((ref) => repo.something())` directly:
///
/// - First-ever launch (nothing cached yet): waits on the real network call,
///   same as a normal FutureProvider.
/// - Every launch after that: returns the cached copy immediately (no
///   spinner, no delay), then fetches fresh data in the background and
///   replaces the state once it arrives — so new content still shows up
///   without the person needing to do anything, it just doesn't block the
///   first paint.
/// - Network failure during the background refresh: silently keeps showing
///   the cached copy rather than surfacing an error over content that was
///   already successfully displayed.
abstract class CachedAsyncNotifier<T> extends AsyncNotifier<T> {
  /// Unique disk-cache key for this content type.
  String get cacheKey;

  /// Hits the network and returns the raw decoded JSON (a List or Map —
  /// whatever [parse] expects). Kept separate from [parse] so the exact
  /// bytes that came back can be cached as-is.
  Future<dynamic> fetchRaw();

  /// Turns raw JSON (freshly fetched, or read back from disk) into the real
  /// model type.
  T parse(dynamic raw);

  @override
  Future<T> build() async {
    final cachedRaw = await ContentCache.read(cacheKey);
    if (cachedRaw != null) {
      try {
        final cached = parse(cachedRaw);
        // Show the cached copy instantly; refresh quietly in the background.
        _refreshInBackground();
        return cached;
      } catch (_) {
        // Cache didn't parse (e.g. shape changed after an update) — fall
        // through to a real fetch below.
      }
    }
    final raw = await fetchRaw();
    await ContentCache.write(cacheKey, raw);
    return parse(raw);
  }

  Future<void> _refreshInBackground() async {
    try {
      final raw = await fetchRaw();
      await ContentCache.write(cacheKey, raw);
      state = AsyncData(parse(raw));
    } catch (_) {
      // Keep showing the cached copy — a failed background refresh should
      // never be treated as "the content is now broken".
    }
  }
}
