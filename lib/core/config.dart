class AppConfig {
  String host = 'localhost';
  int port = 5432;
  String username = 'postgres';
  String password = '';
  String database = 'postgres';
  String destinationPath = '';
  String additionalDestination = '';
  int retentionCount = 0;
  bool executeMaintenance = true;
  bool fullMaintenance = false;
  bool enableEncryption = false;
  String encryptionPassword = '';
  bool enableCompression = false;
  String compressionPassword = '';
}

final appConfig = AppConfig();
