part of 'serializer.dart';

class BoolParser implements JsonConverter<bool, Object?> {
  const BoolParser.trueV() : ifNull = true;

  const BoolParser.falseV() : ifNull = false;
  final bool ifNull;

  @override
  bool fromJson(Object? val) {
    return switch (val) {
      bool value => value,
      int value => value > 0,
      String value => ['true', '1'].contains(value),
      _ => ifNull,
    };
  }

  @override
  Object? toJson(bool val) => '$val';
}
