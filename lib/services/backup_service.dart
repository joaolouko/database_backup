import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'postgres_service.dart';
import 'maintenance_service.dart';
import 'encryption_service.dart';
import 'compression_service.dart';
import 'logging_service.dart';
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

  String _findExecutable(String name, List<String> windowsPaths) {
    if (Platform.isWindows) {
      for (final path in windowsPaths) {
        if (File(path).existsSync()) return path;
      }
      return '$name.exe';
    }
    return name;
  }

  String _findPgDump() => _findExecutable('pg_dump', [
        r'C:\Program Files\PostgreSQL\18\bin\pg_dump.exe',
        r'C:\Program Files\PostgreSQL\17\bin\pg_dump.exe',
        r'C:\Program Files\PostgreSQL\16\bin\pg_dump.exe',
        r'C:\Program Files\PostgreSQL\15\bin\pg_dump.exe',
        r'C:\Program Files\PostgreSQL\14\bin\pg_dump.exe',
        r'C:\Program Files\PostgreSQL\13\bin\pg_dump.exe',
      ]);

  String _findPgRestore() => _findExecutable('pg_restore', [
        r'C:\Program Files\PostgreSQL\18\bin\pg_restore.exe',
        r'C:\Program Files\PostgreSQL\17\bin\pg_restore.exe',
        r'C:\Program Files\PostgreSQL\16\bin\pg_restore.exe',
        r'C:\Program Files\PostgreSQL\15\bin\pg_restore.exe',
        r'C:\Program Files\PostgreSQL\14\bin\pg_restore.exe',
        r'C:\Program Files\PostgreSQL\13\bin\pg_restore.exe',
      ]);

  String _redact(String value, Iterable<String> secrets) {
    var result = value;
    for (final secret in secrets) {
      if (secret.isNotEmpty) result = result.replaceAll(secret, '[REDACTED]');
    }
    return result;
  }

  Future<(int, String, String)> _runProcess(
    String executable,
    List<String> arguments,
    String password,
  ) async {
    final process = await Process.start(
      executable,
      arguments,
      environment: {...Platform.environment, 'PGPASSWORD': password},
      runInShell: false,
    );
    final stdoutFuture = process.stdout.transform(utf8.decoder).join();
    final stderrFuture = process.stderr.transform(utf8.decoder).join();
    final exitCode = await process.exitCode;
    return (exitCode, await stdoutFuture, await stderrFuture);
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
    String maintenanceMode = 'automatic',
    bool encrypt = false,
    String? encryptionPassword,
    bool compress = false,
    String? compressPassword,
    Function(String step, String message)? onProgress,
  }) async {
    final start = DateTime.now();
    final executionId = await appDatabase.insert('execution_history', {
      'database': database.database,
      'date': start.toIso8601String(),
      'duration': '0',
      'status': BackupStatus.running.name,
    });
    final secrets = [password, encryptionPassword ?? '', compressPassword ?? ''];
    var currentStep = 'Inicialização';
    Future<void> progress(String step, String message, {String? error}) async {
      currentStep = step;
      await loggingService.logExecution(
        executionId,
        step,
        _redact(message, secrets),
        error: error == null ? null : _redact(error, secrets),
      );
      onProgress?.call(step, message);
    }

    String? currentFile;
    var maintenanceDecision = 'Nenhuma';
    var maintenanceRule = 'N/A';
    try {
      await progress('Validação', 'Validando parâmetros, diretórios e ferramentas...');
      if (host.trim().isEmpty || username.trim().isEmpty || database.database.trim().isEmpty) {
        throw Exception('Host, usuário e banco de dados são obrigatórios.');
      }
      if (port < 1 || port > 65535) throw Exception('Porta PostgreSQL inválida.');
      if (!p.isAbsolute(destination)) throw Exception('O destino principal deve ser um caminho absoluto.');
      if (additionalDestination != null && additionalDestination.isNotEmpty && !p.isAbsolute(additionalDestination)) {
        throw Exception('O destino adicional deve ser um caminho absoluto.');
      }
      if (retentionCount != null && retentionCount < 0) throw Exception('A retenção não pode ser negativa.');
      if (encrypt && (encryptionPassword == null || encryptionPassword.isEmpty)) {
        throw Exception('Senha de criptografia não fornecida.');
      }
      if (compress && (compressPassword == null || compressPassword.isEmpty)) {
        throw Exception('Senha do ZIP não fornecida.');
      }
      final outputDir = Directory(destination);
      await outputDir.create(recursive: true);
      if (additionalDestination != null && additionalDestination.isNotEmpty) {
        await Directory(additionalDestination).create(recursive: true);
      }
      final pgDump = _findPgDump();

      await progress('Conexão', 'Testando conexão e permissões do banco...');
      await postgresService.connect(
        host: host,
        port: port,
        username: username,
        password: password,
        database: database.database,
      );

      await progress('Manutenção', 'Analisando necessidade de manutenção...');
      final selectedMode = maintenanceMode == 'automatic'
          ? (executeMaintenance ? 'automatic' : 'none')
          : maintenanceMode;
      if (selectedMode == 'none') {
        maintenanceDecision = 'Nenhuma';
        maintenanceRule = 'Manual (desativada)';
      } else if (selectedMode == 'full' || fullMaintenance) {
        maintenanceDecision = 'VACUUM FULL ANALYZE';
        maintenanceRule = 'Manual (Completa)';
      } else if (selectedMode == 'vacuum') {
        maintenanceDecision = 'VACUUM';
        maintenanceRule = 'Manual (VACUUM)';
      } else {
        maintenanceDecision = await maintenanceService.determineMaintenanceAction(database.database);
        maintenanceRule = maintenanceDecision == 'Nenhuma'
            ? 'Automática: última manutenção há menos de 30 dias'
            : maintenanceDecision == 'VACUUM'
                ? 'Automática: última manutenção entre 30 e 60 dias'
                : 'Automática: sem histórico ou última manutenção há mais de 60 dias';
      }
      await progress('Manutenção', 'Decisão: $maintenanceDecision.');
      if (maintenanceDecision != 'Nenhuma') {
        await maintenanceService.executeMaintenance(
          database: database.database,
          action: maintenanceDecision,
          origemDecisao: selectedMode == 'automatic' ? 'Automática' : 'Manual',
          regraAplicada: maintenanceRule,
          host: host,
          port: port,
          username: username,
          password: password,
        );
      }

      await progress('Backup', 'Executando pg_dump...');
      final dumpPath = p.join(destination, '${database.database}_${start.millisecondsSinceEpoch}.dump');
      final result = await _runProcess(
        pgDump,
        [
          '--host=$host',
          '--port=$port',
          '--username=$username',
          '--format=custom',
          '--no-password',
          '--file=$dumpPath',
          database.database,
        ],
        password,
      );
      if (result.$1 != 0) throw Exception('pg_dump falhou (código ${result.$1}): ${_redact(result.$3, secrets)}');
      final dumpFile = File(dumpPath);
      if (!await dumpFile.exists() || await dumpFile.length() == 0) throw Exception('pg_dump terminou sem gerar um arquivo válido.');
      currentFile = dumpPath;

      if (encrypt) {
        await progress('Criptografia', 'Protegendo o backup com AES-256-GCM...');
        currentFile = await encryptionService.encryptFile(currentFile!, encryptionPassword!);
      }
      if (compress) {
        await progress('Compressão', 'Criando ZIP protegido por senha...');
        currentFile = await compressionService.compressFile(currentFile!, compressPassword!);
      }
      if (retentionCount != null && retentionCount > 0) {
        await progress('Retenção', 'Aplicando política: manter $retentionCount arquivo(s)...');
        await _applyRetention(destination, database.database, retentionCount, executionId);
      }
      if (additionalDestination != null && additionalDestination.isNotEmpty) {
        await progress('Cópia adicional', 'Copiando o arquivo concluído...');
        await File(currentFile!).copy(p.join(additionalDestination, p.basename(currentFile!)));
      }

      final duration = DateTime.now().difference(start);
      await progress('Finalização', 'Backup concluído com sucesso.');
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
    } catch (error) {
      final duration = DateTime.now().difference(start);
      final safeError = _redact(error.toString(), secrets);
      final failedStep = currentStep;
      await progress('Erro', 'Falha na etapa "$failedStep".', error: safeError);
      await appDatabase.update('execution_history', {
        'status': BackupStatus.failed.name,
        'duration': duration.inSeconds.toString(),
        'error': safeError,
        'file_path': currentFile,
        'maintenance_decision': maintenanceDecision,
        'maintenance_rule': maintenanceRule,
      }, where: 'id = ?', whereArgs: [executionId]);
      return BackupRecord(
        id: executionId,
        database: database.database,
        date: start,
        duration: '${duration.inSeconds}s',
        status: BackupStatus.failed,
        filePath: currentFile,
        error: safeError,
        maintenanceDecision: maintenanceDecision,
        maintenanceRule: maintenanceRule,
      );
    }
  }

  Future<void> _applyRetention(String dirPath, String database, int count, int executionId) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return;
    final files = dir.listSync().whereType<File>().where((file) {
      final name = p.basename(file.path);
      return name.startsWith('${database}_') &&
          (name.endsWith('.dump') || name.endsWith('.dump.aes') || name.endsWith('.dump.zip') || name.endsWith('.dump.aes.zip'));
    }).toList();
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    for (var i = count; i < files.length; i++) {
      final oldPath = files[i].path;
      await files[i].delete();
      await loggingService.logExecution(executionId, 'Retenção', 'Arquivo antigo removido: ${p.basename(oldPath)}');
    }
  }

  Future<Map<String, dynamic>> executeRestore({
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
    if (isEncrypted && (encryptionPassword == null || encryptionPassword.isEmpty)) throw Exception('Senha de descriptografia não fornecida.');
    if (isCompressed && (compressPassword == null || compressPassword.isEmpty)) throw Exception('Senha de descompactação não fornecida.');
    var currentPath = filePath;
    final temporaryPaths = <String>[];
    try {
      onProgress?.call('Validação', 'Validando o arquivo de restauração...');
      if (!await File(filePath).exists()) throw Exception('Arquivo de backup não encontrado.');
      if (isCompressed) {
        onProgress?.call('Descompressão', 'Extraindo ZIP protegido...');
        currentPath = await compressionService.decompressFile(currentPath, compressPassword!);
        temporaryPaths.add(p.dirname(currentPath));
      }
      if (isEncrypted) {
        onProgress?.call('Descriptografia', 'Descriptografando AES...');
        currentPath = await encryptionService.decryptFile(currentPath, encryptionPassword!);
        temporaryPaths.add(currentPath);
      }
      onProgress?.call('Conexão', 'Conectando ao banco de restauração...');
      await postgresService.connect(host: host, port: port, username: username, password: password, database: 'postgres');
      onProgress?.call('Restauração', 'Executando pg_restore...');
      final result = await _runProcess(
        _findPgRestore(),
        [
          '--host=$host',
          '--port=$port',
          '--username=$username',
          '--dbname=$database',
          '--clean',
          '--if-exists',
          '--no-owner',
          '--exit-on-error',
          '--no-password',
          currentPath,
        ],
        password,
      );
      if (result.$1 != 0) throw Exception('pg_restore falhou (código ${result.$1}): ${result.$3}');
      onProgress?.call('Integridade', 'Conferindo tabelas, registros e tamanho do banco...');
      await postgresService.connect(host: host, port: port, username: username, password: password, database: database);
      final integrity = await postgresService.getDatabaseIntegrity();
      if ((integrity['tableCount'] as int) < 1) throw Exception('Restauração sem tabelas de usuário; integridade não confirmada.');
      onProgress?.call('Finalização', 'Restauração validada: ${integrity['tableCount']} tabela(s), ${integrity['rowEstimate']} registro(s) estimado(s).');
      return integrity;
    } finally {
      for (final path in temporaryPaths.reversed) {
        final type = FileSystemEntity.typeSync(path);
        if (type == FileSystemEntityType.directory) {
          await Directory(path).delete(recursive: true);
        } else if (type == FileSystemEntityType.file) {
          await File(path).delete();
        }
      }
    }
  }
}
