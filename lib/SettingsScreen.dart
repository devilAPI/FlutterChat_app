import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool _showImages = true;
  bool _showAudio = true;
  bool _enableMarkdown = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showImages = prefs.getBool('showImages') ?? true;
      _showAudio = prefs.getBool('showAudio') ?? true;
      _enableMarkdown = prefs.getBool('enableMarkdown') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Config.accentColor,
      ),
      body: Center(
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Allow Images'),
              secondary: const Icon(Icons.image),
              value: _showImages,
              onChanged: (bool value) {
                setState(() {
                  _showImages = value;
                  _saveSetting('showImages', value);
                });
              },
            ),
            SwitchListTile(
              title: const Text('Allow Audio'),
              secondary: const Icon(Icons.audiotrack),
              value: _showAudio,
              onChanged: (bool value) {
                setState(() {
                  _showAudio = value;
                  _saveSetting('showAudio', value);
                });
              },
            ),
            SwitchListTile(
              title: const Text('Enable Markdown'),
              secondary: const Icon(Icons.tag),
              value: _enableMarkdown,
              onChanged: (bool value) {
                setState(() {
                  _enableMarkdown = value;
                  _saveSetting('enableMarkdown', value);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
