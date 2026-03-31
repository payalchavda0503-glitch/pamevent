import 'dart:convert';

import '../../json_convertors/serializer.dart';

part 'ticket.g.dart';

@CustomSerializerWithToJson
class Ticket {
  Ticket({
    required this.id,
    required this.scanned,
    required this.quantity,
    required this.firstName,
    required this.lastName,
    required this.ticketName,
    this.email,
    this.scanUpTo = 1,
    this.scanLeft = 1,
    this.scanTicketLabel,
  });

  @JsonKey(name: 'ticket_id')
  final String id;
  @JsonKey(name: 'scan_status')
  bool scanned;
  @JsonKey(name: 'fname')
  String firstName;
  @JsonKey(name: 'lname')
  String lastName;
  String ticketName;
  @JsonKey(name: 'ticket_qty')
  final int quantity;
  final String? email;
  @JsonKey(name: 'total_scan')
  final int scanUpTo;
  @JsonKey(name: 'remaining_scan')
  int scanLeft;
  String? scanTicketLabel;

  String get fullName => '$firstName $lastName'.trim();

  factory Ticket.fromJson(Map<String, dynamic> json) => _$TicketFromJson(json);
  factory Ticket.fromJsonString(String json) =>
      _$TicketFromJson(jsonDecode(json));

  Ticket get verified {
    return Ticket(
      id: id,
      scanned: true,
      quantity: quantity,
      firstName: firstName,
      lastName: lastName,
      ticketName: ticketName,
      email: email,
      scanUpTo: scanUpTo,
      scanLeft: scanLeft,
    );
  }

  String get label {
    if (scanTicketLabel == null) return 'Quantity: $quantity';
    final scannedCount = scanUpTo - scanLeft;
    return scanTicketLabel!
        .replaceAll('{remaining_scan}', '$scannedCount')
        .replaceAll('{total_scan}', '$scanUpTo');
  }

  Map<String, dynamic> toJson() => _$TicketToJson(this);
}
