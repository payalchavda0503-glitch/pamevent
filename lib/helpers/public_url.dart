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

/// Formats a raw price value into a user-friendly string (e.g., "$20.00").
String formatPrice(dynamic price) {
  if (price == null || price.toString().isEmpty) return 'Free';
  final pStr = price.toString().toLowerCase().trim();
  if (pStr == 'free' || pStr == '0' || pStr == '0.00' || pStr == '0.0') return 'Free';
  
  // If already formatted with $, return as is
  if (pStr.contains('\$')) return price.toString();
  
  // Extract numeric value
  final numericPart = pStr.replaceAll(RegExp(r'[^0-9.]'), '');
  final val = double.tryParse(numericPart);
  if (val == null) return price.toString();
  
  return '\$${val.toStringAsFixed(2)}';
}
