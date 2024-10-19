import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SettingsWindow extends StatefulWidget {
  @override
  _SettingsWindowState createState() => _SettingsWindowState();
}

class _SettingsWindowState extends State<SettingsWindow> {
  String _selectedView = 'General'; // Default view
  String _selectedSearchEngine = 'Google'; // Move this here
  TextEditingController _customUrlController = TextEditingController(); // Move this here

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Row(
        children: [
          // Sidebar
          NavigationRail(
            selectedIndex: _getSelectedIndex(),
            onDestinationSelected: (int index) {
              setState(() {
                _selectedView = _getViewFromIndex(index);
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('General'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.keyboard),
                label: Text('ShortCut'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.play_circle_outline),
                label: Text('Player'),
              ),
            ],
          ),
          VerticalDivider(thickness: 1, width: 1), // Divider between sidebar and content

          // Content area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildContentView(),
            ),
          ),
        ],
      ),
    );
  }

  // Get selected index for the sidebar
  int _getSelectedIndex() {
    switch (_selectedView) {
      case 'General':
        return 0;
      case 'ShortCut':
        return 1;
      case 'Player':
        return 2;
      default:
        return 0;
    }
  }

  // Get corresponding view from index
  String _getViewFromIndex(int index) {
    switch (index) {
      case 0:
        return 'General';
      case 1:
        return 'ShortCut';
      case 2:
        return 'Player';
      default:
        return 'General';
    }
  }

  // Build the content view based on the selected option
  Widget _buildContentView() {
    switch (_selectedView) {
      case 'General':
        return _generalSettings();
      case 'ShortCut':
        return Center(child: Text('ShortCut Settings', style: TextStyle(fontSize: 24)));
      case 'Player':
        return Center(child: Text('Player Settings', style: TextStyle(fontSize: 24)));
      default:
        return Center(child: Text('General Settings', style: TextStyle(fontSize: 24)));
    }
  }




  Widget _generalSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Search Engine:', style: TextStyle(fontSize: 16)),
            SizedBox(width: 16),
            DropdownButton<String>(
              value: _selectedSearchEngine,
              items: <String>['Google', 'Baidu', 'Customize'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedSearchEngine = newValue!;
                  print('Selected: $_selectedSearchEngine');
                });
              },
            ),
            if (_selectedSearchEngine == 'Customize') ...[
              SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _customUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Input the Search Engine URL',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  print('Custom URL: ${_customUrlController.text}');
                },
                child: Text('Confirm'),
              ),
            ],
          ],
        ),
        SizedBox(height: 16),
        // Add other settings here, each in a new row
        // show a img from https://image.tmdb.org/t/p/w500/y4MBh0EjBlMuOzv9axM4qJlmhzz.jpg

        // FutureBuilder<http.Response>(
        //   future: fetchImage('https://image.tmdb.org/t/p/w500/y4MBh0EjBlMuOzv9axM4qJlmhzz.jpg'),
        //   builder: (context, snapshot) {
        //     if (snapshot.connectionState == ConnectionState.waiting) {
        //       return Center(child: CircularProgressIndicator());
        //     } else if (snapshot.hasError) {
        //       return Center(child: Text(snapshot.error.toString()));
        //     } else {
        //       // Image response is successful; you can use the response
        //       return Image.network(
        //         'https://image.tmdb.org/t/p/w500/y4MBh0EjBlMuOzv9axM4qJlmhzz.jpg',
        //         fit: BoxFit.cover,
        //         width: double.infinity,
        //         height: double.infinity,
        //       );
        //     }
        //   },
        // )

      ],
    );
  }


  Future<http.Response> fetchImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 5)); // 5 seconds timeout
      return response;
    } on TimeoutException {
      throw Exception('Request timed out');
    } on http.ClientException {
      throw Exception('Failed to load image');
    }
  }
}



