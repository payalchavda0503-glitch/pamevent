import 'package:flutter/widgets.dart' show VoidCallback, WidgetsBinding;
import 'package:intl/intl.dart';

void asap(VoidCallback callback) {
  WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
    callback();
  });
}

String formatEventDate(String dateStr) {
  if (dateStr.isEmpty) return '';
  try {
    // Expected input format: yyyy-MM-dd
    DateTime dateTime = DateTime.parse(dateStr);
    
    String day = DateFormat('d').format(dateTime);
    String suffix = 'th';
    int dayInt = int.parse(day);
    
    if (dayInt >= 11 && dayInt <= 13) {
      suffix = 'th';
    } else {
      switch (dayInt % 10) {
        case 1: suffix = 'st'; break;
        case 2: suffix = 'nd'; break;
        case 3: suffix = 'rd'; break;
        default: suffix = 'th';
      }
    }
    
    // Format: Mon, 18th May 2026
    String formattedDate = DateFormat('EEE, ').format(dateTime) + 
                          day + suffix + 
                          DateFormat(' MMM yyyy').format(dateTime);
    return formattedDate;
  } catch (e) {
    return dateStr; // Return original if parsing fails
  }
}
