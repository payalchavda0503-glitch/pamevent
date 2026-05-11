import 'package:flutter/material.dart';
import '../../api/api.client.dart';
import '../../helpers/app_colors.dart';
import '../../helpers/app_state.dart';
import '../../helpers/public_url.dart';
import '../../helpers/extensions/context.extension.dart';
import '../auth/login.screen.dart';
import '../shared/widgets/custom_button.widget.dart';
import '../shared/widgets/custom_image.dart';
import '../shared/moncash_payment.screen.dart';
import './order_success.screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'dart:developer';

class PaymentWebviewWidget extends StatefulWidget {
  final String url;
  const PaymentWebviewWidget({super.key, required this.url});
  @override
  State<PaymentWebviewWidget> createState() => _PaymentWebviewWidgetState();
}

class _PaymentWebviewWidgetState extends State<PaymentWebviewWidget> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url.toLowerCase();
            if (url.contains('success') || url.contains('completed') || url.contains('booking_complate')) {
               debugPrint('Success detected in Stripe Modal: ${request.url}');
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}

class PaymentWebviewScreen extends StatelessWidget {
  final String url;
  const PaymentWebviewScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF14103D),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PaymentWebviewWidget(url: url),
    );
  }
}

class _StripeModalContent extends StatefulWidget {
  final String url;
  final ScrollController scrollController;
  final Map<String, dynamic>? eventDetail;
  final int eventId;
  final double grandTotal;

  const _StripeModalContent({
    required this.url,
    required this.scrollController,
    required this.eventDetail,
    required this.eventId,
    required this.grandTotal,
  });

  @override
  State<_StripeModalContent> createState() => _StripeModalContentState();
}

