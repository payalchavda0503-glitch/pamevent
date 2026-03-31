part of 'serializer.dart';

class IntParser implements JsonConverter<int, Object?> {
  const IntParser();

  @override
  int fromJson(Object? val) {
    if (val is int) return val;
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  @override
  Object? toJson(int val) => '$val';
}

class IntNullParser implements JsonConverter<int?, Object?> {
  const IntNullParser();

  @override
  int? fromJson(Object? val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is String) return int.tryParse(val);
    return null;
  }

  @override
  Object? toJson(int? val) => '$val';
}
