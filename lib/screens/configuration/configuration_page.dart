import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import '../../core/config.dart';
import '../../services/service_locator.dart';

class ConfigurationPage extends StatefulWidget {
  const ConfigurationPage({super.key});

  @override
  State<ConfigurationPage> createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage> {
  bool _testingConnection = false;

  void _testConnection() async {
    setState(() {
      _testingConnection = true;
    });
    
    try {
      await getIt.postgresService.connect(
        host: appConfig.host,
        port: appConfig.port,
        username: appConfig.username,
        password: appConfig.password,
        database: appConfig.database,
      );
      
      final dbs = await getIt.postgresService.getDatabases();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Conexão bem-sucedida! ${dbs.length} bancos encontrados.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha na conexão: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _testingConnection = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Configuração de Banco de Dados', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: appConfig.host,
                      decoration: const InputDecoration(labelText: 'Host'),
                      onChanged: (v) => appConfig.host = v,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: appConfig.port.toString(),
                            decoration: const InputDecoration(labelText: 'Porta'),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => appConfig.port = int.tryParse(v) ?? 5432,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            initialValue: appConfig.database,
                            decoration: const InputDecoration(labelText: 'Database'),
                            onChanged: (v) => appConfig.database = v,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: appConfig.username,
                            decoration: const InputDecoration(labelText: 'Usuário'),
                            onChanged: (v) => appConfig.username = v,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            initialValue: appConfig.password,
                            decoration: const InputDecoration(labelText: 'Senha'),
                            obscureText: true,
                            onChanged: (v) => appConfig.password = v,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _testingConnection ? null : _testConnection,
                      icon: _testingConnection ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.link),
                      label: const Text('Testar Conexão'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Configuração de Backup', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: TextEditingController(text: appConfig.destinationPath),
                            decoration: const InputDecoration(labelText: 'Destino Principal (Diretório)'),
                            readOnly: true,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.folder),
                          onPressed: () async {
                            final dir = await getDirectoryPath();
                            if (dir != null) {
                              setState(() {
                                appConfig.destinationPath = dir;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: TextEditingController(text: appConfig.additionalDestination),
                            decoration: const InputDecoration(labelText: 'Destino Adicional (Opcional)'),
                            readOnly: true,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.folder_copy),
                          onPressed: () async {
                            final dir = await getDirectoryPath();
                            if (dir != null) {
                              setState(() {
                                appConfig.additionalDestination = dir;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    TextFormField(
                      initialValue: appConfig.retentionCount.toString(),
                      decoration: const InputDecoration(labelText: 'Quantidade a manter (0 = Ilimitado)'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => appConfig.retentionCount = int.tryParse(v) ?? 0,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Opções Adicionais', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CheckboxListTile(
                      title: const Text('Executar manutenção antes do backup (VACUUM / VACUUM FULL ANALYZE)'),
                      value: appConfig.executeMaintenance,
                      onChanged: (v) => setState(() => appConfig.executeMaintenance = v ?? false),
                    ),
                    if (appConfig.executeMaintenance)
                      CheckboxListTile(
                        title: const Text('Manutenção completa forçada (VACUUM FULL ANALYZE)'),
                        value: appConfig.fullMaintenance,
                        onChanged: (v) => setState(() => appConfig.fullMaintenance = v ?? false),
                      ),
                    CheckboxListTile(
                      title: const Text('Criptografar (AES)'),
                      value: appConfig.enableEncryption,
                      onChanged: (v) => setState(() => appConfig.enableEncryption = v ?? false),
                    ),
                    if (appConfig.enableEncryption)
                      TextFormField(
                        initialValue: appConfig.encryptionPassword,
                        decoration: const InputDecoration(labelText: 'Senha de Criptografia'),
                        obscureText: true,
                        onChanged: (v) => appConfig.encryptionPassword = v,
                      ),
                    CheckboxListTile(
                      title: const Text('Compactar (ZIP protegido)'),
                      value: appConfig.enableCompression,
                      onChanged: (v) => setState(() => appConfig.enableCompression = v ?? false),
                    ),
                    if (appConfig.enableCompression)
                      TextFormField(
                        initialValue: appConfig.compressionPassword,
                        decoration: const InputDecoration(labelText: 'Senha do ZIP'),
                        obscureText: true,
                        onChanged: (v) => appConfig.compressionPassword = v,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
