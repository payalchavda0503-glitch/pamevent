part of 'serializer.dart';

class DateParser implements JsonConverter<DateTime?, Object?> {
  const DateParser.normal() : format = null;
  const DateParser.dMy() : format = 'dd/MM/yyyy';
  const DateParser.yMd() : format = 'yyyy-MM-dd';

  final String? format;

  @override
  DateTime? fromJson(Object? val) {
    try {
      if (val is String) {
        if (format?.isNotEmpty ?? false) return DateFormat(format).parse(val);
        return DateTime.tryParse(val);
      }
    } catch (e) {
      log('The value "$val" in not date parsable.');
    }
    return null;
  }

  @override
  Object? toJson(DateTime? val) => val?.toIso8601String();
}
