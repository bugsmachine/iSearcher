import 'package:flutter/material.dart';

class FitterTopBar extends StatelessWidget {
  final List<Widget> leftWidgets;
  final List<Widget> rightWidgets;

  const FitterTopBar({
    Key? key,
    required this.leftWidgets,
    required this.rightWidgets,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: Colors.white60,
      child: Row(
        children: [
          const SizedBox(width: 5),
          ...leftWidgets,
          const Spacer(),
          ...rightWidgets,
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}