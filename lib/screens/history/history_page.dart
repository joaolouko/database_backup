import 'package:flutter/material.dart';
import '../../core/database.dart';
import '../../services/service_locator.dart';
import '../../widgets/app_ui.dart';

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
    setState(() => _loading = true);
    final data = await appDatabase.query('execution_history', orderBy: 'id DESC');
    if (mounted) setState(() { _history = data; _loading = false; });
  }

  Future<void> _showLogs(int id) async {
    final logs = await getIt.loggingService.getLogs(id);
    if (!mounted) return;
    showDialog(context: context, builder: (c) => AlertDialog(title: Text('Logs da execução #$id'), content: SizedBox(width: 560, height: 420, child: logs.isEmpty ? const Center(child: Text('Nenhum log registrado.')) : ListView.separated(itemCount: logs.length, separatorBuilder: (_, __) => const Divider(color: AppColors.border), itemBuilder: (_, i) { final log = logs[i]; return ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.article_outlined, color: Color(0xFFA5B4FC)), title: Text('${log['step']}'), subtitle: Text('${log['message']}\n${log['date']}${log['error'] == null ? '' : '\n${log['error']}'}')); })), actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Fechar'))]));
  }

  @override
  Widget build(BuildContext context) {
    final successCount = _history.where((item) => item['status'] == 'success').length;
    final failedCount = _history.where((item) => item['status'] == 'failed').length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppPageHeader(eyebrow: 'Execuções', title: 'Backups', description: 'Acompanhe os backups realizados, seus resultados e os logs de cada execução.', icon: Icons.backup_rounded, trailing: IconButton.filledTonal(onPressed: _loading ? null : _loadHistory, icon: const Icon(Icons.refresh_rounded), tooltip: 'Atualizar histórico')),
        const SizedBox(height: 28),
        Row(children: [Expanded(child: _SummaryCard(label: 'Total', value: '${_history.length}', icon: Icons.history_rounded, color: AppColors.primary)), const SizedBox(width: 12), Expanded(child: _SummaryCard(label: 'Sucesso', value: '$successCount', icon: Icons.check_circle_outline, color: AppColors.success)), const SizedBox(width: 12), Expanded(child: _SummaryCard(label: 'Falhas', value: '$failedCount', icon: Icons.error_outline, color: AppColors.danger))]),
        const SizedBox(height: 18),
        AppSectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppSectionTitle(title: 'Histórico de execuções', subtitle: 'Os registros são mantidos no banco local da aplicação.', icon: Icons.list_alt_rounded),
          const SizedBox(height: 18),
          if (_loading) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())) else if (_history.isEmpty) const AppInfoBanner(message: 'Nenhum backup foi executado ainda.', icon: Icons.inbox_outlined, color: AppColors.textSubtle) else ..._history.map(_historyTile),
        ])),
      ]),
    );
  }

  Widget _historyTile(Map<String, dynamic> record) {
    final status = record['status'] as String? ?? 'failed';
    final success = status == 'success';
    final running = status == 'running';
    final color = success ? AppColors.success : running ? AppColors.warning : AppColors.danger;
    return Container(margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)), child: ListTile(leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(10)), child: Icon(success ? Icons.check_rounded : running ? Icons.pending_rounded : Icons.close_rounded, color: color)), title: Text('${record['database']}  •  ${record['date']}', style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text('Status: $status  |  Duração: ${record['duration']}s  |  Manutenção: ${record['maintenance_decision']}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)), trailing: IconButton(onPressed: () => _showLogs(record['id'] as int), icon: const Icon(Icons.receipt_long_outlined), tooltip: 'Ver logs')));
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)), child: Row(children: [Icon(icon, color: color), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: AppColors.textSubtle, fontSize: 12))])]));
}
