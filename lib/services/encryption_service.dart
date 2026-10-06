import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionService {
  Future<String> encryptFile(String filePath, String password) async {
    if (password.isEmpty) throw ArgumentError('A senha AES não pode ser vazia.');
    final keyStr = password.padRight(32, '0').substring(0, 32);
    final key = encrypt.Key.fromUtf8(keyStr);
    final iv = encrypt.IV(Uint8List.fromList(
      List<int>.generate(16, (_) => Random.secure().nextInt(256)),
    ));
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.gcm),
    );
    final file = File(filePath);
    if (!await file.exists()) throw FileSystemException('Arquivo não encontrado.', filePath);
    final encrypted = encrypter.encryptBytes(await file.readAsBytes(), iv: iv);
    final outPath = '$filePath.aes';
    await File(outPath).writeAsBytes([...iv.bytes, ...encrypted.bytes]);
    await file.delete();
    return outPath;
  }

  Future<String> decryptFile(String filePath, String password) async {
    if (password.isEmpty) throw ArgumentError('A senha AES não pode ser vazia.');
    final keyStr = password.padRight(32, '0').substring(0, 32);
    final key = encrypt.Key.fromUtf8(keyStr);
    final bytes = await File(filePath).readAsBytes();
    if (bytes.length <= 16) throw Exception('Arquivo AES inválido ou incompleto.');
    final iv = encrypt.IV(Uint8List.fromList(bytes.sublist(0, 16)));
    final encryptedBytes = Uint8List.fromList(bytes.sublist(16));
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.gcm),
    );
    final decrypted = encrypter.decryptBytes(
      encrypt.Encrypted(encryptedBytes),
      iv: iv,
    );
    final outPath = filePath.endsWith('.aes')
        ? filePath.substring(0, filePath.length - 4)
        : '$filePath.decrypted';
    await File(outPath).writeAsBytes(decrypted);
    return outPath;
  }
}
