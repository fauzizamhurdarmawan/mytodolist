import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionService {
  // Kunci enkripsi dengan panjang tepat 16 karakter (128-bit)
  final key =
      encrypt.Key.fromUtf8('thisis128bitkey!'); // 128-bit key (16 chars)

  // Fungsi untuk enkripsi data
  String encryptData(String data) {
    try {
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );

      // Gunakan IV baru untuk setiap enkripsi
      final iv = encrypt.IV.fromLength(16);
      final encrypted = encrypter.encrypt(data, iv: iv);

      // Gabungkan cipher text dan IV menjadi satu string
      return '${encrypted.base64}:${iv.base64}';
    } catch (e) {
      print('Error during encryption: $e');
      return ''; // Return empty string in case of error
    }
  }

  String decryptData(String encryptedData) {
    try {
      // Pisahkan cipher text dan IV dari string terenkripsi
      final parts = encryptedData.split(':');
      if (parts.length != 2) {
        throw FormatException('Invalid encrypted data format');
      }

      final cipherText = parts[0];
      final iv = encrypt.IV.fromBase64(parts[1]);

      // Dekripsi menggunakan cipher text dan IV yang benar
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );
      final decrypted = encrypter.decrypt64(cipherText, iv: iv);

      return decrypted;
    } catch (e) {
      print('Error during decryption: $e');
      return ''; // Return empty string in case of error
    }
  }
}
