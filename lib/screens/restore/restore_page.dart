import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import '../../core/config.dart';
import '../../services/service_locator.dart';

class RestorePage extends StatefulWidget {
  const RestorePage({super.key});

  @override
  State<RestorePage> createState() => _RestorePageState();
}

class _RestorePageState extends State<RestorePage> {
  String? _selectedFile;
  bool _isEncrypted = false;
  String _encryptionPassword = '';
  bool _isCompressed = false;
  String _compressionPassword = '';
  
  bool _isRunning = false;
  String _currentStep = '';
  String _currentMessage = '';
  
  void _pickFile() async {
    const XTypeGroup group = XTypeGroup(
      label: 'Backups',
      extensions: ['dump', 'aes', 'zip'],
    );
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file != null) {
      setState(() {
        _selectedFile = file.path;
      });
    }
  }

  void _startRestore() async {
    if (_selectedFile == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um arquivo de backup.'), backgroundColor: Colors.red));
       return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirmar Restauração'),
        content: Text('Isso sobrescreverá os dados no banco ${appConfig.database}. Tem certeza?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Restaurar')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isRunning = true;
      _currentStep = 'Iniciando';
      _currentMessage = 'Preparando restauração...';
    });

    try {
      await getIt.backupService.executeRestore(
        filePath: _selectedFile!,
        host: appConfig.host,
        port: appConfig.port,
        username: appConfig.username,
        password: appConfig.password,
        database: appConfig.database,
        isEncrypted: _isEncrypted,
        encryptionPassword: _encryptionPassword,
        isCompressed: _isCompressed,
        compressPassword: _compressionPassword,
        onProgress: (step, msg) {
          if (mounted) {
            setState(() {
              _currentStep = step;
              _currentMessage = msg;
            });
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restauração e verificação concluídas com sucesso!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Erro de Restauração'),
            content: SingleChildScrollView(child: Text(e.toString())),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: const Text('Fechar')),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRunning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Restaurar Backup', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedFile ?? 'Nenhum arquivo selecionado',
                          style: TextStyle(color: _selectedFile == null ? Colors.grey : Colors.white),
                        ),
                      ),
                      ElevatedButton(onPressed: _pickFile, child: const Text('Selecionar Arquivo')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  CheckboxListTile(
                    title: const Text('Arquivo está criptografado (AES)'),
                    value: _isEncrypted,
                    onChanged: (v) => setState(() => _isEncrypted = v ?? false),
                  ),
                  if (_isEncrypted)
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Senha de Descriptografia'),
                      obscureText: true,
                      onChanged: (v) => _encryptionPassword = v,
                    ),
                  CheckboxListTile(
                    title: const Text('Arquivo está compactado (ZIP)'),
                    value: _isCompressed,
                    onChanged: (v) => setState(() => _isCompressed = v ?? false),
                  ),
                  if (_isCompressed)
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Senha de Descompactação'),
                      obscureText: true,
                      onChanged: (v) => _compressionPassword = v,
                    ),
                  const SizedBox(height: 32),
                  if (_isRunning) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text('Etapa: $_currentStep', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 10),
                    Text(_currentMessage, textAlign: TextAlign.center),
                  ] else ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _startRestore,
                      icon: const Icon(Icons.restore),
                      label: const Text('Iniciar Restauração', style: TextStyle(fontSize: 18)),
                    ),
                  ]
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
