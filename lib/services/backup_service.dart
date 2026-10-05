import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'postgres_service.dart';
import 'maintenance_service.dart';
import 'encryption_service.dart';
import 'compression_service.dart';
import 'logging_service.dart';
import 'package:path/path.dart' as p;
import '../models/models.dart';
import '../core/database.dart';

class BackupService {
  final PostgresService postgresService;
  final MaintenanceService maintenanceService;
  final EncryptionService encryptionService;
  final CompressionService compressionService;
  final LoggingService loggingService;

  BackupService({
    required this.postgresService,
    required this.maintenanceService,
    required this.encryptionService,
    required this.compressionService,
    required this.loggingService,
  });

  String? _findPgDump() {
    if (Platform.isWindows) {
      final paths = [
        r'C:\Program Files\PostgreSQL\18\bin\pg_dump.exe',
        r'C:\Program Files\PostgreSQL\17\bin\pg_dump.exe',
        r'C:\Program Files\PostgreSQL\16\bin\pg_dump.exe',
        r'C:\Program Files\PostgreSQL\15\bin\pg_dump.exe',
        r'C:\Program Files\PostgreSQL\14\bin\pg_dump.exe',
        r'C:\Program Files\PostgreSQL\13\bin\pg_dump.exe',
      ];
      for (final path in paths) {
        if (File(path).existsSync()) return path;
      }
      return 'pg_dump.exe';
    }
    return 'pg_dump';
  }

  String? _findPgRestore() {
    if (Platform.isWindows) {
      final paths = [
        r'C:\Program Files\PostgreSQL\18\bin\pg_restore.exe',
        r'C:\Program Files\PostgreSQL\17\bin\pg_restore.exe',
        r'C:\Program Files\PostgreSQL\16\bin\pg_restore.exe',
        r'C:\Program Files\PostgreSQL\15\bin\pg_restore.exe',
        r'C:\Program Files\PostgreSQL\14\bin\pg_restore.exe',
        r'C:\Program Files\PostgreSQL\13\bin\pg_restore.exe',
      ];
      for (final path in paths) {
        if (File(path).existsSync()) return path;
      }
      return 'pg_restore.exe';
    }
    return 'pg_restore';
  }

  Future<BackupRecord> executeBackupPipeline({
    required DatabaseServer database,
    required String host,
    required int port,
    required String username,
    required String password,
    required String destination,
    int? retentionCount,
    String? additionalDestination,
    bool executeMaintenance = true,
    bool fullMaintenance = false,
    bool encrypt = false,
    String? encryptionPassword,
    bool compress = false,
    String? compressPassword,
    Function(String step, String message)? onProgress,
  }) async {
    final start = DateTime.now();
    int executionId = await appDatabase.insert('execution_history', {
      'database': database.database,
      'date': start.toIso8601String(),
      'duration': '0',
      'status': BackupStatus.running.name,
    });
    
    void progress(String step, String msg, {String? error}) {
      loggingService.logExecution(executionId, step, msg, error: error);
      if (onProgress != null) onProgress(step, msg);
    }
    
    String? currentFile;
    String maintenanceDecision = 'Nenhuma';
    String maintenanceRule = 'N/A';

    try {
      progress('Validação', 'Iniciando validação de parâmetros...');
      final pgDump = _findPgDump();
      if (pgDump == null) throw Exception('pg_dump não encontrado.');
      final outputDir = Directory(destination);
      await outputDir.create(recursive: true);
      if (!await outputDir.exists()) {
        throw Exception('Não foi possível criar o diretório de destino: $destination');
      }
      if (additionalDestination != null && additionalDestination.isNotEmpty) {
        await Directory(additionalDestination).create(recursive: true);
      }
      if (encrypt && (encryptionPassword == null || encryptionPassword.isEmpty)) {
        throw Exception('Senha de criptografia não fornecida.');
      }
      
      progress('Conexão', 'Testando conexão com banco...');
      await postgresService.connect(host: host, port: port, username: username, password: password, database: database.database);
      
      progress('Manutenção', 'Analisando necessidade de manutenção...');
      if (executeMaintenance) {
        if (fullMaintenance) {
          maintenanceDecision = 'VACUUM FULL ANALYZE';
          maintenanceRule = 'Manual (Completa)';
        } else {
          maintenanceDecision = await maintenanceService.determineMaintenanceAction(database.database);
          maintenanceRule = 'Automática baseada no histórico';
        }
        
        progress('Manutenção', 'Executando: $maintenanceDecision');
        await maintenanceService.executeMaintenance(
          database: database.database,
          action: maintenanceDecision,
          origemDecisao: fullMaintenance ? 'Manual' : 'Automática',
          regraAplicada: maintenanceRule,
          host: host,
          port: port,
          username: username,
          password: password,
        );
      } else {
        progress('Manutenção', 'Manutenção pulada pelo usuário.');
      }

      progress('Backup', 'Iniciando pg_dump...');
      final fileName = '${database.database}_${start.millisecondsSinceEpoch}.dump';
      final dumpPath = p.join(destination, fileName);
      
      final arguments = [
        '--host=$host',
        '--port=$port',
        '--username=$username',
        '--format=custom',
        '--file=$dumpPath',
        database.database,
      ];
      
      final process = await Process.start(
        pgDump, arguments,
        environment: {...Platform.environment, 'PGPASSWORD': password},
        runInShell: false,
      );
      
      final stdoutFuture = process.stdout.transform(utf8.decoder).join();
      final stderrFuture = process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;
      await stdoutFuture;
      final stderr = await stderrFuture;
      if (exitCode != 0) {
        throw Exception('pg_dump falhou (código $exitCode): $stderr');
      }
      currentFile = dumpPath;
      final dumpFile = File(dumpPath);
      if (!await dumpFile.exists() || await dumpFile.length() == 0) {
        throw Exception('pg_dump terminou sem gerar um arquivo válido: $dumpPath');
      }
      
      if (encrypt) {
        progress('Criptografia', 'Criptografando arquivo AES...');
        currentFile = await encryptionService.encryptFile(currentFile!, encryptionPassword!);
      }
      
      if (compress) {
        progress('Compressão', 'Compactando em ZIP...');
        currentFile = await compressionService.compressFile(currentFile!, compressPassword ?? '');
      }
      
      if (retentionCount != null && retentionCount > 0) {
        progress('Retenção', 'Aplicando política de retenção ($retentionCount)...');
        await _applyRetention(destination, database.database, retentionCount);
      }
      
      if (additionalDestination != null && additionalDestination.isNotEmpty) {
        progress('Cópia', 'Copiando para destino adicional...');
        final addFile = File(p.join(additionalDestination, p.basename(currentFile!)));
        await File(currentFile!).copy(addFile.path);
      }
      
      final duration = DateTime.now().difference(start);
      progress('Finalização', 'Processo concluído com sucesso.');
      
      await appDatabase.update('execution_history', {
        'status': BackupStatus.success.name,
        'duration': duration.inSeconds.toString(),
        'file_path': currentFile,
        'maintenance_decision': maintenanceDecision,
        'maintenance_rule': maintenanceRule,
      }, where: 'id = ?', whereArgs: [executionId]);

      return BackupRecord(
        id: executionId,
        database: database.database,
        date: start,
        duration: '${duration.inSeconds}s',
        status: BackupStatus.success,
        filePath: currentFile,
        maintenanceDecision: maintenanceDecision,
        maintenanceRule: maintenanceRule,
      );

    } catch (e) {
      final duration = DateTime.now().difference(start);
      progress('Erro', 'Falha no processo', error: e.toString());
      
      await appDatabase.update('execution_history', {
        'status': BackupStatus.failed.name,
        'duration': duration.inSeconds.toString(),
        'error': e.toString(),
        'file_path': currentFile,
      }, where: 'id = ?', whereArgs: [executionId]);
      
      return BackupRecord(
        id: executionId,
        database: database.database,
        date: start,
        duration: '${duration.inSeconds}s',
        status: BackupStatus.failed,
        error: e.toString(),
      );
    }
  }

