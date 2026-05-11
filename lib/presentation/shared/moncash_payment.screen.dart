import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../helpers/app_colors.dart';
import '../main_layout.dart';
import '../tickets/order_success.screen.dart';

enum MonCashPaymentStatus { loading, processing, success, failed, cancelled }

class MonCashPaymentScreen extends StatefulWidget {
  final String paymentUrl;
  final String orderId;
  final double amount;
  final String customerName;
  final String customerEmail;

  const MonCashPaymentScreen({
    super.key,
    required this.paymentUrl,
    required this.orderId,
    required this.amount,
    required this.customerName,
    required this.customerEmail,
  });

  @override
  State<MonCashPaymentScreen> createState() => _MonCashPaymentScreenState();
}

class _MonCashPaymentScreenState extends State<MonCashPaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  MonCashPaymentStatus _paymentStatus = MonCashPaymentStatus.loading;
  String _paymentMessage = 'Connecting to MonCash...';
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _loadingProgress = 0.0;
              _paymentStatus = MonCashPaymentStatus.processing;
              _paymentMessage = 'Connecting to MonCash payment gateway...';
            });
          },
          onProgress: (progress) {
            setState(() {
              _loadingProgress = progress / 100;
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
            });
            _checkPaymentCompletion(url);
          },
          onNavigationRequest: (request) {
            final url = request.url.toLowerCase();
            // If we already detected success, don't allow further navigation 
            // to things like the homepage of the website
            if (_paymentStatus == MonCashPaymentStatus.success) {
              debugPrint('Blocking navigation after success: ${request.url}');
              return NavigationDecision.prevent;
            }
            
            // Also check if the URL itself looks like a success redirect
            if (url.contains('success') || url.contains('completed') || url.contains('booking_complate')) {
               debugPrint('Success detected in navigation request: ${request.url}');
               _handlePaymentSuccess();
               return NavigationDecision.navigate;
            }
            
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkPaymentCompletion(String url) {
    debugPrint('MonCash WebView URL: $url');
    final lowerUrl = url.toLowerCase();
    
    // Check for success keywords
    if (lowerUrl.contains('success') || 
        lowerUrl.contains('completed') || 
        lowerUrl.contains('payment_success') ||
        lowerUrl.contains('order_complete') ||
        lowerUrl.contains('transaction_success') ||
        lowerUrl.contains('booking_complate')) {
      debugPrint('Success detected in URL: $url');
      _handlePaymentSuccess();
    } else if (lowerUrl.contains('cancel') || 
               lowerUrl.contains('failed') || 
               lowerUrl.contains('error') ||
               lowerUrl.contains('payment_cancelled')) {
      debugPrint('Failure/Cancel detected in URL: $url');
      _handlePaymentCancelled();
    }
  }

  void _handlePaymentSuccess() {
    if (_paymentStatus != MonCashPaymentStatus.success) {
      debugPrint('Handling Payment Success...');
      setState(() {
        _paymentStatus = MonCashPaymentStatus.success;
        _paymentMessage = 'Payment Successful!';
      });
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          debugPrint('Returning true for successful payment...');
          Navigator.pop(context, true);
        }
      });
    }
  }

  void _handlePaymentCancelled() {
    if (_paymentStatus != MonCashPaymentStatus.cancelled && 
        _paymentStatus != MonCashPaymentStatus.failed) {
      setState(() {
        _paymentStatus = MonCashPaymentStatus.cancelled;
        _paymentMessage = 'Payment Cancelled';
      });
    }
  }

  void _handlePaymentFailed(String reason) {
    setState(() {
      _paymentStatus = MonCashPaymentStatus.failed;
      _paymentMessage = reason.isNotEmpty ? reason : 'Payment Failed';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'MonCash Payment',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE31837),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showCloseDialog(),
        ),
        actions: [
          if (_paymentStatus == MonCashPaymentStatus.processing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildPaymentHeader(),
          if (_isLoading || _paymentStatus != MonCashPaymentStatus.processing)
            _buildStatusOverlay(),
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: _loadingProgress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE31837)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE31837).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: Color(0xFFE31837),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${widget.orderId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.darkGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.customerEmail,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE31837),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '\$${widget.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOverlay() {
    if (_paymentStatus == MonCashPaymentStatus.processing) {
      return const SizedBox.shrink();
    }

    Color backgroundColor;
    Color iconColor;
    IconData icon;
    String title;

    switch (_paymentStatus) {
      case MonCashPaymentStatus.success:
        backgroundColor = const Color(0xFFE8F5E9);
        iconColor = const Color(0xFF4CAF50);
        icon = Icons.check_circle;
        title = 'Success!';
        break;
      case MonCashPaymentStatus.cancelled:
        backgroundColor = const Color(0xFFFFF3E0);
        iconColor = const Color(0xFFFF9800);
        icon = Icons.cancel;
        title = 'Cancelled';
        break;
      case MonCashPaymentStatus.failed:
        backgroundColor = const Color(0xFFFFEBEE);
        iconColor = const Color(0xFFF44336);
        icon = Icons.error;
        title = 'Failed';
        break;
      default:
        backgroundColor = Colors.white;
        iconColor = Colors.grey;
        icon = Icons.hourglass_empty;
        title = 'Processing';
    }

    return Container(
      color: backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_paymentStatus == MonCashPaymentStatus.success ||
                _paymentStatus == MonCashPaymentStatus.cancelled ||
                _paymentStatus == MonCashPaymentStatus.failed) ...[
              Icon(icon, color: iconColor, size: 64),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _paymentMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_paymentStatus == MonCashPaymentStatus.cancelled ||
                  _paymentStatus == MonCashPaymentStatus.failed)
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Return to Checkout'),
                ),
            ] else ...[
              const CircularProgressIndicator(color: Color(0xFFE31837)),
              const SizedBox(height: 16),
              Text(
                _paymentMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCloseDialog() {
    if (_paymentStatus == MonCashPaymentStatus.processing) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel Payment?'),
          content: const Text(
            'Are you sure you want to cancel the MonCash payment? '
            'You will need to start the checkout process again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue Payment'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, false);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cancel Payment'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context, false);
    }
  }
}

class MonCashPaymentResult {
  final bool success;
  final String? transactionId;
  final String? message;
  final String? orderId;

  MonCashPaymentResult({
    required this.success,
    this.transactionId,
    this.message,
    this.orderId,
  });

  factory MonCashPaymentResult.fromUrl(String url, Map<String, dynamic>? extraData) {
    final uri = Uri.parse(url);
    final params = uri.queryParameters;

    bool isSuccess = url.toLowerCase().contains('success') ||
        url.toLowerCase().contains('completed');

    return MonCashPaymentResult(
      success: isSuccess,
      transactionId: params['transaction_id'] ?? params['txn_id'] ?? params['reference'],
      message: params['message'] ?? params['status'],
      orderId: extraData?['order_id']?.toString(),
    );
  }
}