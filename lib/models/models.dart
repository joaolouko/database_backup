enum BackupStatus {
  pending,
  running,
  success,
  failed,
}

class DatabaseServer {
  final String name;
  final String host;
  final int port;
  final String database;
  final String username;
  final String environment;
  final bool online;

  const DatabaseServer({
    required this.name,
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.environment,
    required this.online,
  });
}

class BackupRecord {
  final int? id;
  final String database;
  final DateTime date;
  final String duration;
  final BackupStatus status;
  final String? filePath;
  final String? error;
  final String? maintenanceDecision;
  final String? maintenanceRule;

  const BackupRecord({
    this.id,
    required this.database,
    required this.date,
    required this.duration,
    required this.status,
    this.filePath,
    this.error,
    this.maintenanceDecision,
    this.maintenanceRule,
  });
}
