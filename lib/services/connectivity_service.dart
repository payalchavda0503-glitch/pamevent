
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityController extends GetxController {
  var isConnected = false.obs;
  var connectionType = ''.obs;

  final Connectivity _connectivity = Connectivity();
  @override
  Future<void> onInit() async {
    super.onInit();
    _checkInitialConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      // ignore: avoid_print
      print('Connectivity check failed: $e');
    }
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    // Reset the default values
    isConnected.value = false;
    connectionType.value = 'No Connection';

    // Iterate through the results and handle each ConnectivityResult
    for (var result in results) {
      if (result == ConnectivityResult.wifi) {
        isConnected.value = true;
        connectionType.value = 'Wi-Fi';
      } else if (result == ConnectivityResult.mobile) {
        isConnected.value = true;
        connectionType.value = 'Mobile Data';
      } else if (result == ConnectivityResult.none) {
        isConnected.value = false;
        connectionType.value = 'No Connection';
      }
    }

  }



}