  Future<void> _applyRetention(String dirPath, String database, int count) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return;
    
    final files = dir.listSync().whereType<File>().where((f) => p.basename(f.path).startsWith(database)).toList();
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync())); // newest first
    
    if (files.length > count) {
      for (int i = count; i < files.length; i++) {
        await files[i].delete();
        loggingService.logExecution(0, 'Retenção', 'Arquivo antigo deletado: ${files[i].path}');
      }
    }
  }

  Future<void> executeRestore({
    required String filePath,
    required String host,
    required int port,
    required String username,
    required String password,
    required String database,
    bool isEncrypted = false,
    String? encryptionPassword,
    bool isCompressed = false,
    String? compressPassword,
    Function(String step, String message)? onProgress,
  }) async {
    final pgRestore = _findPgRestore();
    if (pgRestore == null) throw Exception('pg_restore não encontrado.');
    
    String currentPath = filePath;
    try {
      if (onProgress != null) onProgress('Validação', 'Preparando restauração...');
      
      if (isCompressed) {
        if (onProgress != null) onProgress('Descompressão', 'Descompactando ZIP...');
        currentPath = await compressionService.decompressFile(currentPath, compressPassword ?? '');
      }
      
      if (isEncrypted) {
        if (onProgress != null) onProgress('Descriptografia', 'Descriptografando arquivo...');
        currentPath = await encryptionService.decryptFile(currentPath, encryptionPassword!);
      }
      
      if (onProgress != null) onProgress('Conexão', 'Conectando para restaurar...');
      await postgresService.connect(host: host, port: port, username: username, password: password, database: 'postgres');
      
      // Try to create db if it doesn't exist? (Optional, here we assume it exists or pg_restore handles it)
      // Usually better to let pg_restore create it with -C if possible, or drop and recreate.
      // For safety we just run pg_restore on the database.
      
      if (onProgress != null) onProgress('Restauração', 'Executando pg_restore...');
      final arguments = [
        '--host=$host',
        '--port=$port',
        '--username=$username',
        '--dbname=$database',
        '--clean',
        currentPath,
      ];
      
      final process = await Process.start(
        pgRestore, arguments,
        environment: {...Platform.environment, 'PGPASSWORD': password},
        runInShell: false,
      );
      
      final stdoutFuture = process.stdout.transform(utf8.decoder).join();
      final stderrFuture = process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;
      await stdoutFuture;
      final stderr = await stderrFuture;
      if (exitCode != 0) {
        throw Exception('pg_restore falhou (código $exitCode): $stderr');
      }
      
      if (onProgress != null) onProgress('Integridade', 'Verificando integridade...');
      await postgresService.connect(host: host, port: port, username: username, password: password, database: database);
      final size = await postgresService.getDatabaseSize(database);
      
      if (onProgress != null) onProgress('Finalização', 'Restauração concluída. Tamanho: $size');
      
    } finally {
      // Clean up temp files if they were decrypted/decompressed
      if (currentPath != filePath && await File(currentPath).exists()) {
        await File(currentPath).delete();
      }
    }
  }
}
