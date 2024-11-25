import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
// import the main.dart file
import 'package:home_cinema_app/main.dart';
import 'package:home_cinema_app/service/movie_detail_generator.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class SettingsWindow extends StatefulWidget {
  @override
  _SettingsWindowState createState() => _SettingsWindowState();
}

class _SettingsWindowState extends State<SettingsWindow> {
  String _selectedView = 'General'; // Default view
  String _selectedSearchEngine = 'Google'; // Move this here
  TextEditingController _customUrlController = TextEditingController(); // Move this here

  List<String>? _imageStorageInfo;

  @override
  void initState() {
    super.initState();
    if (_selectedView == 'APP Storage') {
      _fetchImageStorageInfo();
    }
  }

  Future<void> _fetchImageStorageInfo() async {
    List<String>? info = await getImgCacheInfo("caodingjie");
    setState(() {
      _imageStorageInfo = info;
    });
  }


  Future<List<String>> getImgCacheInfo(String username) async {
    // Get the Documents directory dynamically
    // /Users/{username}/Library/Containers/top.homecinema.homeCinemaApp/Data/Documents/Posters

    String directoryPath = '/Users/$username/Library/Containers/top.homecinema.homeCinemaApp/Data/Documents/Posters';

    // Directory object for the given path
    final directory = Directory(directoryPath);

    // Check if the directory exists
    if (!await directory.exists()) {
      return ['Directory does not exist', '0', '0 KB']; // Handle missing directory case
    }

    // Initialize counters
    int totalFiles = 0;
    int totalSize = 0; // Size in bytes

    // Get the list of files in the directory
    await for (var entity in directory.list(recursive: false, followLinks: false)) {
      if (entity is File) {
        totalFiles++; // Count each file
        totalSize += await entity.length(); // Add file size
      }
    }

    // Convert totalSize to a more readable format (KB, MB, or GB)
    String sizeFormatted = _formatBytes(totalSize);
    print('Number of posters: $totalFiles');
    return ['Number of posters: $totalFiles', 'Total size: $sizeFormatted'];
  }

// Function to format bytes into KB, MB, GB
  String _formatBytes(int bytes, [int decimals = 2]) {
    if (bytes < 1024) return "$bytes B"; // less than 1 KB
    const int kb = 1024;
    const int mb = kb * 1024;
    const int gb = mb * 1024;

    if (bytes < mb) {
      return (bytes / kb).toStringAsFixed(decimals) + ' KB';
    } else if (bytes < gb) {
      return (bytes / mb).toStringAsFixed(decimals) + ' MB';
    } else {
      return (bytes / gb).toStringAsFixed(decimals) + ' GB';
    }
  }

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
                if (_selectedView == 'APP Storage') {
                  _fetchImageStorageInfo();
                }
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
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
              NavigationRailDestination(
                icon: Icon(Icons.storage_outlined),
                label: Text('APP Storage'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1), // Divider between sidebar and content

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
      case 'APP Storage':
        return 3;
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
      case 3:
        return 'APP Storage';
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
      case 'APP Storage':
        return _appStorageSettings();
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
      ],
    );
  }

  Widget _appStorageSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('APP Storage Information:', style: TextStyle(fontSize: 16)),
        SizedBox(height: 16),
        if (_imageStorageInfo != null)
          ..._imageStorageInfo!.map((info) => Text(info)).toList()
        else
          CircularProgressIndicator(),
      ],
    );
  }
}