import '../barcode/barcode.dart';
import '../ticket/ticket.dart';
import 'physical_scans.dart';

class Event {
  Event({
    required this.id,
    required this.image,
    required this.title,
    this.description,
    this.url,
    this.tickets = const [],
    this.bookingAddons = const [],
    required this.sold,
    required this.scanned,
    required this.attendance,
    this.physicalScans,
    required this.cSold,
    required this.cAttendance,
    required this.cScanned,
    required this.lastAppSyncDate,
    required this.inviteCode,
    required this.isOrganizerUser,
    this.inviteQrExpiryDate,
    this.inviteQrExpiryString,
    this.peggination,

  });

   int id;
   String image;
   String title;
   String? description;
   String? url;
  List<Ticket> tickets;
  List<BarcodeModel> bookingAddons;
  String sold;
  String inviteCode;
  String? inviteQrExpiryDate;
  String? inviteQrExpiryString;
  int isOrganizerUser;
  String scanned;
  num attendance;
  String cSold;
  String cScanned;
  num cAttendance;
  String lastAppSyncDate;
   PhysicalScans? physicalScans;
  Pagination? peggination;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['event_id'] ?? 0,
      image: json['event_img'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      url: json['event_url'],
      tickets: (json['all_ticket_json'] as List<dynamic>?)
          ?.map((e) => Ticket.fromJson(e))
          .toList() ??
          [],
      bookingAddons: (json['booking_addons'] as List<dynamic>?)
          ?.map((e) => BarcodeModel.fromJson(e))
          .toList() ??
          [],
      sold: json['booking_total_sell']?.toString() ?? '0',
      inviteCode: json['invite_code']?.toString() ?? '',
      inviteQrExpiryDate: json['invite_qr_expiry_date']?.toString(),
      inviteQrExpiryString: json['invite_qr_expiry_string']?.toString(),
      isOrganizerUser: json['is_organizer_user'] ?? 0,
      scanned: json['booking_total_scan']?.toString() ?? '0',
      attendance: json['booking_scan_percentage'] ?? 0,
      cSold: json['complimentary_booking_total_sell']?.toString() ?? '0',
      cScanned: json['complimentary_booking_total_scan']?.toString() ?? '0',
      cAttendance: json['complimentary_booking_scan_percentage'] ?? 0,
      lastAppSyncDate: json['last_app_sync_date']?.toString() ?? '',
      physicalScans: json['physical_ticket_data'] != null
          ? PhysicalScans.fromJson(json['physical_ticket_data'])
          : null,
      peggination: json['pagination'] != null?Pagination.fromJson(json['pagination']):null

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': id,
      'event_img': image,
      'title': title,
      'description': description,
      'event_url': url,
      'all_ticket_json': tickets.map((e) => e.toJson()).toList(),
      'booking_addons': bookingAddons.map((e) => e.toJson()).toList(),
      'booking_total_sell': sold,
      'invite_code': inviteCode,
      'invite_qr_expiry_date': inviteQrExpiryDate,
      'invite_qr_expiry_string': inviteQrExpiryString,
      'is_organizer_user': isOrganizerUser,
      'booking_total_scan': scanned,
      'booking_scan_percentage': attendance,
      'complimentary_booking_total_sell': cSold,
      'complimentary_booking_total_scan': cScanned,
      'complimentary_booking_scan_percentage': cAttendance,
      'last_app_sync_date': lastAppSyncDate,
      'physical_ticket_data': physicalScans?.toJson(),
    };
  }
}

class Pagination {
  int currentPage;
  int perPage;
  int total;
  int lastPage;
  int from;
  int to;
  bool hasMorePages;

  Pagination({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
    required this.from,
    required this.to,
    required this.hasMorePages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['current_page'] ?? 0,
      perPage: json['per_page'] ?? 0,
      total: json['total'] ?? 0,
      lastPage: json['last_page'] ?? 1,
      from: json['from'] ?? 0,
      to: json['to'] ?? 0,
      hasMorePages: json['has_more_pages'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'per_page': perPage,
      'total': total,
      'last_page': lastPage,
      'from': from,
      'to': to,
      'has_more_pages': hasMorePages,
    };
  }
}