class _StripeModalContentState extends State<_StripeModalContent> {
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            final lowerUrl = url.toLowerCase();
            if (lowerUrl.contains('success') || 
                lowerUrl.contains('completed') || 
                lowerUrl.contains('booking_complate')) {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderSuccessScreen(
                    orderId: widget.eventDetail?['id']?.toString() ?? widget.eventId.toString(),
                    amount: widget.grandTotal,
                    eventName: widget.eventDetail?['title'],
                  ),
                ),
                (route) => false,
              );
            }
          },
          onNavigationRequest: (request) {
            final url = request.url.toLowerCase();
            if (url.contains('success') || 
                url.contains('completed') || 
                url.contains('booking_complate')) {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderSuccessScreen(
                    orderId: widget.eventDetail?['id']?.toString() ?? widget.eventId.toString(),
                    amount: widget.grandTotal,
                    eventName: widget.eventDetail?['title'],
                  ),
                ),
                (route) => false,
              );
              return NavigationDecision.navigate;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Secure Checkout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: WebViewWidget(controller: _webViewController),
        ),
      ],
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  final int eventId;
  final List<Map<String, dynamic>> selectedTickets;
  final double totalAmount;
  final double serviceFee;
  final double processingFee;

  const CheckoutScreen({
    super.key,
    required this.eventId,
    required this.selectedTickets,
    required this.totalAmount,
    this.serviceFee = 0.0,
    this.processingFee = 0.0,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _moncashId = 'moncash';
  String _stripeId = '4';
  late String _selectedPaymentMethod;
  bool _acceptTerms = false;
  Map<String, dynamic>? _eventDetail;
  bool _isLoadingEvent = true;
  String _stripePublishableKey = '';
  
  double _couponDiscount = 0.0;
  double _referralDiscount = 0.0;
  
  bool _isLoggedIn = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _reEmailController = TextEditingController();

  final TextEditingController _couponController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();

  List<Map<String, dynamic>> _hardcodedGateways = [
    {'id': '4', 'title': 'Credit or debit card', 'icon': Icons.credit_card},
    {'id': 'moncash', 'title': 'Moncash', 'icon': Icons.money},
  ];

  @override
  void initState() {
    super.initState();
    _isLoggedIn = AppState.loggedIn;
    _selectedPaymentMethod = _stripeId;
    
    if (_isLoggedIn && AppState.profile != null) {
      _nameController.text = AppState.profile?.username ?? '';
      _emailController.text = AppState.profile?.email ?? '';
      _reEmailController.text = AppState.profile?.email ?? '';
      _phoneController.text = AppState.profile?.phone ?? '';
    }
    
    _fetchEventDetail();
    _initCheckoutFlow();
  }

  bool get isFreeOrder => widget.totalAmount <= 0;

  double get currentServiceFee => isFreeOrder ? 0.0 : 1.77;
  double get currentProcessingFee => isFreeOrder ? 0.0 : 0.68;

  double get grandTotal {
    return widget.totalAmount + currentServiceFee + currentProcessingFee - _couponDiscount - _referralDiscount;
  }

  Future<void> _fetchEventDetail() async {
    final data = await ApiClient.getCustomerEventDetail(widget.eventId);
    if (mounted) {
      setState(() {
        _eventDetail = data;
        _isLoadingEvent = false;
      });
    }
  }

  Future<void> _initCheckoutFlow() async {
    print('Init Checkout Flow - Logged In: $_isLoggedIn');
    if (_isLoggedIn) {
       final profile = await ApiClient.fetchProfile();
       print('Fetched Profile for Checkout: $profile');
       if (profile != null && mounted) {
          setState(() {
            if (profile['name'] != null || profile['username'] != null) {
              _nameController.text = profile['name'] ?? profile['username'] ?? '';
            }
            if (profile['email'] != null) {
              _emailController.text = profile['email'] ?? '';
              _reEmailController.text = profile['email'] ?? '';
            }
            if (profile['phone'] != null && profile['phone'].toString().isNotEmpty) {
              _phoneController.text = profile['phone'].toString();
            }
          });
       }
    }
    
    await ApiClient.customerAddToCart(widget.eventId);
    
    final gatewaysData = await ApiClient.customerGetPaymentGateways();
    print('GET GATEWAYS RESPONSE: $gatewaysData');
    if (mounted && gatewaysData != null && gatewaysData['data'] is List) {
       final gwData = gatewaysData['data'] as List;
       for (var gw in gwData) {
          final title = gw['name']?.toString().toLowerCase() ?? '';
          final gwId = gw['id']?.toString() ?? gw['gateway_id']?.toString() ?? '';
          print('Parsing Gateway - Title: $title, ID: $gwId');
          
          if (title.contains('stripe') || title.contains('card') || title.contains('credit')) {
              _stripeId = gwId;
              
              final gwString = gw.toString();
              final regExp = RegExp(r'(pk_test_[a-zA-Z0-9]+|pk_live_[a-zA-Z0-9]+)');
              final match = regExp.firstMatch(gwString);
              if (match != null) {
                   _stripePublishableKey = match.group(0) ?? '';
              }
          }
          if (title.contains('moncash') || title.contains('mon cash')) {
              _moncashId = gwId;
              print('FOUND MONCASH GATEWAY ID: $_moncashId');
          }
       }
       
       print('RESOLVED GATEWAYS - Stripe ID: $_stripeId (Key: $_stripePublishableKey), Moncash ID: $_moncashId');
       
       setState(() {
          _hardcodedGateways = [
            {'id': _stripeId, 'title': 'Credit or debit card', 'icon': Icons.credit_card},
            {'id': _moncashId, 'title': 'Moncash', 'icon': Icons.money},
          ];
          _selectedPaymentMethod = _stripeId;
       });
    }
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    
    final res = await ApiClient.customerApplyCoupon({
      'sub_total': widget.totalAmount.toString(),
      'event_id': widget.eventId.toString(),
      'coupon': code,
    });
    if (res != null) {
      setState(() {
        _couponDiscount = double.tryParse(res['discount']?.toString() ?? '0') ?? 0.0;
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coupon applied!')));
    }
  }

  Future<void> _applyReferral() async {
    final code = _referralController.text.trim();
    if (code.isEmpty) return;
    
    final map = {
      'sub_total': widget.totalAmount.toString(),
      'event_id': widget.eventId.toString(),
      'referral_code': code,
      'total_early_bird_dicount': '0',
      'absorb_fee_tickets': '0',
      'qty_ticket_per_tables': '1',
      'ticket_ids': widget.selectedTickets.map((e) => (e['ticket']['id'] ?? e['ticket']['ticket_id']).toString()).toList(),
      'early_bird_dicounts': widget.selectedTickets.map((e) => '0').toList(),
      'names': widget.selectedTickets.map((e) => (e['ticket']['title'] ?? e['ticket']['name'] ?? 'Ticket').toString()).toList(),
      'qtys': widget.selectedTickets.map((e) => e['count'].toString()).toList(),
      'prices': widget.selectedTickets.map((e) => (e['ticket']['price'] ?? '0').toString()).toList(),
      'max_ticket_redemptions': widget.selectedTickets.map((e) => '1').toList(),
    };
    
    final res = await ApiClient.customerApplyReferral(map);
    if (res != null) {
      setState(() {
        _referralDiscount = double.tryParse(res['discount']?.toString() ?? '0') ?? 0.0;
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral applied!')));
    }
  }

  Future<void> _proceedToCheckout() async {
     print('START _proceedToCheckout');
     print('Is Free Order: $isFreeOrder');
     String fname = _nameController.text.trim();
     String phone = _phoneController.text.trim();
     String email = _emailController.text.trim();
     String reEmail = _reEmailController.text.trim();

     if (_isLoggedIn && AppState.profile != null) {
        if (fname.isEmpty) fname = AppState.profile?.username ?? '';
        if (email.isEmpty) email = AppState.profile?.email ?? '';
        if (reEmail.isEmpty) reEmail = email;
        if (phone.isEmpty) phone = AppState.profile?.phone ?? '';
        
        if (fname.isEmpty) fname = 'User';
        if (phone.isEmpty) phone = '0000000000'; 
     }

     print('Final Attendee Data - Name: $fname, Email: $email, Phone: $phone');

     if (fname.isEmpty || email.isEmpty || phone.isEmpty) {
         String missing = '';
         if (fname.isEmpty) missing += 'Name, ';
         if (email.isEmpty) missing += 'Email, ';
         if (phone.isEmpty) missing += 'Phone, ';
         missing = missing.substring(0, missing.length - 2);
         
         print('Validation failed: Attendee details missing ($missing)');
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all required attendee details ($missing)')));
         return;
     }
     if (!isFreeOrder && _selectedPaymentMethod.isEmpty) {
         print('Validation failed: Payment method is empty literal string');
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a payment method')));
         return;
     }
     if (!_acceptTerms) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please accept the terms to proceed')));
         return;
     }

     double finalGrandTotal = grandTotal;
     double finalSubTotal = widget.totalAmount;

     String finalGateway = isFreeOrder ? 'free' : (_selectedPaymentMethod == _stripeId ? 'stripe' : 'moncash');

     final map = <String, dynamic>{
         'event_id': widget.eventId.toString(),
         'event_name': _eventDetail?['title'] ?? 'Event',
         'fname': fname,
         'country_code': '+91', 
         'phone': phone,
         'email': email,
         're_enter_email': reEmail,
         'gateway': finalGateway,
         'agree_org_policy': '1',
         'total': finalSubTotal.toStringAsFixed(2),
         'quantity': widget.selectedTickets.fold<int>(0, (sum, e) => sum + (e['count'] as int)).toString(),
         'processing_fee': currentProcessingFee.toStringAsFixed(2),
         'ticket_fees': currentServiceFee.toStringAsFixed(2),
         'coupon': _couponController.text.isEmpty ? '0' : _couponController.text,
         'referral_code': _referralController.text.isEmpty ? '0' : _referralController.text,
         'admin_coupon_discount': _couponDiscount.toStringAsFixed(2),
         'referral_discount': _referralDiscount.toStringAsFixed(2),
         'attendee_discount': '0',
         'event_date': _eventDetail?['start_date'] ?? '',
         'event_start_time': _eventDetail?['start_time'] ?? '',
         'tax': '0',
         'discount': '0',
         'total_early_bird_dicount': '0',
         'sub_total': finalSubTotal.toStringAsFixed(2),
         'grand_total': finalGrandTotal.toStringAsFixed(2),
     };

     for (int i = 0; i < widget.selectedTickets.length; i++) {
        final t = widget.selectedTickets[i]['ticket'];
        final count = widget.selectedTickets[i]['count'];
        final tId = t['id'] ?? t['ticket_id'] ?? '';
        final title = t['title'] ?? t['name'] ?? 'Ticket';
        final price = t['price'] ?? '0';

        map['selTickets[$i][ticket_id]'] = tId.toString();
        map['selTickets[$i][early_bird_dicount]'] = '0';
        map['selTickets[$i][name]'] = title.toString();
        map['selTickets[$i][qty]'] = count.toString();
        map['selTickets[$i][price]'] = price.toString();
        map['selTickets[$i][max_ticket_redemption]'] = '1';
        map['selTickets[$i][absorb_fee_tickets]'] = '0';
        map['selTickets[$i][qty_ticket_per_table]'] = '1';
     }

     print('PAYLOAD SENDING TO CHECKOUT: $map');

     if (isFreeOrder) {
       final res = await ApiClient.customerCheckout(map);
       print('CHECKOUT RESPONSE (FREE ORDER): $res');
       
       if (res != null && res['status'] == 100) {
         final orderId = res['data']?['order_id']?.toString() ?? widget.eventId.toString();
         if (mounted) {
           Navigator.pushAndRemoveUntil(
             context,
             MaterialPageRoute(
               builder: (_) => OrderSuccessScreen(
                 orderId: orderId,
                 amount: finalGrandTotal,
                 eventName: _eventDetail?['title'],
                 bookingData: res['data'],
               ),
             ),
             (route) => false,
           );
         }
       }
     } else {
       final res = await ApiClient.customerCheckout(map);
       print('CHECKOUT RESPONSE: $res');
       print('Selected Payment Method: $_selectedPaymentMethod, Stripe ID: $_stripeId');
       print('Response keys: ${res?.keys.toList()}');

       if (res != null) {
          final paymentData = res['data'] is Map ? res['data'] : res;
          print('Payment Data: $paymentData');
          
          final targetUrl = paymentData['url'] ?? paymentData['redirect_url']; 
          final clientSecret = paymentData['client_secret'];
          final orderId = paymentData['order_id']?.toString() ?? widget.eventId.toString();

          if (_selectedPaymentMethod == _stripeId) {
              print('Processing STRIPE payment');
              print('Client Secret: ${clientSecret?.toString().substring(0, 20)}...');
              if (clientSecret != null && clientSecret.toString().isNotEmpty) {
                 try {
                    if (_stripePublishableKey.isNotEmpty) {
                        Stripe.publishableKey = _stripePublishableKey;
                        print('Using Stripe Publishable Key: $_stripePublishableKey');
                    } else {
                        Stripe.publishableKey = 'YOUR_STRIPE_PUBLISHABLE_KEY';
                        print('WARNING: Using dummy Stripe Publishable Key!');
                    }
                    
                    print('Initializing Payment Sheet...');
                    await Stripe.instance.initPaymentSheet(
                      paymentSheetParameters: SetupPaymentSheetParameters(
                        paymentIntentClientSecret: clientSecret.toString(),
                        merchantDisplayName: 'Pamevent',
                        style: ThemeMode.light,
                        billingDetails: BillingDetails(
                          name: fname,
                          email: email,
                          phone: phone,
                        ),
                        allowsDelayedPaymentMethods: true,
                      ),
                    );
                    
                    print('Presenting Payment Sheet...');
                    await Stripe.instance.presentPaymentSheet();
                    print('Payment Sheet completed successfully!');
                    if (mounted) {
                        debugPrint('Stripe Payment Successful, redirecting to OrderSuccessScreen...');
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Successful!')));
                        Navigator.pushAndRemoveUntil(
                          context, 
                          MaterialPageRoute(
                            builder: (_) => OrderSuccessScreen(
                              orderId: orderId,
                              amount: finalGrandTotal,
                              eventName: _eventDetail?['title'],
                              bookingData: paymentData,
                            ),
                          ), 
                          (route) => false
                        );
                    }
                 } on StripeException catch (e) {
                    print('Stripe Exception: ${e.error}');
                    print('Stripe Exception code: ${e.error.code}');
                    print('Stripe Exception message: ${e.error.localizedMessage}');
                    if (mounted) {
                      if (e.error.code == FailureCode.Canceled) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment cancelled')));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed: ${e.error.localizedMessage}')));
                      }
                    }
                 } catch (e, stack) {
                    print('General Error during payment: $e');
                    print('Stack trace: $stack');
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                 }
              } else if (targetUrl != null && targetUrl.toString().startsWith('http')) {
                 print('Using WebView fallback for Stripe');
                 if (mounted) _showStripeModal(targetUrl.toString());
              } else {
                 if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not initialize payment. Please try again.')));
                 }
              }
          } else {
             print('Processing MONCASH payment');
             final String? paymentUrl = (paymentData['url'] ?? paymentData['redirect_url'])?.toString();
             print('MONCASH REDIRECT URL DETECTED: $paymentUrl');
             
             if (paymentUrl != null && paymentUrl.startsWith('http')) {
                if (mounted) {
                    final paymentSuccessful = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MonCashPaymentScreen(
                          paymentUrl: paymentUrl,
                          orderId: orderId,
                          amount: finalGrandTotal,
                          customerName: fname,
                          customerEmail: email,
                        ),
                      ),
                    );
                    if (mounted && paymentSuccessful == true) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderSuccessScreen(
                              orderId: orderId,
                              amount: finalGrandTotal,
                              eventName: _eventDetail?['title'],
                              bookingData: paymentData,
                            ),
                          ),
                          (route) => false,
                        );
                    }
                }
             } else {
                if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not get payment URL. Please try again.')));
                }
             }
          }
       }
     }
  }

  void _showStripeModal(String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white,
            child: _StripeModalContent(
              url: url,
              scrollController: ScrollController(),
              eventDetail: _eventDetail,
              eventId: widget.eventId,
              grandTotal: grandTotal,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventInfo() {
    final title = _eventDetail?['title'] ?? _eventDetail?['event_name'] ?? 'Event';
    final imageUrl = _eventDetail?['image'] ?? _eventDetail?['event_img'] ?? _eventDetail?['event_thumbnail'] ?? _eventDetail?['thumbnail'] ?? '';
    final startDate = _eventDetail?['start_date'] ?? _eventDetail?['event_date'] ?? '';
    final startTime = _eventDetail?['start_time'] ?? _eventDetail?['event_start_time'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CustomImage(
              resolvePublicUrl(imageUrl) ?? imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              whenEmpty: Container(
                width: 80,
                height: 80,
                color: Colors.grey[200],
                child: const Icon(Icons.image, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (startDate.isNotEmpty || startTime.isNotEmpty)
                  Text(
                    '$startDate $startTime'.trim(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalTickets = 0;
    for (var item in widget.selectedTickets) {
      totalTickets += (item['count'] as int);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF14103D),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isDesktop = constraints.maxWidth > 800;
            return SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
              child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildLeftColumn(),
                      ),
                      const SizedBox(width: 48),
                      Expanded(
                        flex: 4,
                        child: _buildRightColumn(totalTickets),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLeftColumn(),
                      const SizedBox(height: 32),
                      _buildRightColumn(totalTickets),
                    ],
                  ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isLoadingEvent)
           const Center(child: CircularProgressIndicator())
        else if (_eventDetail != null)
           _buildEventInfo(),

        const SizedBox(height: 32),
        const Text('Attendee Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (!_isLoggedIn) ...[
          GestureDetector(
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              if (AppState.loggedIn) {
                 setState(() {
                   _isLoggedIn = true;
                 });
                 _initCheckoutFlow();
              }
            },
            child: Row(
              children: const [
                Text('Log in', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                Text(' for a faster experience.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 400) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Full Name *', 'Enter Your Full Name', _nameController)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('Phone *', '+91 Phone Number', _phoneController)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Email *', 'Enter Your Email', _emailController)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('Re-Enter Email *', 'Enter Re Enter Email', _reEmailController)),
                      ],
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  _buildTextField('Full Name *', 'Enter Your Full Name', _nameController),
                  const SizedBox(height: 16),
                  _buildTextField('Phone *', '+91 Phone Number', _phoneController),
                  const SizedBox(height: 16),
                  _buildTextField('Email *', 'Enter Your Email', _emailController),
                  const SizedBox(height: 16),
                  _buildTextField('Re-Enter Email *', 'Enter Re Enter Email', _reEmailController),
                ],
              );
            }
          ),
        ] else ...[
           Text(
             'Welcome back, ${_nameController.text.isNotEmpty ? _nameController.text : (AppState.profile?.username ?? 'User')}! Your details are pre-filled.',
             style: const TextStyle(color: Colors.grey, fontSize: 14),
           ),
           const SizedBox(height: 8),
           Text(
             'Name: ${_nameController.text.isNotEmpty ? _nameController.text : (AppState.profile?.username ?? 'User')}\nEmail: ${_emailController.text.isNotEmpty ? _emailController.text : (AppState.profile?.email ?? 'N/A')}\nPhone: ${_phoneController.text.isNotEmpty ? _phoneController.text : (AppState.profile?.phone ?? '0000000000')}',
             style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5),
           ),
        ],
        
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              const Text('Success!', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('CLOUDFLARE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  Text('Privacy - Terms', style: TextStyle(fontSize: 8, color: Colors.grey.shade600)),
                ],
              )
            ],
          ),
        ),
        if (!isFreeOrder) ...[
          const SizedBox(height: 32),
          const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._hardcodedGateways.map((g) {
             return Padding(
               padding: const EdgeInsets.only(bottom: 12.0),
               child: _buildPaymentOption(g['title'], g['id'], g['icon'] as IconData),
             );
          }).toList(),
        ],
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _acceptTerms,
              onChanged: (val) {
                setState(() => _acceptTerms = val ?? false);
              },
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  'I confirm that this purchase is authorized. I accept the event\'s refund and entry policy, understand that tickets may be purchased for another attendee, and acknowledge that chargebacks are not permitted in accordance with the organizer\'s policy.\n\nBy selecting Place Order, i agree to the Pamevent Terms of Service and Refund Policy',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRightColumn(int totalTickets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Summary', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Text('Tickets Info', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
        const SizedBox(height: 16),
        ...widget.selectedTickets.map((item) {
          final ticket = item['ticket'];
          final count = item['count'];
          final title = ticket['title'] ?? ticket['name'] ?? ticket['ticket_type'] ?? 'Ticket';
          final price = double.tryParse(ticket['price']?.toString() ?? '0') ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
                Text('$count X \$${price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }).toList(),
        const Divider(height: 32),
        _buildSummaryRow('Total Tickets', '$totalTickets'),
        const SizedBox(height: 12),
        _buildSummaryRow('Ticket Price', '\$${widget.totalAmount.toStringAsFixed(2)}'),
        const SizedBox(height: 12),
        _buildSummaryRow('Subtotal', '\$${widget.totalAmount.toStringAsFixed(2)}'),
        if (currentServiceFee > 0) ...[
          const SizedBox(height: 12),
          _buildSummaryRow('Service Fee', '+ \$${currentServiceFee.toStringAsFixed(2)}'),
        ],
        if (currentProcessingFee > 0) ...[
          const SizedBox(height: 12),
          _buildSummaryRow('Processing Fee', '+ \$${currentProcessingFee.toStringAsFixed(2)}'),
        ],
        if (_couponDiscount > 0) ...[
          const SizedBox(height: 12),
          _buildSummaryRow('Coupon Discount', '- \$${_couponDiscount.toStringAsFixed(2)}'),
        ],
        if (_referralDiscount > 0) ...[
          const SizedBox(height: 12),
          _buildSummaryRow('Referral Discount', '- \$${_referralDiscount.toStringAsFixed(2)}'),
        ],
        const Divider(height: 32),
        Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
             Text('\$${grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
           ],
        ),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Coupon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: TextField(
                      controller: _couponController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.only(left: 12),
                        hintText: 'Code',
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              minimumSize: Size.zero,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            onPressed: _applyCoupon,
                            child: const Text('Apply', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Referral', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: TextField(
                      controller: _referralController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.only(left: 12),
                        hintText: 'Ref Code',
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              minimumSize: Size.zero,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            onPressed: _applyReferral,
                            child: const Text('Apply', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        CustomButton(
          title: isFreeOrder ? 'Confirm Order' : 'Proceed to Pay',
          onTap: () {
            _proceedToCheckout();
          },
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
               hintText: hint,
               hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
               border: const OutlineInputBorder(),
               contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String title, String value, IconData icon) {
    bool isSelected = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Container(
               width: 18,
               height: 18,
               decoration: BoxDecoration(
                 shape: BoxShape.circle,
                 border: Border.all(color: isSelected ? AppColors.primary : Colors.grey, width: 2),
               ),
               child: isSelected ? Center(
                 child: Container(
                   width: 10,
                   height: 10,
                   decoration: const BoxDecoration(
                     shape: BoxShape.circle,
                     color: AppColors.primary,
                   ),
                 ),
               ) : null,
            ),
            const SizedBox(width: 12),
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(color: isSelected ? AppColors.primary : Colors.black87, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
