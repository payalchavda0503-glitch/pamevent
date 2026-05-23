import 'package:flutter/material.dart';
import 'dart:convert';
import '../../api/api.client.dart';
import '../../helpers/app_colors.dart';
import '../../helpers/app_state.dart';
import '../../helpers/public_url.dart';
import '../../helpers/utils.dart';
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
                    displayId: widget.eventDetail?['booking_id']?.toString() ?? widget.eventId.toString(),
                    eventId: widget.eventId.toString(),
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
                    displayId: widget.eventDetail?['booking_id']?.toString() ?? widget.eventId.toString(),
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
  final List<dynamic>? gateways;

  const CheckoutScreen({
    super.key,
    required this.eventId,
    required this.selectedTickets,
    required this.totalAmount,
    this.serviceFee = 0.0,
    this.processingFee = 0.0,
    this.gateways,
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
  bool _isSubmitting = false;
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

  List<Map<String, dynamic>> _hardcodedGateways = [];

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
    // _initCheckoutFlow call will be handled inside _fetchEventDetail or after it
  }

  bool get isFreeOrder => widget.totalAmount <= 0;

  double get currentServiceFee {
    if (isFreeOrder) return 0.0;
    // Base service fee from previous screen, rounded to 2 decimal places
    return double.parse(widget.serviceFee.toStringAsFixed(2));
  }

  double get currentProcessingFee {
    if (isFreeOrder) return 0.0;
    
    // Find selected gateway to get its fee config
    final selectedGateway = _hardcodedGateways.firstWhere(
      (g) => g['id'] == _selectedPaymentMethod,
      orElse: () => {},
    );

    double feePerc = 0.0;
    double feeCents = 0.0;

    if (selectedGateway.isNotEmpty) {
      feePerc = double.tryParse(selectedGateway['fee']?.toString() ?? '0') ?? 0.0;
      feeCents = double.tryParse(selectedGateway['fee_cents']?.toString() ?? '0') ?? 0.0;
    }
    
    // Subtotal for processing fee calculation (includes base service fee)
    final double subtotal = widget.totalAmount + currentServiceFee - _couponDiscount - _referralDiscount;
    final double percAmount = (subtotal / 100) * feePerc;
    final totalFee = percAmount + feeCents;
    
    final roundedFee = double.parse(totalFee.toStringAsFixed(2));
    debugPrint('DEBUG: Selected Gateway: ${_selectedPaymentMethod}, Subtotal: $subtotal, FeePerc: $feePerc, FeeCents: $feeCents, Calculated Processing Fee: $totalFee, Rounded: $roundedFee');
    
    return roundedFee;
  }

  double get grandTotal {
    final total = widget.totalAmount + currentServiceFee + currentProcessingFee - _couponDiscount - _referralDiscount;
    return double.parse(total.toStringAsFixed(2));
  }

  Future<void> _fetchEventDetail() async {
    final data = await ApiClient.getCustomerEventDetail(widget.eventId);
    if (mounted) {
      setState(() {
        _eventDetail = data;
        _isLoadingEvent = false;
        
        // Extract gateways from widget.gateways or settings if available
        List<dynamic> gateways = [];
        if (widget.gateways != null && widget.gateways!.isNotEmpty) {
          gateways = widget.gateways!;
        } else if (data != null && data['settings'] != null && data['settings']['online_gateways'] is List) {
          gateways = data['settings']['online_gateways'];
        }

        if (gateways.isNotEmpty) {
           // Filter out duplicates (only keep items that have an ID and unique keywords)
           final Map<String, Map<String, dynamic>> uniqueGateways = {};
           for (var g in gateways) {
             if (g is! Map) continue;
             final id = g['id']?.toString() ?? '';
             final keyword = g['keyword']?.toString().toLowerCase() ?? '';
             if (id.isNotEmpty && keyword.isNotEmpty && !uniqueGateways.containsKey(keyword)) {
                uniqueGateways[keyword] = Map<String, dynamic>.from(g);
             }
           }

           _hardcodedGateways = uniqueGateways.values.map((g) {
             final name = g['name']?.toString() ?? 'Payment';
             final keyword = g['keyword']?.toString().toLowerCase() ?? '';
             final iconPath = g['icon']?.toString() ?? '';
             
             // Use full URL if provided, otherwise construct it
             String iconUrl = '';
             if (iconPath.isNotEmpty) {
               if (iconPath.startsWith('http')) {
                 iconUrl = iconPath;
               } else {
                 // Updated folder name from payment-gateway to payment_gateway as per API snippet
                 iconUrl = 'https://pamevent.com/assets/admin/img/payment_gateway/$iconPath';
               }
             }
             
             debugPrint('DEBUG: Gateway Icon URL for $name: $iconUrl');
             
             return {
               'id': g['id']?.toString() ?? '',
               'title': name,
               'keyword': keyword,
               'icon_url': iconUrl,
               'fee': g['fee'],
               'fee_cents': g['fee_cents'],
               'service_fee': g['service_fee'],
               'service_fee_cents': g['service_fee_cents'],
               'information': g['information'],
             };
           }).toList();

           // Set initial selected method to first available or stripe
           if (_hardcodedGateways.isNotEmpty) {
             final stripeGw = _hardcodedGateways.firstWhere((g) => g['keyword'] == 'stripe', orElse: () => _hardcodedGateways.first);
             final moncashGw = _hardcodedGateways.firstWhere((g) => g['keyword'] == 'moncash', orElse: () => {});
             
             _selectedPaymentMethod = stripeGw['id'];
             _stripeId = stripeGw['id'];
             if (moncashGw.isNotEmpty) {
               _moncashId = moncashGw['id'];
             }
             
             // Handle Stripe Key initialization from settings
             final info = stripeGw['information'];
             if (info != null) {
                try {
                  Map<String, dynamic> infoMap = {};
                  if (info is String) {
                    infoMap = jsonDecode(info);
                  } else if (info is Map) {
                    infoMap = Map<String, dynamic>.from(info);
                  }
                  
                  final pKey = infoMap['key']?.toString() ?? infoMap['publishable_key']?.toString();
                  if (pKey != null && pKey.isNotEmpty) {
                    _stripePublishableKey = pKey;
                    Stripe.publishableKey = _stripePublishableKey;
                    Stripe.instance.applySettings();
                    debugPrint('DEBUG: Stripe.publishableKey initialized: $pKey');
                  }
                } catch (e) {
                  debugPrint('Error parsing stripe info: $e');
                }
             }
           }
        }
      });
      _initCheckoutFlow();
    }
  }

  double _stripeFeePerc = 0.0;
  double _stripeFeeCents = 0.0;
  double _moncashFeePerc = 0.0;
  double _moncashFeeCents = 0.0;

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
    
    final String? firstTicketId = widget.selectedTickets.isNotEmpty 
          ? (widget.selectedTickets.first['ticket']['id'] ?? widget.selectedTickets.first['ticket']['ticket_id'])?.toString() 
          : null;
      final String firstTicketQty = widget.selectedTickets.isNotEmpty 
          ? widget.selectedTickets.first['count'].toString() 
          : '1';
      final String firstTicketPrice = widget.selectedTickets.isNotEmpty 
           ? (widget.selectedTickets.first['ticket']['price'] ?? '0').toString() 
           : '0';
       final String firstTicketName = widget.selectedTickets.isNotEmpty 
           ? (widget.selectedTickets.first['ticket']['title'] ?? widget.selectedTickets.first['ticket']['name'] ?? 'Ticket').toString() 
           : 'Ticket';
       await ApiClient.customerAddToCart(widget.eventId, ticketId: firstTicketId, qty: firstTicketQty, price: firstTicketPrice, name: firstTicketName);
    
    final gatewaysData = await ApiClient.customerGetPaymentGateways();
    print('GET GATEWAYS RESPONSE: $gatewaysData');
    if (mounted && gatewaysData != null) {
       final dynamic rawData = gatewaysData['data'];
       List<dynamic> gwData = [];
       
       if (rawData is List) {
         gwData = rawData;
       } else if (rawData is Map && rawData['online_gateways'] is List) {
         gwData = rawData['online_gateways'];
       }

       for (var gw in gwData) {
          final title = gw['name']?.toString().toLowerCase() ?? '';
          final gwId = gw['id']?.toString() ?? gw['gateway_id']?.toString() ?? '';
          final fee = double.tryParse(gw['fee']?.toString() ?? '0') ?? 0.0;
          final feeCents = double.tryParse(gw['fee_cents']?.toString() ?? '0') ?? 0.0;
          
          print('Parsing Gateway - Title: $title, ID: $gwId, Fee: $fee, FeeCents: $feeCents');

          // CRITICAL: Update _hardcodedGateways with the most accurate fee data and ID from the specific gateways API
          if (mounted) {
            setState(() {
              final index = _hardcodedGateways.indexWhere((g) => 
                title.contains(g['keyword'].toString().toLowerCase()) || 
                g['keyword'].toString().toLowerCase().contains(title)
              );
              
              if (index != -1) {
                final oldId = _hardcodedGateways[index]['id'];
                _hardcodedGateways[index]['id'] = gwId;
                _hardcodedGateways[index]['fee'] = fee;
                _hardcodedGateways[index]['fee_cents'] = feeCents;
                
                if (_selectedPaymentMethod == oldId) {
                  _selectedPaymentMethod = gwId;
                }
                
                // Also update service fee if this API provides it
                if (gw['service_fee'] != null) {
                  _hardcodedGateways[index]['service_fee'] = gw['service_fee'];
                }
                if (gw['service_fee_cents'] != null) {
                  _hardcodedGateways[index]['service_fee_cents'] = gw['service_fee_cents'];
                }
                debugPrint('DEBUG: Updated Gateway ${_hardcodedGateways[index]['keyword']} ID from $oldId to $gwId in _hardcodedGateways');
              }
            });
          }
          
          if (title.contains('stripe') || title.contains('card') || title.contains('credit')) {
              _stripeId = gwId;
              _stripeFeePerc = fee;
              _stripeFeeCents = feeCents;
              
              final gwString = gw.toString();
              final regExp = RegExp(r'(pk_test_[a-zA-Z0-9]+|pk_live_[a-zA-Z0-9]+)');
              final match = regExp.firstMatch(gwString);
              if (match != null && _stripePublishableKey.isEmpty) {
                   _stripePublishableKey = match.group(0) ?? '';
                   Stripe.publishableKey = _stripePublishableKey;
                   await Stripe.instance.applySettings();
              }
          }
          if (title.contains('moncash') || title.contains('mon cash')) {
              _moncashId = gwId;
              _moncashFeePerc = fee;
              _moncashFeeCents = feeCents;
              print('FOUND MONCASH GATEWAY ID: $_moncashId');
          }
       }
       
       print('RESOLVED GATEWAYS - Stripe ID: $_stripeId (Key: $_stripePublishableKey), Moncash ID: $_moncashId');
       
       // Note: _hardcodedGateways is now populated from _fetchEventDetail 
       // to include icons and dynamic fees from settings.
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
     if (_isSubmitting) return;
     
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

     if (fname.isEmpty || email.isEmpty || phone.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required attendee details')));
         return;
     }
     if (!isFreeOrder && _selectedPaymentMethod.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a payment method')));
         return;
     }
     if (!_acceptTerms) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please accept the terms to proceed')));
         return;
     }

     setState(() => _isSubmitting = true);
     AppState.showLoader();

     try {
       // 1. Get Booking ID first from API
       final String? orderId = await ApiClient.getBookingId();
       if (orderId == null) {
         AppState.hideLoader();
         setState(() => _isSubmitting = false);
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not generate booking ID. Please try again.')));
         return;
       }
       debugPrint('DEBUG: Generated Booking ID from API: $orderId');

       double finalProcessingFee = currentProcessingFee;
       double finalServiceFee = currentServiceFee;
       double finalSubTotal = widget.totalAmount;
       double totalToPay = grandTotal;
       
       double payloadGrandTotal = finalSubTotal + finalServiceFee - _couponDiscount - _referralDiscount;
       payloadGrandTotal = double.parse(payloadGrandTotal.toStringAsFixed(2));

       final String processingFeeStr = finalProcessingFee.toStringAsFixed(2);
       final String serviceFeeStr = finalServiceFee.toStringAsFixed(2);

       String finalGateway = isFreeOrder ? 'free' : (_selectedPaymentMethod == _stripeId ? 'stripe' : 'moncash');

       // Get gateway information to pass to checkout/payment intent
       Map<String, dynamic>? selectedGatewayInfo;
       final selectedGw = _hardcodedGateways.firstWhere(
         (g) => g['id'] == _selectedPaymentMethod,
         orElse: () => {},
       );
       if (selectedGw.isNotEmpty && selectedGw['information'] != null) {
         final info = selectedGw['information'];
         if (info is Map) {
           selectedGatewayInfo = Map<String, dynamic>.from(info);
         } else if (info is String) {
           try {
             selectedGatewayInfo = jsonDecode(info);
           } catch (e) {
             debugPrint('Error decoding gateway info: $e');
           }
         }
       }

       final map = <String, dynamic>{
           'booking_id': orderId, 
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
           'processing_fee': processingFeeStr,
           'service_fee': serviceFeeStr,
           'ticket_fees': serviceFeeStr, // Keeping both for compatibility
           'coupon': _couponController.text.isEmpty ? '0' : _couponController.text,
           'referral_code': _referralController.text.isEmpty ? '0' : _referralController.text,
           'admin_coupon_discount': _couponDiscount.toStringAsFixed(2),
           'referral_discount': _referralDiscount.toStringAsFixed(2),
           'attendee_discount': '0',
           'event_date': _eventDetail?['start_date'] ?? '',
           'event_start_time': _eventDetail?['start_time'] ?? '',
           'tax': '0',
           'discount': '0',
           'total_early_bird_discount': '0',
           'sub_total': finalSubTotal.toStringAsFixed(2),
           'grand_total': totalToPay.toStringAsFixed(2),
           'ticket_id': widget.selectedTickets.isNotEmpty ? (widget.selectedTickets.first['ticket']['id'] ?? widget.selectedTickets.first['ticket']['ticket_id']).toString() : '',
           'tickets_id': widget.selectedTickets.isNotEmpty ? (widget.selectedTickets.first['ticket']['id'] ?? widget.selectedTickets.first['ticket']['ticket_id']).toString() : '',
           'ticket_ids': widget.selectedTickets.map((e) => (e['ticket']['id'] ?? e['ticket']['ticket_id']).toString()).toList(),
       };

       // Add gateway credentials to payload if available
       if (selectedGatewayInfo != null) {
         selectedGatewayInfo.forEach((key, value) {
           map['gateway_info[$key]'] = value.toString();
         });
       }

       for (int i = 0; i < widget.selectedTickets.length; i++) {
          final t = widget.selectedTickets[i]['ticket'];
          final count = widget.selectedTickets[i]['count'];
          final tId = (t['id'] ?? t['ticket_id'] ?? '').toString();
          final title = (t['title'] ?? t['name'] ?? 'Ticket').toString();
          final price = (t['price'] ?? '0').toString();

          map['selTickets[$i][ticket_id]'] = tId;
          map['selTickets[$i][tickets_id]'] = tId; // Adding plural key inside array just in case
          map['selTickets[$i][id]'] = tId; 
          map['selTickets[$i][early_bird_discount]'] = '0';
          map['selTickets[$i][name]'] = title;
          map['selTickets[$i][qty]'] = count.toString();
          map['selTickets[$i][price]'] = price;
          map['selTickets[$i][max_ticket_redemption]'] = '1';
          map['selTickets[$i][absorb_fee_tickets]'] = '0';
          map['selTickets[$i][qty_ticket_per_table]'] = '1';
       }

       if (isFreeOrder) {
         final res = await ApiClient.customerCheckout(map);
         if (res != null && res['status'] == 100) {
           final String? internalId = _extractInternalIdFromResponse(res);
           final String? displayBookingId = _extractDisplayBookingIdFromResponse(res);
           if (mounted) {
             AppState.hideLoader();
             Navigator.pushAndRemoveUntil(
               context,
               MaterialPageRoute(
                 builder: (_) => OrderSuccessScreen(
                   orderId: internalId ?? orderId,
                   displayId: displayBookingId ?? orderId,
                   eventId: widget.eventId.toString(),
                   amount: totalToPay,
                   eventName: _eventDetail?['title'],
                   bookingData: res['data'],
                 ),
               ),
               (route) => false,
             );
           }
         } else {
            if (mounted) {
              AppState.hideLoader();
              setState(() => _isSubmitting = false);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res?['message'] ?? 'Checkout failed')));
            }
         }
       } else {
         if (_selectedPaymentMethod == _stripeId) {
             final piRes = await ApiClient.createPaymentIntent(
               amount: totalToPay,
               currency: 'USD',
               bookingId: orderId,
               description: 'Tickets for ${_eventDetail?['title'] ?? 'Event'}',
               eventId: widget.eventId.toString(),
               gatewayInfo: selectedGatewayInfo,
             );
             
             if (piRes != null) {
               final clientSecret = piRes['client_secret']?.toString() ?? 
                                  piRes['stripe_secret']?.toString() ?? 
                                  (piRes['data'] is Map ? (piRes['data']['client_secret']?.toString() ?? piRes['data']['stripe_secret']?.toString()) : null);
               
               // Use Stripe Publishable Key from the API (Event Details -> Gateway Settings)
               // Priority: 1. Payment Intent Response, 2. Event Detail Settings
               final publishableKey = piRes['stripe_key']?.toString() ?? 
                                     piRes['publishable_key']?.toString() ?? 
                                     _stripePublishableKey;

               if (clientSecret != null && clientSecret.isNotEmpty) {
                  if (publishableKey.isEmpty) {
                    AppState.hideLoader();
                    setState(() => _isSubmitting = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Stripe configuration missing. Please contact support.'))
                      );
                    }
                    return;
                  }

                  try {
                     Stripe.publishableKey = publishableKey;
                     await Stripe.instance.applySettings();
                     debugPrint('DEBUG: Using Stripe Publishable Key: $publishableKey');
                     
                     await Stripe.instance.initPaymentSheet(
                      
                       paymentSheetParameters: SetupPaymentSheetParameters(
                         paymentIntentClientSecret: clientSecret,
                         merchantDisplayName: 'Pamevent',
                         style: ThemeMode.light,
                         billingDetails: BillingDetails(name: fname, email: email, phone: phone),
                       ),
                     );
                     
                     AppState.hideLoader();
                     await Stripe.instance.presentPaymentSheet();
                     
                     AppState.showLoader();
                     final checkoutRes = await ApiClient.customerCheckout(map);
                     
                     if (checkoutRes != null && checkoutRes['status'] == 100) {
                        final String? internalId = _extractInternalIdFromResponse(checkoutRes);
                        final String? displayBookingId = _extractDisplayBookingIdFromResponse(checkoutRes);
                        if (mounted) {
                            AppState.hideLoader();
                            Navigator.pushAndRemoveUntil(
                              context, 
                              MaterialPageRoute(
                                builder: (_) => OrderSuccessScreen(
                                  orderId: internalId ?? orderId,
                                  displayId: displayBookingId ?? orderId,
                                  eventId: widget.eventId.toString(),
                                  amount: totalToPay,
                                  eventName: _eventDetail?['title'],
                                  bookingData: checkoutRes['data'],
                                ),
                              ), 
                              (route) => false
                            );
                        }
                     } else {
                        AppState.hideLoader();
                        setState(() => _isSubmitting = false);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(checkoutRes?['message'] ?? 'Payment successful but checkout failed.')));
                     }
                     return; 
                  } on StripeException catch (e) {
                     AppState.hideLoader();
                     setState(() => _isSubmitting = false);
                     if (e.error.code == FailureCode.Canceled) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment cancelled')));
                     } else {
                        if (mounted) {
                          showDialog(
                             context: context,
                             builder: (context) => AlertDialog(
                               title: const Text('Stripe Error'),
                               content: Text(e.error.localizedMessage ?? 'An unknown Stripe error occurred.'),
                               actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                             ),
                           );
                        }
                     }
                     return;
                  } catch (e) {
                     AppState.hideLoader();
                     setState(() => _isSubmitting = false);
                     if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Error: $e')));
                     return;
                  }
               }
             }
             
             AppState.hideLoader();
             setState(() => _isSubmitting = false);
             if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not initialize Stripe. Please try again.')));
             
         } else {
            // REDIRECT PAYMENT FLOW (MonCash)
            // 1. Get Payment URL from moncashPaymentUrl API using same payload as checkout
            final piRes = await ApiClient.getMonCashPaymentUrl(map);

            if (piRes != null) {
               final paymentData = piRes['data'] is Map ? piRes['data'] : piRes;
               final String? paymentUrl = (paymentData['url'] ?? paymentData['redirect_url'])?.toString();
               
               AppState.hideLoader();
               
               if (paymentUrl != null && paymentUrl.startsWith('http')) {
                  if (mounted) {
                      final paymentResult = await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MonCashPaymentScreen(
                            paymentUrl: paymentUrl,
                            orderId: orderId,
                            amount: totalToPay,
                            customerName: fname,
                            customerEmail: email,
                          ),
                        ),
                      );
                      
                      if (mounted) {
                        if (paymentResult != null && paymentResult['success'] == true) {
                          // 2. Call checkout API ONLY after payment is successful
                          // Pass moncash_order_id and transactionId from WebView
                          AppState.showLoader();
                          
                          final finalCheckoutMap = Map<String, dynamic>.from(map);
                          if (paymentResult['moncash_order_id'] != null) {
                            finalCheckoutMap['moncash_order_id'] = paymentResult['moncash_order_id'];
                          }
                          if (paymentResult['transactionId'] != null) {
                            finalCheckoutMap['transactionId'] = paymentResult['transactionId'];
                          }

                          final checkoutRes = await ApiClient.customerCheckout(finalCheckoutMap);
                          
                          if (checkoutRes != null && checkoutRes['status'] == 100) {
                            final String? internalId = _extractInternalIdFromResponse(checkoutRes);
                            final String? displayBookingId = _extractDisplayBookingIdFromResponse(checkoutRes);
                            AppState.hideLoader();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderSuccessScreen(
                                  orderId: internalId ?? orderId,
                                  displayId: displayBookingId ?? orderId,
                                  eventId: widget.eventId.toString(),
                                  amount: totalToPay,
                                  eventName: _eventDetail?['title'],
                                  bookingData: checkoutRes['data'] ?? checkoutRes,
                                ),
                              ),
                              (route) => false,
                            );
                          } else {
                            AppState.hideLoader();
                            setState(() => _isSubmitting = false);
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(checkoutRes?['message'] ?? 'Payment successful but checkout failed.')));
                          }
                        } else {
                          // Payment was cancelled or failed in WebView
                          setState(() => _isSubmitting = false);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment cancelled or failed.')));
                        }
                      }
                  }
               } else {
                  setState(() => _isSubmitting = false);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not get payment URL.')));
               }
            } else {
               AppState.hideLoader();
               setState(() => _isSubmitting = false);
            }
         }
       }
     } catch (e) {
        AppState.hideLoader();
        setState(() => _isSubmitting = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
     }
  }

  String? _extractInternalIdFromResponse(Map<String, dynamic> res) {
    try {
      final data = res['data'] is Map ? res['data'] : res;
      
      // Numeric ID for API (booking_info['id'])
      if (data['booking_info'] is Map) {
        return data['booking_info']['id']?.toString();
      }
      
      if (data['booking_info'] is List && (data['booking_info'] as List).isNotEmpty) {
        return data['booking_info'][0]['id']?.toString();
      }
      
      return data['id']?.toString() ?? res['id']?.toString();
    } catch (e) {
      debugPrint('Error extracting internal ID: $e');
      return null;
    }
  }

  String? _extractDisplayBookingIdFromResponse(Map<String, dynamic> res) {
    try {
      final data = res['data'] is Map ? res['data'] : res;
      
      // Alphanumeric ID for UI (booking_info['booking_id'])
      if (data['booking_info'] is Map) {
        return data['booking_info']['booking_id']?.toString();
      }
      
      if (data['booking_info'] is List && (data['booking_info'] as List).isNotEmpty) {
        return data['booking_info'][0]['booking_id']?.toString();
      }
      
      return data['booking_id']?.toString() ?? res['booking_id']?.toString();
    } catch (e) {
      debugPrint('Error extracting display booking ID: $e');
      return null;
    }
  }

  void _showStripeBottomSheet(String url) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle/Indicator
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: _StripeModalContent(
                  url: url,
                  scrollController: ScrollController(),
                  eventDetail: _eventDetail,
                  eventId: widget.eventId,
                  grandTotal: grandTotal,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStripeModal(String url) {
    // This is the old full-screen dialog, keeping it as backup or for specific cases
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
    final imageUrl = _eventDetail?['event_thumbnail_url'] ?? 
                    resolvePublicUrl(_eventDetail?['event_thumbnail'] ?? _eventDetail?['image'] ?? _eventDetail?['event_img']) ?? 
                    '';
    
    final location = _eventDetail?['event_address'] ?? 
                    '${_eventDetail?['city'] ?? ''}, ${_eventDetail?['country'] ?? ''}'.trim().replaceAll(RegExp(r'^, |, $'), '') ?? 
                    _eventDetail?['venue'] ?? 
                    'Online';
    
    final organizer = _eventDetail?['organizer'] is Map 
        ? (_eventDetail?['organizer']['username'] ?? 'Unknown')
        : (_eventDetail?['organizer_name'] ?? 'Unknown');
    
    final date = (() {
      String d = _eventDetail?['event_date']?.toString() ?? _eventDetail?['start_date']?.toString() ?? '';
      String t = _eventDetail?['event_start_time']?.toString() ?? _eventDetail?['start_time']?.toString() ?? '';
      
      if (d.isEmpty && _eventDetail?['date_type'] == 'multiple' && _eventDetail?['multiple_dates'] is List && (_eventDetail?['multiple_dates'] as List).isNotEmpty) {
        final firstDate = (_eventDetail?['multiple_dates'] as List).first;
        d = firstDate['event_date']?.toString() ?? firstDate['start_date']?.toString() ?? '';
        t = firstDate['event_start_time']?.toString() ?? firstDate['start_time']?.toString() ?? '';
      }
      String formattedDate = formatShortEventDate(d);
      return formattedDate.isNotEmpty ? '$formattedDate / $t' : '';
    })();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CustomImage(
              imageUrl,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              whenEmpty: Container(
                width: 120,
                height: 120,
                color: AppColors.lightGrey,
                child: const Icon(Icons.image_not_supported, color: AppColors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: AppColors.darkGrey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(fontSize: 13, color: AppColors.darkGrey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: AppColors.darkGrey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'By $organizer',
                        style: const TextStyle(fontSize: 12, color: AppColors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(fontSize: 13, color: AppColors.darkGrey),
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
        if (!_isLoggedIn)
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginScreen(
                    onLoginSuccess: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              );
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
          )
        else
          Text(
            'Welcome back, ${_nameController.text.isNotEmpty ? _nameController.text : (AppState.profile?.username ?? 'User')}! Your details are pre-filled.',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
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
        
        const SizedBox(height: 24),
        if (!isFreeOrder) ...[
          const SizedBox(height: 32),
          const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._hardcodedGateways.map((g) {
             return Padding(
               padding: const EdgeInsets.only(bottom: 12.0),
               child: _buildPaymentOption(
                 g['title'], 
                 g['id'], 
                 iconUrl: g['icon_url'],
                 icon: g['keyword'] == 'stripe' ? Icons.credit_card : Icons.money
               ),
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

  Widget _buildPaymentOption(String title, String value, {String? iconUrl, IconData? icon}) {
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
            if (iconUrl != null && iconUrl.isNotEmpty)
              CustomImage(iconUrl, width: 24, height: 24, fit: BoxFit.contain)
            else if (icon != null)
              Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(color: isSelected ? AppColors.primary : Colors.black87, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
