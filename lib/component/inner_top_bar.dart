// lib/inner_top_bar.dart
import 'package:flutter/material.dart';

class InnerTopBar extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? selectedOption;
  final ValueChanged<String?>? onChanged;
  final List<Widget>? additionalWidgets; // New parameter for additional widgets
  final List<Widget>? additionalWidgetsAfterSelector; // New parameter for additional widgets

  InnerTopBar({
    required this.label,
    required this.options,
    required this.selectedOption,
    this.onChanged,
    this.additionalWidgets, // Initialize the new parameter
    this.additionalWidgetsAfterSelector,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: Colors.white60,
      child: Row(
        children: [
          const SizedBox(width: 5),
          Text(label),
          const SizedBox(width: 5),
          _buildStyledDropdown(),
          if (additionalWidgetsAfterSelector != null) ...additionalWidgetsAfterSelector!, // Add additional widgets after the selector if provided
          const Spacer(),
          if (additionalWidgets != null) ...additionalWidgets!, // Add additional widgets if provided
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildStyledDropdown() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade400),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedOption,
          icon: Icon(Icons.arrow_drop_down, size: 20, color: Colors.black),
          dropdownColor: Colors.white,
          style: TextStyle(color: Colors.black, fontSize: 14),
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}