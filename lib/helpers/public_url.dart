import '../api/api.config.dart';

/// Resolves API-provided links (full URL or site-relative path) for in-app WebView.
String? resolvePublicUrl(String? raw) {
  if (raw == null) return null;
  final t = raw.trim();
  if (t.isEmpty) return null;
  if (t.startsWith('http://') || t.startsWith('https://')) return t;
  final h = ApiConfig.host;
  if (t.startsWith('/')) return '$h$t';
  return '$h/$t';
}
