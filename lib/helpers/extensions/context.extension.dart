import 'package:flutter/material.dart';

extension MediaQueryExtension on BuildContext {
  bool get isMobile => MediaQuery.sizeOf(this).width < 600;
}

extension NavigatorExtension on BuildContext {
  NavigatorState get _ => Navigator.of(this);
  NavigatorState get root => Navigator.of(this, rootNavigator: true);

  void pop<T>({
    T? value,
    bool rootNav = false, //
  }) {
    return (rootNav ? root : _).pop<T>(value);
  }

  Future<T?> push<T>(
    Widget screen, {
    bool rootNav = false, //
  }) async {
    return await (rootNav ? root : _).push<T>(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Future<T?> replace<T, TO>(
    Widget screen, {
    TO? result,
    bool rootNav = false,
  }) async {
    return await (rootNav ? root : _).pushReplacement<T, TO>(
      MaterialPageRoute(builder: (context) => screen),
      result: result,
    );
  }

  Future<T?> replaceAll<T>(
    Widget screen, {
    bool rootNav = false, //
  }) async {
    return await (rootNav ? root : _).pushAndRemoveUntil<T>(
      MaterialPageRoute(builder: (context) => screen),
      (route) => false,
    );
  }
}
