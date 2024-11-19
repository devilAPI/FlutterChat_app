import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as encrypt;
import '../Config.dart';

class ApiHelper {
  static Future<http.Response> sendMessage({
    required String user1Id,
    required String user2Id,
    required String message,
    required String encryptionKey,
  }) async {
    final response = await http.post(
      Uri.parse(Config.backendUrl + '/save.php'),
      body: {
        'user1Id': user1Id,
        'user2Id': user2Id,
        'message': message,
        'encryptionKey': encryptionKey,
      },
    );
    return response;
  }

  static String encryptMessage(String message, String encryptionKey) {
    final key = encrypt.Key.fromUtf8(
        encryptionKey.padRight(32, '0').substring(0, 32));
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(message, iv: iv);
    final encryptedMessage = '${iv.base64}:${encrypted.base64}';

    return encryptedMessage;
  }

  static String decryptMessage(String encryptedMessage, String encryptionKey) {
    // Check if the encrypted message contains the expected delimiter
    if (!encryptedMessage.contains(':')) {
      print("Decryption error: Invalid format of encrypted message");
      return "Decryption error: Invalid format of encrypted message";
    }

    try {
      // Ensure the encryption key is 32 characters long
      final key = encrypt.Key.fromUtf8(
          encryptionKey.padRight(32, '0').substring(0, 32));
      final parts = encryptedMessage.split(':');

      // Check if both parts (IV and encrypted text) are present
      if (parts.length != 2) {
        print("Decryption error: Expected 2 parts, but got ${parts.length}");
        return "Decryption error: Expected 2 parts, but got ${parts.length}";
      }

      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final decrypted = encrypter.decrypt64(parts[1], iv: iv);

      return decrypted;
    } catch (e) {
      print("Decryption error: $e");
      return "Decryption error: $e";
    }
  }
}