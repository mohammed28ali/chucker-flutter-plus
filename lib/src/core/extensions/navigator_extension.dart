import 'package:flutter/material.dart';

import '../routes/routes_name.dart';

extension NavigatorExtension on BuildContext {
  Future<dynamic> pushNamed(String routeName, {Object? arguments}) async =>
      await Navigator.of(this).pushNamed(routeName, arguments: arguments);

  Future<dynamic> pushReplacementNamed(
    String routeName, {
    Object? arguments,
  }) async =>
      await Navigator.of(this)
          .pushReplacementNamed(routeName, arguments: arguments);

  Future<dynamic> pushAndRemoveUntilNamed(
    String routeName, {
    Object? arguments,
  }) async => await Navigator.of(
    this,
  ).pushNamedAndRemoveUntil(routeName, (route) => false, arguments: arguments);

  Future<dynamic> pop([Object? result]) async {
    if (Navigator.canPop(this)) {
      Navigator.pop(this, result);
    } else {
      pushAndRemoveUntilNamed(Routes.initialRoute);
    }
  }

  void popUntil(String routeName) {
    Navigator.popUntil(this, (route) => route.settings.name == routeName);
  }
}
