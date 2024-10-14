import 'package:flutter/material.dart';
import '../app_config/colors.dart';

class CustomModal {
  static Future<void> show(
      BuildContext context,
      String title,
      Widget content,
      List<Widget> actions, {
        double? width,
        double? height,
      }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user can dismiss the modal by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Text(title),
          content: SingleChildScrollView(
            child: Container(
              width: width,
              height: height,
              child: content,

            ),
          ),
          actions: actions,
        );
      },
    );
  }
}