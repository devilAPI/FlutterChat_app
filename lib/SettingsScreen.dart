import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final bool showImages;
  final ValueChanged<bool> onShowImagesChanged;

  const SettingsScreen(
      {super.key, required this.showImages, required this.onShowImagesChanged});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _showImages;

  @override
  void initState() {
    super.initState();
    _showImages = widget.showImages;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListTile(
        title: const Text('Show Images'),
        trailing: Switch(
          value: _showImages,
          onChanged: (value) {
            setState(() {
              _showImages = value;
            });
            widget.onShowImagesChanged(value); // Call the callback
          },
        ),
      ),
    );
  }
}
