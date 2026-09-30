import 'postgres_service.dart';
import 'backup_service.dart';
import 'logging_service.dart';
import 'encryption_service.dart';
import 'compression_service.dart';
import 'maintenance_service.dart';
import 'secret_store.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late final PostgresService postgresService;
  late final BackupService backupService;
  late final LoggingService loggingService;
  late final EncryptionService encryptionService;
  late final CompressionService compressionService;
  late final MaintenanceService maintenanceService;
  late final SecretStore secretStore;

  void setup() {
    secretStore = SecretStore();
    loggingService = LoggingService();
    postgresService = PostgresService();
    encryptionService = EncryptionService();
    compressionService = CompressionService();
    maintenanceService = MaintenanceService(postgresService: postgresService);
    backupService = BackupService(
      postgresService: postgresService,
      loggingService: loggingService,
      encryptionService: encryptionService,
      compressionService: compressionService,
      maintenanceService: maintenanceService,
    );
  }
}

final getIt = ServiceLocator();
void setupServiceLocator() {
  getIt.setup();
}
