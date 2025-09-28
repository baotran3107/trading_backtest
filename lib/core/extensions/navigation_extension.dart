import 'package:flutter/material.dart';

extension NavigationExtension on BuildContext {
  NavigatorState get navigator => Navigator.of(this);

  Future<T?> push<T>(Widget page) {
    return navigator.push<T>(MaterialPageRoute(builder: (_) => page));
  }

  Future<T?> pushReplacement<T extends Object?, TO extends Object?>(Widget page,
      {TO? result}) {
    return navigator.pushReplacement<T, TO>(
      MaterialPageRoute(builder: (_) => page),
      result: result,
    );
  }

  Future<T?> pushAndRemoveAll<T>(Widget page) {
    return navigator.pushAndRemoveUntil<T>(
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }

  void pop<T extends Object?>([T? result]) {
    navigator.pop<T>(result);
  }

  Future<bool> maybePop<T extends Object?>([T? result]) {
    return navigator.maybePop<T>(result);
  }

  Future<T?> showAdaptiveDialog<T>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: this,
      barrierDismissible: barrierDismissible,
      builder: builder,
    );
  }
}
