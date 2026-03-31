import '../ticket/ticket.dart';
import 'booking_addon.dart';
import '../../json_convertors/serializer.dart';

class Booking {
  Booking({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.quantity,
    required this.email,
    required this.phone,
    required this.firstName,
    required this.lastName,
    this.date,
    this.tickets = const [],
    this.bookingAddon,
  });

  final int id;
  final String bookingId;
  final int customerId;
  final int quantity;
  final String email;
  final String phone;
  final String firstName;
  final String lastName;
  final DateTime? date;
  final List<Ticket> tickets;
  final BookingAddon? bookingAddon;

  String get fullName => '$firstName $lastName'.trim();

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: const IntParser().fromJson(json['id']),
      bookingId: json['booking_id'] as String,
      customerId: const IntParser().fromJson(json['customer_id']),
      quantity: const IntParser().fromJson(json['quantity']),
      email: json['email'] as String,
      phone: json['phone'] as String,
      firstName: json['fname'] as String,
      lastName: json['lname'] as String,
      date: const DateParser.normal().fromJson(json['created_at']),
      tickets: (json['booking_tickets'] as List<dynamic>?)
          ?.map((e) => Ticket.fromJson(e as Map<String, dynamic>))
          .toList() ??
          const [],
      bookingAddon: json['booking_addons'] != null
          ? BookingAddon.fromJson(json['booking_addons'])
          : null,
    );
  }

  bool matches(String query) {
    return [fullName, email, phone, bookingId].any((prop) {
      return prop.toLowerCase().contains(query.toLowerCase());
    });
  }

  @override
  bool operator ==(Object other) {
    return other is Booking &&
        other.id == id &&
        other.fullName == fullName &&
        other.email == email &&
        other.phone == phone;
  }

  @override
  int get hashCode => id.hashCode ^ fullName.hashCode;
}
class BookingPageResult {
  final List<Booking> bookings;
  final bool hasMore;

  BookingPageResult({required this.bookings, required this.hasMore});
}
