import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import '../../core/config.dart';
import '../../services/service_locator.dart';
import '../../widgets/app_ui.dart';

class RestorePage extends StatefulWidget {
  const RestorePage({super.key});

  @override
  State<RestorePage> createState() => _RestorePageState();
}

class _RestorePageState extends State<RestorePage> {
  String? _selectedFile;
  bool _isEncrypted = false;
  bool _isCompressed = false;
  String _encryptionPassword = '';
  String _compressionPassword = '';
  bool _isRunning = false;
  String _currentStep = '';
  String _currentMessage = '';

  Future<void> _pickFile() async {
    const group = XTypeGroup(label: 'Backups', extensions: ['dump', 'aes', 'zip']);
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file != null && mounted) setState(() => _selectedFile = file.path);
  }

  Future<void> _startRestore() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um arquivo de backup.'), backgroundColor: AppColors.danger));
      return;
    }
    final confirmed = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Confirmar restauração'), content: Text('Os dados do banco ${appConfig.database} serão sobrescritos. Deseja continuar?'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Restaurar'))]));
    if (confirmed != true || !mounted) return;
    setState(() { _isRunning = true; _currentStep = 'Iniciando'; _currentMessage = 'Preparando restauração...'; });
    try {
      await getIt.backupService.executeRestore(filePath: _selectedFile!, host: appConfig.host, port: appConfig.port, username: appConfig.username, password: appConfig.password, database: appConfig.database, isEncrypted: _isEncrypted, encryptionPassword: _encryptionPassword, isCompressed: _isCompressed, compressPassword: _compressionPassword, onProgress: (step, message) { if (mounted) setState(() { _currentStep = step; _currentMessage = message; }); });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restauração e verificação concluídas com sucesso.')));
    } catch (e) {
      if (mounted) showDialog(context: context, builder: (c) => AlertDialog(title: const Text('Erro de restauração'), content: SingleChildScrollView(child: Text(e.toString())), actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Fechar'))]));
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const AppPageHeader(eyebrow: 'Recuperação', title: 'Restaurar backup', description: 'Selecione um arquivo e restaure os dados com validação de integridade.', icon: Icons.restore_rounded),
        const SizedBox(height: 28),
        AppInfoBanner(message: 'A restauração pode sobrescrever dados existentes no banco configurado. Confira o arquivo e as senhas antes de iniciar.', icon: Icons.warning_amber_rounded, color: AppColors.warning),
        const SizedBox(height: 18),
        AppSectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSectionTitle(title: 'Arquivo de backup', subtitle: 'Formatos aceitos: .dump, .aes e .zip.', icon: Icons.insert_drive_file_outlined),
          const SizedBox(height: 20),
          InkWell(
            onTap: _isRunning ? null : _pickFile,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: _selectedFile == null ? AppColors.border : AppColors.primary)),
              child: Row(children: [
                Icon(_selectedFile == null ? Icons.upload_file_rounded : Icons.check_circle_rounded, color: _selectedFile == null ? AppColors.textSubtle : AppColors.success, size: 28),
                const SizedBox(width: 14),
                Expanded(child: Text(_selectedFile ?? 'Nenhum arquivo selecionado\nClique para escolher um backup', style: TextStyle(color: _selectedFile == null ? AppColors.textMuted : Colors.white, fontSize: 13))),
                OutlinedButton.icon(onPressed: _isRunning ? null : _pickFile, icon: const Icon(Icons.folder_open_rounded, size: 18), label: const Text('Selecionar')),
              ]),
            ),
          ),
          const SizedBox(height: 22),
          const Divider(color: AppColors.border),
          const SizedBox(height: 14),
          const Text('Opções do arquivo', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          CheckboxListTile(contentPadding: EdgeInsets.zero, title: const Text('Arquivo criptografado com AES'), value: _isEncrypted, onChanged: _isRunning ? null : (v) => setState(() => _isEncrypted = v ?? false)),
          if (_isEncrypted) Padding(padding: const EdgeInsets.only(bottom: 8), child: TextFormField(decoration: const InputDecoration(labelText: 'Senha de descriptografia', prefixIcon: Icon(Icons.key_outlined)), obscureText: true, onChanged: (v) => _encryptionPassword = v)),
          CheckboxListTile(contentPadding: EdgeInsets.zero, title: const Text('Arquivo compactado como ZIP protegido'), value: _isCompressed, onChanged: _isRunning ? null : (v) => setState(() => _isCompressed = v ?? false)),
          if (_isCompressed) TextFormField(decoration: const InputDecoration(labelText: 'Senha do ZIP', prefixIcon: Icon(Icons.password_outlined)), obscureText: true, onChanged: (v) => _compressionPassword = v),
        ])),
        const SizedBox(height: 18),
        AppSectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSectionTitle(title: 'Destino da restauração', subtitle: 'Conexão definida em Configurações.', icon: Icons.storage_rounded),
          const SizedBox(height: 18),
          Row(children: [const Icon(Icons.dns_outlined, color: AppColors.textSubtle), const SizedBox(width: 10), Expanded(child: Text('${appConfig.host}:${appConfig.port}  •  ${appConfig.database}', style: const TextStyle(fontWeight: FontWeight.w600))), const Icon(Icons.lock_outline, size: 17, color: AppColors.success)]),
          if (_isRunning) ...[const SizedBox(height: 22), LinearProgressIndicator(color: AppColors.primary, backgroundColor: AppColors.border), const SizedBox(height: 12), Text(_currentStep, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(_currentMessage, style: const TextStyle(color: AppColors.textMuted))] else ...[const SizedBox(height: 22), Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: _startRestore, icon: const Icon(Icons.restore_rounded), label: const Text('Iniciar restauração')))],
        ])),
      ]),
    );
  }
}
