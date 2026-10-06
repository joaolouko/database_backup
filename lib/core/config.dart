class AppConfig {
  String host = 'localhost';
  int port = 5432;
  String username = 'postgres';
  String password = '';
  String database = 'postgres';
  String destinationPath = '';
  String additionalDestination = '';
  int retentionCount = 0;
  String maintenanceMode = 'automatic';
  bool executeMaintenance = true;
  bool fullMaintenance = false;
  bool enableEncryption = false;
  String encryptionPassword = '';
  bool enableCompression = false;
  String compressionPassword = '';

  Map<String, String> toStorageMap() => {
        'host': host,
        'port': port.toString(),
        'username': username,
        'database': database,
        'destinationPath': destinationPath,
        'additionalDestination': additionalDestination,
        'retentionCount': retentionCount.toString(),
        'maintenanceMode': maintenanceMode,
        'executeMaintenance': executeMaintenance.toString(),
        'fullMaintenance': fullMaintenance.toString(),
        'enableEncryption': enableEncryption.toString(),
        'enableCompression': enableCompression.toString(),
      };

  void loadFromStorage(Map<String, String> values) {
    host = values['host'] ?? host;
    port = int.tryParse(values['port'] ?? '') ?? port;
    username = values['username'] ?? username;
    database = values['database'] ?? database;
    destinationPath = values['destinationPath'] ?? destinationPath;
    additionalDestination = values['additionalDestination'] ?? additionalDestination;
    retentionCount = int.tryParse(values['retentionCount'] ?? '') ?? retentionCount;
    maintenanceMode = values['maintenanceMode'] ??
        (values['executeMaintenance'] == 'false' ? 'none' : 'automatic');
    executeMaintenance = _parseBool(values['executeMaintenance'], executeMaintenance);
    fullMaintenance = _parseBool(values['fullMaintenance'], fullMaintenance);
    enableEncryption = _parseBool(values['enableEncryption'], enableEncryption);
    enableCompression = _parseBool(values['enableCompression'], enableCompression);
  }

  bool _parseBool(String? value, bool fallback) {
    if (value == null) return fallback;
    return value.toLowerCase() == 'true';
  }
}

final appConfig = AppConfig();
