import 'package:flutter/material.dart';

class MovieLabel extends StatelessWidget {
  final String text;
  final double width;
  final double height;
  final Color backgroundColor;

  MovieLabel({
    required this.text,
    this.width = 100,
    this.height = 50,
    this.backgroundColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: backgroundColor,
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: Colors.white, fontSize: 8),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _resolutionLabel(String resolution) {
    return MovieLabel(
      text: resolution,
      backgroundColor: Colors.yellow,
    );
  }

  Widget _remuxLabel() {
    return MovieLabel(
      text: "REMUX",
      backgroundColor: Colors.green,
    );
  }

  Widget _bluRayLabel() {
    return MovieLabel(
      text: "BLURAY",
      backgroundColor: Colors.blue,
    );
  }

  Widget _atmosLabel() {
    return MovieLabel(
      text: "ATMOS",
      backgroundColor: Colors.red,
    );

  }

  Widget intLabel() {
    return MovieLabel(
      text: "INT",
      backgroundColor: Colors.purple,
    );
  }

  Widget _yearLabel(String year) {
    return MovieLabel(
      text: year,
      backgroundColor: Colors.grey,
    );
  }


}