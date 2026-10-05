import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

class CompressionService {
  Future<String> compressFile(String filePath, String password) async {
    // Note: The 'archive' package does not support password protected ZIP files directly.
    // As per the project requirements, we use an external tool or fallback to a documented limitation.
    // For this academic project, we use the archive package to create a ZIP. 
    // The "password" parameter is ignored for the ZIP itself in Dart due to package limitations,
    // but the AES encryption step covers the security requirement.
    
    final file = File(filePath);
    final outPath = '$filePath.zip';
    
    final encoder = ZipFileEncoder();
    try {
      encoder.create(outPath);
      encoder.addFile(file);
    } finally {
      encoder.close();
    }
    await _deleteWithRetry(file);
    return outPath;
  }

  Future<void> _deleteWithRetry(File file) async {
    OSError? lastError;
    for (var attempt = 0; attempt < 10; attempt++) {
      try {
        if (!await file.exists()) return;
        await file.delete();
        return;
      } on FileSystemException catch (error) {
        lastError = error.osError;
        await Future<void>.delayed(Duration(milliseconds: 100 * (attempt + 1)));
      }
    }
    throw FileSystemException(
      'Não foi possível remover o arquivo intermediário após várias tentativas.',
      file.path,
      lastError,
    );
  }

  Future<String> decompressFile(String filePath, String password) async {
    final outDir = p.dirname(filePath);
    final bytes = await File(filePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    
    String? outPath;
    
    for (final file in archive.files) {
      if (file.isFile) {
        final outputStream = OutputFileStream('$outDir/${file.name}');
        file.writeContent(outputStream);
        outputStream.close();
        outPath = '$outDir/${file.name}';
      }
    }
    
    
    if (outPath == null) throw Exception('No files found in zip');
    return outPath;
  }
}
