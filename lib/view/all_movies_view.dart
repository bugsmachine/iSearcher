import 'package:flutter/material.dart';
import '../component/inner_top_bar.dart'; // Adjust the path as necessary

class AllMoviesView extends StatefulWidget {
  @override
  _AllMoviesViewState createState() => _AllMoviesViewState();
}

class _AllMoviesViewState extends State<AllMoviesView> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedOption = 'Option 11111'; // Initialize with a default selected option
  final List<String> _options = ['Option 11111', 'Option 2ss', 'Option 3']; // Dropdown options

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Divider(thickness: 1, color: Colors.black), // Line at the top
          InnerTopBar(
            label: 'Select:', // Label for the dropdown
            options: _options, // Options for the dropdown
            selectedOption: _selectedOption, // Currently selected option
            onChanged: _onDropdownChanged, // Function to handle change
          ),
          Expanded(
            child: Center(
              child: Text(
                'All Movies',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onDropdownChanged(String? newValue) {
    setState(() {
      _selectedOption = newValue;
    });
    print("Selected: $_selectedOption");
  }
}