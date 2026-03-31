import 'dart:developer';

import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

export 'package:json_annotation/json_annotation.dart';

part 'bool.parser.dart';
part 'date.parser.dart';
part 'int.parser.dart';
part 'num.parser.dart';
part 'string.parser.dart';

// ignore: constant_identifier_names
const JsonSerializable CustomSerializer = JsonSerializable(
  createToJson: false,
  fieldRename: FieldRename.snake,
  converters: [
    BoolParser.falseV(),
    IntParser(),
    NumParser(),
    DateParser.normal(),
  ],
);

// ignore: constant_identifier_names
const JsonSerializable CustomSerializerWithToJson = JsonSerializable(
  fieldRename: FieldRename.snake,
  converters: [
    BoolParser.falseV(),
    IntParser(),
    NumParser(),
    DateParser.normal(),
  ],
);
