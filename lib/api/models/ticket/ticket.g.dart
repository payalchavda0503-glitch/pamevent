// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Ticket _$TicketFromJson(Map<String, dynamic> json) => Ticket(
  id: json['ticket_id'] as String,
  scanned: const BoolParser.falseV().fromJson(json['scan_status']),
  quantity: const IntParser().fromJson(json['ticket_qty']),
  firstName: json['fname'] as String,
  lastName: json['lname'] as String,
  ticketName: json['ticket_name'] as String,
  email: json['email'] as String?,
  scanUpTo: json['total_scan'] == null
      ? 1
      : const IntParser().fromJson(json['total_scan']),
  scanLeft: json['remaining_scan'] == null
      ? 1
      : const IntParser().fromJson(json['remaining_scan']),
  scanTicketLabel: json['scan_ticket_label'] as String?,
);

Map<String, dynamic> _$TicketToJson(Ticket instance) => <String, dynamic>{
  'ticket_id': instance.id,
  'scan_status': const BoolParser.falseV().toJson(instance.scanned),
  'fname': instance.firstName,
  'lname': instance.lastName,
  'ticket_name': instance.ticketName,
  'ticket_qty': const IntParser().toJson(instance.quantity),
  'email': instance.email,
  'total_scan': const IntParser().toJson(instance.scanUpTo),
  'remaining_scan': const IntParser().toJson(instance.scanLeft),
  'scan_ticket_label': instance.scanTicketLabel,
};
