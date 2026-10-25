import 'package:chucker_flutter_plus/src/config/theme/inspector_colors.dart';
import 'package:chucker_flutter_plus/src/core/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

extension SnackBarExtension on BuildContext {
  void closeSnackBar() => ScaffoldMessenger.of(this).hideCurrentSnackBar();

  void errorSnackBar(String error, {int duration = 2}) {
    _showToast(error, isError: true, duration: duration);
  }

  void successSnackBar(String msg, {int duration = 2}) {
    _showToast(msg, isError: false, duration: duration);
  }

  void _showToast(String message, {required bool isError, int duration = 2}) {
    Fluttertoast.cancel();

    Fluttertoast.showToast(
      msg: message,
      toastLength: duration > 2 ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: duration,
      backgroundColor: isError
          ? InspectorColors.statusError
          : InspectorColors.status2xx,
      textColor: Colors.white,
      fontSize: AppSizes.textMd,
    );
  }
}
