import 'package:flutter/material.dart';
import 'dart:math';

class Tags extends StatelessWidget {
  final List<Map<String, dynamic>> tagsWithColors;
  final Function(String tag)? onRemove;

  Tags({
    required this.tagsWithColors,
    this.onRemove,
  });

  Color getRandomColor() {
    final Random random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4.0, // Horizontal space between tags
      runSpacing: 4.0, // Vertical space between lines
      children: tagsWithColors.map((tagData) {
        String tag = tagData['tag'];
        Color backgroundColor = tagData['color'] ?? getRandomColor();

        return Container(
          margin: EdgeInsets.only(bottom: 4), // Additional vertical spacing
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Reduced padding
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8, // Limit maximum width
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16), // Slightly smaller radius
            border: Border.all(
              color: Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  tag,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12, // Smaller font size
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 2), // Reduced spacing
              GestureDetector(
                onTap: () => onRemove?.call(tag),
                child: Tooltip(
                  message: 'Remove tag',
                  verticalOffset: 8, // Adjust this value to bring the tooltip closer
                  child: Icon(
                    Icons.close,
                    size: 14, // Smaller icon
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}