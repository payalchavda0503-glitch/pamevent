part of 'serializer.dart';

class NumParser implements JsonConverter<num, Object?> {
  const NumParser();

  @override
  num fromJson(Object? val) {
    if (val is num) return val;
    if (val is String) return num.tryParse(val) ?? 0;
    return 0;
  }

  @override
  Object? toJson(num val) => '$val';
}

class NumNullParser implements JsonConverter<num?, Object?> {
  const NumNullParser();

  @override
  num? fromJson(Object? val) {
    if (val == null) return null;
    if (val is num) return val;
    if (val is String) return num.tryParse(val);
    return null;
  }

  @override
  Object? toJson(num? val) => '$val';
}
