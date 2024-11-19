// lib/utils.dart

class Utils {
  static bool isAudioUrl(String url) {
    return url.endsWith('.mp3') ||
        url.endsWith('.wav') ||
        url.endsWith('.ogg') ||
        url.endsWith('.flac') ||
        url.endsWith('.m4a ') ||
        url.endsWith('.aac');
  }
   static bool isImageUrl(String url) {
    return url.endsWith('.png') ||
        url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.gif') ||
        url.endsWith('.bmp') ||
        url.endsWith('.webp');
  }
}