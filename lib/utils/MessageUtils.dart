// lib/utils.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_chat/SettingsScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Utils {
  bool showImages = true;
  bool showAudio = true;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    showImages = prefs.getBool('showImages') ?? true;
    showAudio = prefs.getBool('showAudio') ?? true;
  }

  bool isAudioUrl(String url) {
    if (showAudio) {
      return url.endsWith('.mp3') ||
          url.endsWith('.wav') ||
          url.endsWith('.ogg') ||
          url.endsWith('.flac') ||
          url.endsWith('.m4a') ||
          url.endsWith('.aac');
    } else {
      return false;
    }
  }

  bool isImageUrl(String url) {
    if (showImages) {
      return url.endsWith('.png') ||
          url.endsWith('.jpg') ||
          url.endsWith('.jpeg') ||
          url.endsWith('.gif') ||
          url.endsWith('.bmp') ||
          url.endsWith('.webp');
    } else {
      return false;
    }
  }
}