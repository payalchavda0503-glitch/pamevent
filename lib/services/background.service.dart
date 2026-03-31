import 'dart:async';

import '../api/api.client.dart';
import '../enums/pref_keys.dart';
import '../helpers/app_state.dart';

class BackgroundService {
  static Timer? _timer;
  static bool _isSyncing = false;
  static bool isInForeground = true;

  static Future<void> startBackgroundTask() async {
    isInForeground = false;
    await _syncToServer();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (_isSyncing) return;
      _isSyncing = true;
      try {
        await _syncToServer();
      } finally {
        _isSyncing = false;
      }
    });
  }

  static void stopBackgroundTask() {
    isInForeground = true;
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> _syncToServer() async {
    final allKeys = AppState.prefs.getKeys();

    // Filter all ticket and barcode queues
    final ticketKeys = allKeys.where((key) => key.startsWith(PrefKeys.queue.key));
    final barcodeKeys = allKeys.where((key) => key.startsWith(PrefKeys.barcodeQueue.key));

    // Combine all relevant event IDs
    final allEventIds = <int>{
      ...ticketKeys.map((k) => int.tryParse(k.split('_').last)).whereType<int>(),
      ...barcodeKeys.map((k) => int.tryParse(k.split('_').last)).whereType<int>(),
    };

    final results = <bool>{};

    for (final eventId in allEventIds) {
      final ticketKey = '${PrefKeys.queue.key}_$eventId';
      final barcodeKey = '${PrefKeys.barcodeQueue.key}_$eventId';

      final ticketQueue = AppState.prefs.getStringList(ticketKey) ?? [];
      final barcodeQueue = AppState.prefs.getStringList(barcodeKey) ?? [];

      if (ticketQueue.isEmpty && barcodeQueue.isEmpty) continue;

      final res = await ApiClient.syncTickets(eventId, ticketQueue, barcodeQueue);
      results.add(res);

      if (res) {
        if (ticketQueue.isNotEmpty) await AppState.prefs.remove(ticketKey);
        if (barcodeQueue.isNotEmpty) await AppState.prefs.remove(barcodeKey);
      }
    }

    if (!results.contains(false)) stopBackgroundTask();
  }

}
