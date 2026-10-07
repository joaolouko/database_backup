import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import '../../core/config.dart';
import '../../core/database.dart';
import '../../services/service_locator.dart';
import '../../widgets/app_ui.dart';

class ConfigurationPage extends StatefulWidget {
  const ConfigurationPage({super.key});

  @override
  State<ConfigurationPage> createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage> {
  bool _testingConnection = false;
  late final TextEditingController _destinationController;
  late final TextEditingController _additionalDestinationController;

  @override
  void initState() {
    super.initState();
    _destinationController = TextEditingController(text: appConfig.destinationPath);
    _additionalDestinationController = TextEditingController(text: appConfig.additionalDestination);
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _additionalDestinationController.dispose();
    super.dispose();
  }

  Future<void> _saveConfiguration() async {
    await saveAppConfig();
    await getIt.secretStore.savePassword('postgres_password', appConfig.password);
    await getIt.secretStore.savePassword('backup_encryption_password', appConfig.encryptionPassword);
    await getIt.secretStore.savePassword('backup_zip_password', appConfig.compressionPassword);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configurações salvas com sucesso.')));
  }

  Future<void> _testConnection() async {
    setState(() => _testingConnection = true);
    try {
      await getIt.postgresService.connect(host: appConfig.host, port: appConfig.port, username: appConfig.username, password: appConfig.password, database: appConfig.database);
      final dbs = await getIt.postgresService.getDatabases();
      await getIt.secretStore.savePassword('postgres_password', appConfig.password);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Conexão bem-sucedida. ${dbs.length} banco(s) encontrado(s).')));
    } catch (e) {
      await getIt.postgresService.disconnect();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha na conexão: $e'), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _testingConnection = false);
    }
  }

  Future<void> _chooseDirectory({required bool additional}) async {
    final dir = await getDirectoryPath();
    if (dir == null || !mounted) return;
    setState(() {
      if (additional) {
        appConfig.additionalDestination = dir;
        _additionalDestinationController.text = dir;
      } else {
        appConfig.destinationPath = dir;
        _destinationController.text = dir;
      }
    });
    await saveAppConfig();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const AppPageHeader(eyebrow: 'Preferências', title: 'Configurações', description: 'Defina a conexão PostgreSQL e as regras de execução dos seus backups.', icon: Icons.settings_rounded),
        const SizedBox(height: 28),
        AppSectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSectionTitle(title: 'Conexão PostgreSQL', subtitle: 'Esses dados são usados para descobrir e acessar os bancos.', icon: Icons.storage_rounded),
          const SizedBox(height: 22),
          LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            final fields = [
              TextFormField(initialValue: appConfig.host, decoration: const InputDecoration(labelText: 'Host', prefixIcon: Icon(Icons.dns_outlined)), onChanged: (v) => appConfig.host = v),
              TextFormField(initialValue: appConfig.port.toString(), decoration: const InputDecoration(labelText: 'Porta', prefixIcon: Icon(Icons.tag)), keyboardType: TextInputType.number, onChanged: (v) => appConfig.port = int.tryParse(v) ?? 5432),
              TextFormField(initialValue: appConfig.database, decoration: const InputDecoration(labelText: 'Database', prefixIcon: Icon(Icons.table_chart_outlined)), onChanged: (v) => appConfig.database = v),
              TextFormField(initialValue: appConfig.username, decoration: const InputDecoration(labelText: 'Usuário', prefixIcon: Icon(Icons.person_outline)), onChanged: (v) => appConfig.username = v),
              TextFormField(initialValue: appConfig.password, decoration: const InputDecoration(labelText: 'Senha (opcional)', prefixIcon: Icon(Icons.lock_outline)), obscureText: true, onChanged: (v) => appConfig.password = v),
            ];
            if (compact) {
              return Column(
                children: fields
                    .map((field) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: field,
                        ))
                    .toList(),
              );
            }
            return Column(children: [
              Row(children: [Expanded(child: fields[0]), const SizedBox(width: 12), Expanded(child: fields[1]), const SizedBox(width: 12), Expanded(child: fields[2])]),
              const SizedBox(height: 12),
              Row(children: [Expanded(child: fields[3]), const SizedBox(width: 12), Expanded(child: fields[4])]),
            ]);
          }),
          const SizedBox(height: 18),
          Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: _testingConnection ? null : _testConnection, icon: _testingConnection ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.link), label: Text(_testingConnection ? 'Testando...' : 'Testar conexão'))),
        ])),
        const SizedBox(height: 18),
        AppSectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSectionTitle(title: 'Destino e retenção', subtitle: 'Escolha onde os arquivos serão salvos e quantos permanecerão.', icon: Icons.folder_copy_outlined),
          const SizedBox(height: 22),
          _DirectoryField(controller: _destinationController, label: 'Destino principal', icon: Icons.folder_outlined, onPick: () => _chooseDirectory(additional: false)),
          const SizedBox(height: 12),
          _DirectoryField(controller: _additionalDestinationController, label: 'Destino adicional (opcional)', icon: Icons.folder_special_outlined, onPick: () => _chooseDirectory(additional: true)),
          const SizedBox(height: 12),
          TextFormField(initialValue: appConfig.retentionCount.toString(), decoration: const InputDecoration(labelText: 'Quantidade de backups a manter (0 = ilimitado)', prefixIcon: Icon(Icons.filter_none_rounded)), keyboardType: TextInputType.number, onChanged: (v) => appConfig.retentionCount = int.tryParse(v) ?? 0),
        ])),
        const SizedBox(height: 18),
        AppSectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSectionTitle(title: 'Processamento do backup', subtitle: 'Configure manutenção, criptografia e compactação.', icon: Icons.tune_rounded),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(value: appConfig.maintenanceMode, decoration: const InputDecoration(labelText: 'Manutenção antes do backup', prefixIcon: Icon(Icons.build_circle_outlined)), items: const [DropdownMenuItem(value: 'automatic', child: Text('Automática pelas regras de data')), DropdownMenuItem(value: 'none', child: Text('Não executar manutenção')), DropdownMenuItem(value: 'vacuum', child: Text('Executar VACUUM manualmente')), DropdownMenuItem(value: 'full', child: Text('Executar VACUUM FULL ANALYZE manualmente'))], onChanged: (value) { if (value == null) return; setState(() { appConfig.maintenanceMode = value; appConfig.executeMaintenance = value != 'none'; appConfig.fullMaintenance = value == 'full'; }); }),
          const SizedBox(height: 8),
          CheckboxListTile(contentPadding: EdgeInsets.zero, title: const Text('Criptografar com AES'), subtitle: const Text('Protege o arquivo antes da compactação.', style: TextStyle(color: AppColors.textSubtle, fontSize: 12)), value: appConfig.enableEncryption, onChanged: (v) => setState(() => appConfig.enableEncryption = v ?? false)),
          if (appConfig.enableEncryption) TextFormField(initialValue: appConfig.encryptionPassword, decoration: const InputDecoration(labelText: 'Senha de criptografia AES', prefixIcon: Icon(Icons.key_outlined)), obscureText: true, onChanged: (v) => appConfig.encryptionPassword = v),
          const SizedBox(height: 6),
          CheckboxListTile(contentPadding: EdgeInsets.zero, title: const Text('Compactar como ZIP protegido'), subtitle: const Text('Reduz o tamanho e aplica uma senha adicional.', style: TextStyle(color: AppColors.textSubtle, fontSize: 12)), value: appConfig.enableCompression, onChanged: (v) => setState(() => appConfig.enableCompression = v ?? false)),
          if (appConfig.enableCompression) TextFormField(initialValue: appConfig.compressionPassword, decoration: const InputDecoration(labelText: 'Senha do ZIP', prefixIcon: Icon(Icons.password_outlined)), obscureText: true, onChanged: (v) => appConfig.compressionPassword = v),
          const SizedBox(height: 20),
          Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: _saveConfiguration, icon: const Icon(Icons.save_outlined), label: const Text('Salvar configurações'))),
        ])),
      ]),
    );
  }
}

class _DirectoryField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final VoidCallback onPick;
  const _DirectoryField({required this.controller, required this.label, required this.icon, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Row(children: [Expanded(child: TextFormField(controller: controller, readOnly: true, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)))), const SizedBox(width: 10), IconButton.filledTonal(onPressed: onPick, icon: const Icon(Icons.folder_open_rounded), tooltip: 'Selecionar pasta')]);
  }
}
