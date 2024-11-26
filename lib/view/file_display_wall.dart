import 'package:flutter/material.dart';
import '../component/fitter_top_bar.dart';
import '../component/modal.dart';
import '../generated/l10n.dart';
import '../component/fitter_options.dart';
import '../app_config/colors.dart';

class FileDisplayWallView extends StatefulWidget {
  final String group;
  final String subItem;
  final S lang;

  const FileDisplayWallView({Key? key, required this.group, required this.subItem, required this.lang}) : super(key: key);

  @override
  _FileDisplayWallViewState createState() => _FileDisplayWallViewState();
}

class _FileDisplayWallViewState extends State<FileDisplayWallView> {
  bool _isLoading = false;
  late List<Map<String, dynamic>> fitters;

  @override
  void initState() {
    super.initState();
    _initializeFitters();
  }

  @override
  void didUpdateWidget(FileDisplayWallView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group != widget.group || oldWidget.subItem != widget.subItem) {
      setState(() {
        _initializeFitters(); // This will reset all fitters to unselected
      });
    }
  }

  void _getFiles() {
    setState(() {
      _isLoading = true;
    });
    // Get the files
    setState(() {
      _isLoading = false;
    });
  }

  void _initializeFitters() {
    setState(() {
      fitters = [
        {'tag': 'Fitter 1', 'isSelected': false, 'color': AppColors.lightColors[0]},
        {'tag': 'Fitter 2', 'isSelected': false, 'color': AppColors.lightColors[1]},
        {'tag': 'Fitter 3', 'isSelected': false, 'color': AppColors.lightColors[2]},
        {'tag': widget.lang.custom, 'isSelected': false, 'color': AppColors.lightColors[5]},
      ];
    });
  }

  void _onFitterSelect(String tag) {
    setState(() {
      for (var fitter in fitters) {
        if (fitter['tag'] == tag) {
          fitter['isSelected'] = !fitter['isSelected'];
          if (tag == widget.lang.custom && fitter['isSelected']) {
            _showCustomModal(context);
          }
        }
      }
    });
    _affectFitters();
  }

  void _showCustomModal(BuildContext context) {
    CustomModal.show(
      context,
      'Custom Modal',
      Container(
        child: Text('This is a custom modal.'),
      ),
      [
        TextButton(
          child: Text('Close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  void _affectFitters() {
    // Add your fitter-specific logic here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Divider(height: 1, color: Colors.grey[300]),
          FitterTopBar(
            leftWidgets: [
              Row(
                children: [
                  Text(widget.lang.fitters),
                  SizedBox(width: 8),
                  fitterRow(),
                ],
              )
            ],
            rightWidgets: [
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

  Widget fitterRow() {
    return Wrap(
      spacing: 4.0,
      runSpacing: 4.0,
      children: fitters.map((fitter) {
        return FitterOption(
          tag: fitter['tag'],
          isSelected: fitter['isSelected'],
          onSelect: (tag) {
            _onFitterSelect(tag);
          },
          color: fitter['color'],
        );
      }).toList(),
    );
  }

  Widget mainContent() {
    return Center(
      child: ListView(
        children: [
          SizedBox(height: 16),
          Text(
            'Displaying files for Group - Subitem',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _moviePoster('Venom: Last Dance', '2024-10-23', 65),
              _moviePoster('Miracle 2', '2024-10-16', 68),
              _moviePoster('Shang-Chi 2', '2024-11-22', 68),
              _moviePoster('Ant-Man 3', '2024-10-09', 69),
              _moviePoster('Alien Artifact', '2024-09-20', 84),
              _moviePoster('Apocalypse Z: The Starting Point', '2024-10-04', 68),
              _moviePoster('Upgrade', '2024-11-01', 59),
              _moviePoster('Enchanted Forest', '2024-12-06', 78),
              _moviePoster('Deadpool vs Wolverine', '2024-07-26', 77),
              _moviePoster('The Existince', '2024-09-07', 73),
            ],
          ),
        ],
      ),
    );
  }

  Widget _moviePoster(String title, String date, int rating) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            'http://8.153.39.151:8080/api/tmdb/image?image_link=kuf6dutpsT0vSVehic3EZIqkOBt.jpg',
            width: 150,
            height: 220,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          date,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Rating: $rating',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}