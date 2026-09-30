import '../core/database.dart';

class LoggingService {
  Future<void> logExecution(int executionId, String step, String message, {String? error}) async {
    print('[${DateTime.now().toIso8601String()}] $step: $message ${error ?? ""}');
    await appDatabase.insert('execution_logs', {
      'execution_id': executionId,
      'date': DateTime.now().toIso8601String(),
      'step': step,
      'message': message,
      'error': error,
    });
  }

  Future<List<Map<String, dynamic>>> getLogs(int executionId) async {
    return await appDatabase.query(
      'execution_logs',
      where: 'execution_id = ?',
      whereArgs: [executionId],
      orderBy: 'id ASC',
    );
  }
}
