import 'package:flutter/material.dart';
import '../../core/database.dart';
import '../../services/service_locator.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await appDatabase.query('execution_history', orderBy: 'id DESC');
    if (mounted) {
      setState(() {
        _history = data;
        _loading = false;
      });
    }
  }

  void _showLogs(int id) async {
    final logs = await getIt.loggingService.getLogs(id);
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('Logs da Execução #$id'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: logs.length,
              itemBuilder: (ctx, i) {
                final log = logs[i];
                return ListTile(
                  title: Text('${log["step"]} - ${log["message"]}'),
                  subtitle: Text('${log["date"]}\n${log["error"] ?? ""}'),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Fechar'))
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Histórico de Execuções', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHistory),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _history.isEmpty
                    ? const Center(child: Text('Nenhum histórico encontrado.'))
                    : ListView.builder(
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final record = _history[index];
                          final isSuccess = record['status'] == 'success';
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                isSuccess ? Icons.check_circle : Icons.error,
                                color: isSuccess ? Colors.green : Colors.red,
                              ),
                              title: Text('${record["database"]} - ${record["date"]}'),
                              subtitle: Text('Duração: ${record["duration"]}s | Manutenção: ${record["maintenance_decision"]}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.receipt_long),
                                onPressed: () => _showLogs(record['id'] as int),
                                tooltip: 'Ver Logs',
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
