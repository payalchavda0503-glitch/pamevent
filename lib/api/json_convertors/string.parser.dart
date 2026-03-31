part of 'serializer.dart';

class StringParser implements JsonConverter<String, Object?> {
  const StringParser();

  @override
  String fromJson(Object? val) {
    if (val is String) return val;
    return val.toString();
  }

  @override
  Object? toJson(String val) => val;
}

class StringNullParser implements JsonConverter<String?, Object?> {
  const StringNullParser();

  @override
  String? fromJson(Object? val) {
    if (val == null) return null;
    if (val is String) return val;
    return val.toString();
  }

  @override
  Object? toJson(String? val) => val;
}
