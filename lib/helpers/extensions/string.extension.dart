extension StringExtensions on String {
  String get titleCase => split('_').map((e) => e.capitalize).join(' ');
  String get capitalize {
    if (length < 2) return toUpperCase();
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  // Will return first and last value by splitting with space
  ({String? first, String? last}) get spread {
    final values = split(' ');
    String? firstName;
    String? lastName;
    if (values.isNotEmpty) {
      firstName = values.first;
      if (values.length > 1) lastName = values.last;
    }
    return (first: firstName, last: lastName);
  }
}

extension NullableChecks on String? {
  bool get isEmpty => this?.isEmpty ?? true;
  bool get isNotEmpty => this?.isNotEmpty ?? false;
}
