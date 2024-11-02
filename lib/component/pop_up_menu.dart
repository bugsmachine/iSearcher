import 'package:flutter/material.dart';

class CustomPopupMenuButton extends StatefulWidget {
  @override
  _CustomPopupMenuButtonState createState() => _CustomPopupMenuButtonState();
}

class _CustomPopupMenuButtonState extends State<CustomPopupMenuButton> {
  final GlobalKey _menuKey = GlobalKey();

  void _showCustomMenu(BuildContext context) {
    final RenderBox renderBox = _menuKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + renderBox.size.height,
        offset.dx + renderBox.size.width,
        offset.dy + renderBox.size.height + 2000,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.work_outline, color: Colors.blueGrey, size: 20),
              SizedBox(width: 10),
              Text('Work 1', style: TextStyle(fontSize: 16)),
            ],
          ),
          value: 'Work 1',
        ),
        PopupMenuItem<String>(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.work, color: Colors.green, size: 20),
              SizedBox(width: 10),
              Text('Work 2', style: TextStyle(fontSize: 16)),
            ],
          ),
          value: 'Work 2',
        ),
        PopupMenuItem<String>(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.work_off, color: Colors.red, size: 20),
              SizedBox(width: 10),
              Text('Work 3', style: TextStyle(fontSize: 16)),
            ],
          ),
          value: 'Work 3',
        ),
        PopupMenuDivider(),
        PopupMenuItem<String>(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.settings, color: Colors.grey, size: 20),
              SizedBox(width: 10),
              Text('Settings', style: TextStyle(fontSize: 16)),
            ],
          ),
          value: 'Settings',
        ),
      ],
    ).then((value) {
      if (value != null) {
        print("Selected work status: $value");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: _menuKey,
      icon: Icon(Icons.work_sharp, color: Colors.grey[700], size: 28),
      onPressed: () => _showCustomMenu(context),
    );
  }
}