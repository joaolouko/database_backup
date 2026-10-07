import 'postgres_service.dart';

class MaintenanceService {
  final PostgresService postgresService;
  
  MaintenanceService({required this.postgresService});

  String _redact(String message, String password) {
    if (password.isEmpty) return message;
    return message.replaceAll(password, '[REDACTED]');
  }

  Future<String> determineMaintenanceAction(String database) async {
    final lastMaintenance = await postgresService.getLastMaintenance(database);
    if (lastMaintenance == null) {
      return 'VACUUM FULL ANALYZE';
    }

    final rawInicio = lastMaintenance['inicio'];
    final inicio = rawInicio is DateTime
        ? rawInicio
        : DateTime.tryParse(rawInicio.toString());
    if (inicio == null) return 'VACUUM FULL ANALYZE';
    final diff = DateTime.now().difference(inicio).inDays;

    if (diff < 30) {
      return 'Nenhuma';
    } else if (diff >= 30 && diff <= 60) {
      return 'VACUUM';
    } else {
      return 'VACUUM FULL ANALYZE';
    }
  }

  Future<void> executeMaintenance({
    required String database,
    required String action,
    required String origemDecisao,
    required String regraAplicada,
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    if (action == 'Nenhuma') return;

    final start = DateTime.now();
    try {
      // VACUUM is executed via a dedicated connection (cannot run inside a transaction).
      await postgresService.executeMaintenance(
        action,
        host: host,
        port: port,
        username: username,
        password: password,
        database: database,
      );
      final end = DateTime.now();
      await postgresService.logMaintenance(
        database: database,
        tipoManutencao: action,
        origemDecisao: origemDecisao,
        regraAplicada: regraAplicada,
        inicio: start,
        fim: end,
        resultado: 'SUCESSO',
      );
    } catch (e) {
      final end = DateTime.now();
      await postgresService.logMaintenance(
        database: database,
        tipoManutencao: action,
        origemDecisao: origemDecisao,
        regraAplicada: regraAplicada,
        inicio: start,
        fim: end,
        resultado: 'FALHA',
        mensagemErro: _redact(e.toString(), password),
      );
      rethrow;
    }
  }
}
