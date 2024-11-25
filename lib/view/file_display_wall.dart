import 'package:flutter/material.dart';

import '../component/inner_top_bar.dart';
import '../generated/l10n.dart';

class FileDisplayWallView extends StatefulWidget {
  final String group;
  final String subItem;
  final S lang;

  const FileDisplayWallView({Key? key, required this.group, required this.subItem, required this.lang}) : super(key: key);

  @override
  _FileDisplayWallViewState createState() => _FileDisplayWallViewState();
}

class _FileDisplayWallViewState extends State<FileDisplayWallView> {
  List<String> _options = ['Option 1', 'Option 2', 'Option 3'];
  String _selectedOption = 'Option 1';
  bool _isLoading = false;

  void _onDropdownChanged(String? newValue) {
    setState(() {
      _selectedOption = newValue!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Divider(height: 1, color: Colors.grey[300]),
          InnerTopBar(
            label: widget.lang.current_folder,
            options: _options,
            selectedOption: _selectedOption,
            onChanged: _onDropdownChanged,
            additionalWidgetsAfterSelector: [
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () async {
                  // open the file picker to select the folder
                },
              ),
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {
                  // open the custom modal to manage the file folders can delete or add new
                },
              ),
            ],
            additionalWidgets: [
              Row(
                children: [
                  Text(widget.lang.file_detected),
                  _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('12138'),
                ],
              ),
              SizedBox(width: 16),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  // refresh the file list
                },
              ),
            ],
          ),
          Expanded(
            child: mainContent(),
          ),
        ],
      ),
    );
  }

  Widget mainContent() {
    return Center(
      child: Text('Displaying files for ${widget.group} - ${widget.subItem}'),
    );
  }
}