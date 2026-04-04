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
  static Uri get customerEvents => Uri.parse('$_customerBaseUrl/events');
  static Uri get customerEventDetail => Uri.parse('$_customerBaseUrl/event_detail');
  static Uri get artists => Uri.parse('$_customerBaseUrl/artists');
  static Uri customerSearch(String query) => Uri.parse('$_customerBaseUrl/search?q=$query');
  static Uri getArtistDetail(String slug) {
    return Uri.parse('$_customerBaseUrl/artist/$slug');
  }

  /// Auth
  static Uri get login => Uri.parse('$_serverBaseUrl/login');
  static Uri get loginQr => Uri.parse('$_serverBaseUrl/login_with_qrcode');
  static Uri get updateGuestUser => Uri.parse('$_serverBaseUrl/update_guest_user');
  static Uri get socialLogin => Uri.parse('$_serverBaseUrl/social-login');
  static Uri get register => Uri.parse('$_serverBaseUrl/register');
  static Uri get forgotPassword => Uri.parse('$_serverBaseUrl/forgot_password');
  static Uri get resetPassword => Uri.parse('$_serverBaseUrl/reset_password');

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
}
