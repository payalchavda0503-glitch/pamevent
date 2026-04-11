class ApiConfig {
  /// Server
  static const host = 'https://pamevent.com';
  static const _serverBaseUrl = '$host/api/scanner';
  static const _customerBaseUrl = '$host/api/customer';

  /// Config
  static Uri get init => Uri.parse('$_serverBaseUrl/splash_screen');
  static Uri get home => Uri.parse('$_customerBaseUrl/home');
  static Uri get categories => Uri.parse('$_customerBaseUrl/categories');
  static Uri get profile => Uri.parse('$_customerBaseUrl/profile');
  static Uri get editProfile => Uri.parse('$_customerBaseUrl/edit_profile');
  static Uri get customerEvents => Uri.parse('$_customerBaseUrl/events');
  static Uri get customerMyTickets => Uri.parse('$_customerBaseUrl/my_tickets');
  static Uri get customerEventDetail => Uri.parse('$_customerBaseUrl/event_detail');
  static Uri get customerEventTicketDetails => Uri.parse('$_customerBaseUrl/event_ticket_details');
  static Uri get artists => Uri.parse('$_customerBaseUrl/artists');
  static Uri customerSearch(String query) => Uri.parse('$_customerBaseUrl/search?q=$query');
  static Uri getArtistDetail(String slug) {
    return Uri.parse('$_customerBaseUrl/artist/$slug');
  }

  /// Auth
  static Uri get login => Uri.parse('$_customerBaseUrl/login');
  static Uri get loginQr => Uri.parse('$_serverBaseUrl/login_with_qrcode');
  static Uri get updateGuestUser => Uri.parse('$_serverBaseUrl/update_guest_user');
  static Uri get socialLogin => Uri.parse('$_customerBaseUrl/social-login');
  static Uri get register => Uri.parse('$_customerBaseUrl/register');
  static Uri get forgotPassword => Uri.parse('$_customerBaseUrl/forgot_password');
  static Uri get resetPassword => Uri.parse('$_customerBaseUrl/reset_password');
  static Uri get logout => Uri.parse('$_customerBaseUrl/logout');
  static Uri get changePassword => Uri.parse('$_customerBaseUrl/change_password');

  /// Events
  static Uri get events => Uri.parse('$_serverBaseUrl/events');
  static Uri get event => Uri.parse('$_serverBaseUrl/event_detail');

  /// Bookings
  static Uri get bookings => Uri.parse('$_serverBaseUrl/event_bookings');
  static Uri get booking => Uri.parse('$_serverBaseUrl/event_booking_detail');

  /// Tickets
  static Uri get verifyTicket => Uri.parse('$_serverBaseUrl/verify_ticket');
  static Uri get syncTickets => Uri.parse('$_serverBaseUrl/event_ticket_sync');
  static Uri get ticketStatistics => Uri.parse('$_serverBaseUrl/event_ticket_statistics');
  static Uri get physicalTicketData => Uri.parse('$_serverBaseUrl/physical_ticket_data');

  /// Checkout Flow
  static Uri get applyCoupon => Uri.parse('$_customerBaseUrl/apply_coupon');
  static Uri get applyReferral => Uri.parse('$_customerBaseUrl/apply_referral');
  static Uri get addToCart => Uri.parse('$_customerBaseUrl/add_to_cart');
  static Uri get checkout => Uri.parse('$_customerBaseUrl/checkout');
  static Uri get bookingComplete => Uri.parse('$_customerBaseUrl/booking_complate');
  static Uri get paymentGateway => Uri.parse('$_customerBaseUrl/get_payment_gateway');
}
