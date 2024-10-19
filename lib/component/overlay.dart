import 'package:flutter/material.dart';

class LoadingOverlay {
  static void show(BuildContext context, String message, {double width = 200, double height = 150}) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents user from dismissing the overlay
      builder: (BuildContext context) {
        return Stack(
          children: [
            ModalBarrier(
              dismissible: false,
              color: Colors.black.withOpacity(0.5), // Semi-transparent background
            ),
            Center(
              child: Container(
                width: width,
                height: height,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(), // Loading animation
                    SizedBox(height: 16),
                    Text(
                      message,
                      style: TextStyle(color: Colors.black, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}