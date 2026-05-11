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
/// [extractOriginal] if true, extracts the value inside <del> tags if present.
String formatPrice(dynamic price, {bool extractOriginal = false}) {
  if (price == null || price.toString().isEmpty) return 'Free';
  
  String rawPrice = price.toString();
  
  // Handle HTML tags like <del>$60.00</del>
  if (rawPrice.contains('<del>')) {
    if (extractOriginal) {
      // Extract part inside <del> tags
      final match = RegExp(r'<del>(.*?)</del>').firstMatch(rawPrice);
      if (match != null) {
        rawPrice = match.group(1) ?? rawPrice;
      }
    } else {
      // Extract part BEFORE <del> tag
      rawPrice = rawPrice.split('<del>').first.trim();
    }
  }
  
  // Strip any remaining HTML tags
  String cleanPrice = rawPrice.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  
  final pStr = cleanPrice.toLowerCase();
  if (pStr == 'free' || pStr == '0' || pStr == '0.00' || pStr == '0.0') return 'Free';
  
  // If already formatted with $, return as is (but cleaned of tags)
  if (pStr.contains('\$')) return cleanPrice;
  
  // Extract numeric value
  final numericPart = pStr.replaceAll(RegExp(r'[^0-9.]'), '');
  final val = double.tryParse(numericPart);
  if (val == null) return cleanPrice;
  
  return '\$${val.toStringAsFixed(2)}';
}
