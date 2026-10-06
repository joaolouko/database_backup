import 'package:flutter/material.dart';
import '../../core/config.dart';
import '../../services/service_locator.dart';
import '../../models/models.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool _isRunning = false;
  String _currentStep = 'Aguardando início...';
  String _currentMessage = '';

  void _startBackup() async {
    if (appConfig.destinationPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configure o diretório de destino primeiro!'), backgroundColor: Colors.red),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirmar Backup'),
        content: Text('Deseja iniciar o backup do banco ${appConfig.database}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Iniciar')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isRunning = true;
      _currentStep = 'Iniciando';
      _currentMessage = 'Preparando...';
    });

    try {
      final record = await getIt.backupService.executeBackupPipeline(
        database: DatabaseServer(
          name: appConfig.database,
          host: appConfig.host,
          port: appConfig.port,
          database: appConfig.database,
          username: appConfig.username,
          environment: 'DB',
          online: true,
        ),
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
              _currentStep = step;
              _currentMessage = msg;
            });
          }
        },
      );

      if (mounted) {
        if (record.status == BackupStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup concluído com sucesso!'), backgroundColor: Colors.green),
          );
        } else {
          _showError('Backup falhou: ${record.error}');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Erro não tratado: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRunning = false;
        });
      }
    }
  }

  void _showError(String error) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Erro de Backup'),
        content: SingleChildScrollView(child: Text(error)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Fechar')),
          FilledButton(
            onPressed: () {
              Navigator.pop(c);
              _simulateEmail(error);
            }, 
            child: const Text('Simular Envio de Email do Log')
          ),
        ],
      ),
    );
  }

  void _simulateEmail(String content) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Email Simulado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Destinatário: admin@sistema.com'),
            const Text('Assunto: Falha no Backup'),
            Text('Data/hora: ${DateTime.now()}'),
            const SizedBox(height: 10),
            const Text('Status: Enviado com sucesso', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Execução de Backup', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text('Banco Alvo: ${appConfig.database}', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  Text('Destino: ${appConfig.destinationPath.isEmpty ? "Não configurado" : appConfig.destinationPath}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 24),
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
                      ),
                      onPressed: _startBackup,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Iniciar Pipeline de Backup', style: TextStyle(fontSize: 18)),
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
