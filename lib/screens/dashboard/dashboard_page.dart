import 'package:flutter/material.dart';
import '../configuration/configuration_page.dart';
import '../history/history_page.dart';
import '../restore/restore_page.dart';
import '../../widgets/dashboard_ui.dart';
import '../../services/service_locator.dart';
import '../../models/models.dart';
import '../../core/config.dart';
import '../../core/database.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedMenu = 0;
  
  List<DatabaseServer> databases = [];
  List<BackupRecord> backups = [];
  
  bool connecting = false;
  bool backupRunning = false;
  
  double backupProgress = 0;
  String? currentBackupDatabase;
  String currentBackupMessage = '';

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }
  
  Future<void> _loadBackups() async {
    final rows = await appDatabase.query(
      'execution_history',
      where: 'status IN (?, ?)',
      whereArgs: [BackupStatus.success.name, BackupStatus.failed.name],
      orderBy: 'id DESC',
    );
    final loaded = rows.map(_recordFromRow).toList();
    if (mounted) {
      setState(() => backups = loaded);
    }
  }

  BackupRecord _recordFromRow(Map<String, dynamic> row) {
    final statusName = row['status'] as String? ?? BackupStatus.failed.name;
    final status = BackupStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => BackupStatus.failed,
    );
    return BackupRecord(
      id: row['id'] as int?,
      database: row['database'] as String? ?? '-',
      date: DateTime.tryParse(row['date'] as String? ?? '') ?? DateTime.now(),
      duration: '${row['duration'] ?? '0'}s',
      status: status,
      filePath: row['file_path'] as String?,
      error: row['error'] as String?,
      maintenanceDecision: row['maintenance_decision'] as String?,
      maintenanceRule: row['maintenance_rule'] as String?,
    );
  }

  void showAddDatabaseDialog() {
    final hostController = TextEditingController(text: appConfig.host);
    final portController = TextEditingController(text: appConfig.port.toString());
    final usernameController = TextEditingController(text: appConfig.username);
    final passwordController = TextEditingController(text: appConfig.password);
    final databaseController = TextEditingController(text: appConfig.database);

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool obscurePassword = true;
        bool loading = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> connect() async {
              setDialogState(() => loading = true);
              try {
                final parsedPort = int.tryParse(portController.text.trim());
                if (parsedPort == null || parsedPort < 1 || parsedPort > 65535) {
                  throw Exception('Porta inválida. Informe um valor entre 1 e 65535.');
                }
                await getIt.postgresService.connect(
                  host: hostController.text,
                  port: parsedPort,
                  username: usernameController.text,
                  password: passwordController.text,
                  database: databaseController.text,
                );
                
                final dbNames = await getIt.postgresService.getDatabases();
                appConfig.host = hostController.text.trim();
                appConfig.port = parsedPort;
                appConfig.username = usernameController.text.trim();
                appConfig.password = passwordController.text;
                appConfig.database = databaseController.text.trim();
                await getIt.secretStore.savePassword('postgres_password', appConfig.password);
                await saveAppConfig();
                databases = dbNames.map((n) => DatabaseServer(
                  name: n,
                  host: hostController.text,
                  port: parsedPort,
                  database: n,
                  username: usernameController.text,
                  environment: n.contains('prod') ? 'PROD' : 'DEV',
                  online: true,
                )).toList();
                
                Navigator.of(dialogContext).pop();
              } catch (e) {
                await getIt.postgresService.disconnect();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
              } finally {
                setDialogState(() => loading = false);
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF111827),
              title: const Text('Conectar PostgreSQL'),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: hostController, decoration: const InputDecoration(labelText: 'Host')),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: portController, decoration: const InputDecoration(labelText: 'Porta'))),
                          const SizedBox(width: 14),
                          Expanded(child: TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Usuário'))),
                        ],
                      ),
                      TextField(controller: passwordController, obscureText: obscurePassword, decoration: const InputDecoration(labelText: 'Senha')),
                      TextField(controller: databaseController, decoration: const InputDecoration(labelText: 'Database')),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: loading ? null : connect,
                  icon: loading ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.link),
                  label: Text(loading ? 'Conectando...' : 'Conectar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void startBackup(DatabaseServer database) async {
    if (appConfig.destinationPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configure o diretório de destino na aba Configurações primeiro!'), backgroundColor: Colors.red));
      return;
    }

    setState(() {
      backupRunning = true;
      backupProgress = 0.1;
      currentBackupDatabase = database.database;
      currentBackupMessage = 'Iniciando pipeline...';
    });
    
    try {
      final record = await getIt.backupService.executeBackupPipeline(
        database: database,
        host: appConfig.host,
        port: appConfig.port,
        username: appConfig.username,
        password: appConfig.password,
        destination: appConfig.destinationPath,
        retentionCount: appConfig.retentionCount,
        additionalDestination: appConfig.additionalDestination,
        executeMaintenance: appConfig.executeMaintenance,
        fullMaintenance: appConfig.fullMaintenance,
        maintenanceMode: appConfig.maintenanceMode,
        encrypt: appConfig.enableEncryption,
        encryptionPassword: appConfig.encryptionPassword,
        compress: appConfig.enableCompression,
        compressPassword: appConfig.compressionPassword,
        onProgress: (step, msg) {
          if (mounted) {
            setState(() {
              backupProgress += 0.05;
              if (backupProgress > 0.95) backupProgress = 0.95;
              currentBackupMessage = '$step: $msg';
            });
          }
        },
      );
      
      if (mounted) {
        setState(() {
          backupRunning = false;
          backupProgress = 1.0;
          currentBackupMessage = 'Sucesso!';
        });
        await _loadBackups();
        if (record.status == BackupStatus.failed) {
          _showError(record.error ?? 'Falha desconhecida');
        }
      }
    } catch (e) {
       if (mounted) {
          setState(() {
            backupRunning = false;
          });
          _showError(e.toString());
       }
    }
  }

  Future<void> disconnectPostgres() async {
    await getIt.postgresService.disconnect();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PostgreSQL desconectado.')),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Color(0xFFF87171)),
              SizedBox(width: 10),
              Text('Erro de Backup (Email Simulado Enviado)'),
            ],
          ),
          content: SelectableText(message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: getIt.postgresService,
      builder: (context, child) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final connected = getIt.postgresService.isConnected;
    final connectedHost = getIt.postgresService.connectedHost;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;

          return Row(
            children: [
              if (!isMobile)
                Sidebar(
                  selectedIndex: selectedMenu,
                  connected: connected,
                  onSelected: (index) {
                    setState(() {
                      selectedMenu = index;
                    });
                  },
                ),
              Expanded(
                child: Column(
                  children: [
                    TopBar(
                      connected: connected,
                      host: connectedHost,
                      onAddDatabase: showAddDatabaseDialog,
                      onDisconnect: disconnectPostgres,
                      onMenu: isMobile ? () { Scaffold.of(context).openDrawer(); } : null,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isMobile ? 18 : 32),
                        child: _buildContent(isMobile),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF111827),
        child: Sidebar(
          selectedIndex: selectedMenu,
          connected: connected,
          onSelected: (index) {
            setState(() { selectedMenu = index; });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _buildContent(bool isMobile) {
    final connected = getIt.postgresService.isConnected;
    final connectedHost = getIt.postgresService.connectedHost;
    if (selectedMenu == 1) {
      return DatabasesPage(
        databases: databases,
        onBackup: startBackup,
        onConnect: showAddDatabaseDialog,
        backupRunning: backupRunning,
      );
    }
    
    // Historico Original substituido pelo nosso HistoryPage (que vem do BD Local)
    if (selectedMenu == 2) {
      return const HistoryPage();
    }
    
    // Configurações e Restaurar
    if (selectedMenu == 3) {
      return const ConfigurationPage();
    }
    
    if (selectedMenu == 4) {
      return const RestorePage();
    }

    return DashboardContent(
      isMobile: isMobile,
      databases: databases,
      backups: backups,
      backupRunning: backupRunning,
      progress: backupProgress,
      currentBackupDatabase: currentBackupDatabase,
      currentBackupMessage: currentBackupMessage,
      onBackup: startBackup,
      onAddDatabase: showAddDatabaseDialog,
      connected: connected,
      host: connectedHost,
    );
  }
}
