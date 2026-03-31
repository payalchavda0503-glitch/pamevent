const _requiredMessage = '*required';

class Validation {
  Validation({
    this.regex,
    this.errMsg,
    this.min,
    this.max,
    this.nullable = false,
  });

  final String? regex;
  final String? errMsg;
  final int? min;
  final int? max;
  final bool nullable;

  static String? email(String? value, {bool nullable = false}) {
    return Validation(
      nullable: nullable,
      errMsg: 'Please enter valid email',
      regex:
          r'^[^<>()[\]\\.,;:\s@"]+(?:\.[^<>()[\]\\.,;:\s@"]+)*@(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-zA-Z]{2,}$',
    ).validate(value);
  }

  static String? required(String? value) {
    return Validation(nullable: false).validate(value);
  }

  @override
  String toString() {
    return 'Regex => $regex, Min => $min, Max => $max';
  }

  String? validate(String? input) {
    if (input?.isEmpty ?? true) return nullable ? null : _requiredMessage;
    final lengthError = _notInRange(input, min, max);
    if (lengthError != null) return lengthError;
    if (regex == null || RegExp(regex!).hasMatch(input!)) return null;
    return errMsg ?? 'Please enter valid value';
  }

  String? _notInRange(String? val, [int? min, int? max]) {
    if (val == null) return _requiredMessage;
    if (min != null && max != null) {
      if (min == max && val.length != min) return 'Length should be $min';
      if (min > val.length || val.length > max) {
        return 'Length should be between $min and $max';
      }
    } else if (min != null && val.length < min) {
      return 'Length should be greater than $min';
    } else if (max != null && val.length > max) {
      return 'Length should be less than $max';
    }
    return null;
  }
}
