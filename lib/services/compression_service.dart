import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

class CompressionService {
  Future<String> compressFile(String filePath, String password) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('Arquivo para compactação não encontrado.', filePath);
    }
    final outPath = '$filePath.zip';
    if (await File(outPath).exists()) await _deleteWithRetry(File(outPath));

    if (password.isEmpty) {
      final encoder = ZipFileEncoder();
      try {
        encoder.create(outPath);
        encoder.addFile(file);
      } finally {
        encoder.close();
      }
    } else {
      final tool = await _findZipTool();
      if (tool == null) {
        throw Exception('ZIP protegido requer 7z/7zz ou zip disponível no PATH.');
      }
      final result = await Process.run(
        tool.executable,
        tool.executable == 'zip'
            ? [...tool.prefixArguments, '-P$password', outPath, filePath]
            : [...tool.prefixArguments, 'a', '-tzip', '-y', '-p$password', outPath, filePath],
        runInShell: false,
      );
      if (result.exitCode != 0 || !await File(outPath).exists()) {
        throw Exception('Falha ao criar ZIP protegido: ${result.stderr}');
      }
    }
    await _deleteWithRetry(file);
    return outPath;
  }

  Future<String> decompressFile(String filePath, String password) async {
    final input = File(filePath);
    if (!await input.exists()) {
      throw FileSystemException('Arquivo ZIP não encontrado.', filePath);
    }
    final outDir = Directory(p.join(
      p.dirname(filePath),
      '.restore_${DateTime.now().microsecondsSinceEpoch}',
    ));
    await outDir.create(recursive: true);

    if (password.isEmpty) {
      final archive = ZipDecoder().decodeBytes(await input.readAsBytes());
      String? outPath;
      for (final entry in archive.files) {
        if (!entry.isFile) continue;
        final safeName = _safeEntryName(entry.name);
        final target = File(p.join(outDir.path, safeName));
        await target.parent.create(recursive: true);
        final output = OutputFileStream(target.path);
        entry.writeContent(output);
        output.close();
        outPath ??= target.path;
      }
      if (outPath == null) throw Exception('O ZIP não contém arquivos utilizáveis.');
      return outPath;
    }

    final tool = await _findUnzipTool();
    if (tool == null) {
      throw Exception('ZIP protegido requer 7z/7zz ou unzip disponível no PATH.');
    }
    if (tool.executable == 'unzip') {
      final listing = await Process.run('unzip', ['-Z1', filePath], runInShell: false);
      if (listing.exitCode != 0) throw Exception('Não foi possível ler a lista de entradas do ZIP.');
      for (final entry in listing.stdout.toString().split('\n')) {
        if (entry.trim().isNotEmpty) _safeEntryName(entry.trim());
      }
    }
    final result = await Process.run(
      tool.executable,
      tool.arguments(filePath, outDir.path, password),
      runInShell: false,
    );
    if (result.exitCode != 0) {
      throw Exception('Falha ao extrair ZIP protegido. Verifique a senha. ${result.stderr}');
    }
    final files = await outDir.list(recursive: true).where((entity) => entity is File).toList();
    if (files.isEmpty) throw Exception('O ZIP não contém arquivos utilizáveis.');
    return (files.first as File).path;
  }

  String _safeEntryName(String name) {
    final normalized = p.normalize(name.replaceAll('\\', '/')).replaceAll('\\', '/');
    if (normalized.startsWith('/') || RegExp(r'^[A-Za-z]:').hasMatch(normalized) || normalized == '..' || normalized.startsWith('../')) {
      throw Exception('Entrada ZIP inválida: caminho fora do diretório de restauração.');
    }
    return normalized;
  }

  Future<_ZipTool?> _findZipTool() async {
    if (Platform.isWindows) {
      for (final path in [r'C:\Program Files\7-Zip\7z.exe', r'C:\Program Files\7-Zip\7zz.exe']) {
        if (await File(path).exists()) return _ZipTool(path, const []);
      }
    }
    for (final command in ['7z', '7zz', 'zip']) {
      final result = await Process.run(Platform.isWindows ? 'where' : 'which', [command]);
      if (result.exitCode == 0) {
        return _ZipTool(command, command == 'zip' ? const ['-j'] : const []);
      }
    }
    return null;
  }

  Future<_UnzipTool?> _findUnzipTool() async {
    if (Platform.isWindows) {
      for (final path in [r'C:\Program Files\7-Zip\7z.exe', r'C:\Program Files\7-Zip\7zz.exe']) {
        if (await File(path).exists()) {
          return _UnzipTool(path, (file, dir, password) => ['x', '-y', '-p$password', '-o$dir', file]);
        }
      }
    }
    for (final command in ['7z', '7zz', 'unzip']) {
      final result = await Process.run(Platform.isWindows ? 'where' : 'which', [command]);
      if (result.exitCode == 0) {
        return _UnzipTool(
          command,
          command == 'unzip'
              ? (path, dir, password) => ['-P$password', '-o$dir', path]
              : (path, dir, password) => ['x', '-y', '-p$password', '-o$dir', path],
        );
      }
    }
    return null;
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
}

class _ZipTool {
  final String executable;
  final List<String> prefixArguments;
  const _ZipTool(this.executable, this.prefixArguments);
}

class _UnzipTool {
  final String executable;
  final List<String> Function(String path, String directory, String password) arguments;
  const _UnzipTool(this.executable, this.arguments);
}
