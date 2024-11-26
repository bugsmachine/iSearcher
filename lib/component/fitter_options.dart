import 'package:flutter/material.dart';

class FitterOption extends StatelessWidget {
  final String tag;
  final bool isSelected;
  final Color color;
  final Function(String tag)? onSelect;

  const FitterOption({
    Key? key,
    required this.tag,
    this.isSelected = false,
    required this.color,
    this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelect?.call(tag),
      child: Container(
        margin: EdgeInsets.only(bottom: 4),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: Text(
          tag,
          style: TextStyle(
            color: Colors.black,
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}