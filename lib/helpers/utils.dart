import 'package:flutter/widgets.dart' show VoidCallback, WidgetsBinding;

void asap(VoidCallback callback) {
  WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
    callback();
  });
}
