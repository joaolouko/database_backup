import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionService {
  Future<String> encryptFile(String filePath, String password) async {
    final keyStr = password.padRight(32, '0').substring(0, 32);
    final key = encrypt.Key.fromUtf8(keyStr);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));

    final file = File(filePath);
    final bytes = await file.readAsBytes();
    
    final encrypted = encrypter.encryptBytes(bytes, iv: iv);
    
    final outPath = '$filePath.aes';
    final outFile = File(outPath);
    
    final outBytes = <int>[...iv.bytes, ...encrypted.bytes];
    await outFile.writeAsBytes(outBytes);
    
    await file.delete();
    return outPath;
  }
  
  Future<String> decryptFile(String filePath, String password) async {
    final keyStr = password.padRight(32, '0').substring(0, 32);
    final key = encrypt.Key.fromUtf8(keyStr);
    
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    
    final ivBytes = bytes.sublist(0, 16);
    final encryptedBytes = bytes.sublist(16);
    
    final iv = encrypt.IV(Uint8List.fromList(ivBytes));
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
    
    final decrypted = encrypter.decryptBytes(encrypt.Encrypted(Uint8List.fromList(encryptedBytes)), iv: iv);
    
    final outPath = filePath.replaceAll('.aes', '');
    final outFile = File(outPath);
    await outFile.writeAsBytes(decrypted);
    
    return outPath;
  }
}
