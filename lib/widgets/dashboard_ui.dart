import 'package:flutter/material.dart';
import '../models/models.dart';
import '../core/config.dart';

// ============================================================
// SIDEBAR
// ============================================================

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelected;
  final bool connected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.connected
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(
          right: BorderSide(
            color: Color(0xFF1E293B),
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 28),

          Padding(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 24,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration:
                  BoxDecoration(
                    color:
                    const Color(0xFF6366F1),
                    borderRadius:
                    BorderRadius.circular(
                      11,
                    ),
                  ),
                  child: const Icon(
                    Icons.storage_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Postgres',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Backup Manager',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                        Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 35),

          _SidebarItem(
            icon:
            Icons.dashboard_rounded,
            title: 'Dashboard',
            selected:
            selectedIndex == 0,
            onTap: () =>
                onSelected(0),
          ),

          _SidebarItem(
            icon:
            Icons.storage_rounded,
            title: 'Bancos de dados',
            selected:
            selectedIndex == 1,
            onTap: () =>
                onSelected(1),
          ),

          _SidebarItem(
            icon:
            Icons.backup_rounded,
            title: 'Backups',
            selected:
            selectedIndex == 2,
            onTap: () =>
                onSelected(2),
          ),

          _SidebarItem(
            icon:
            Icons.settings_rounded,
            title: 'Configurações',
            selected:
            selectedIndex == 3,
            onTap: () =>
                onSelected(3),
          ),

          const Spacer(),

          Container(
            margin:
            const EdgeInsets.all(18),
            padding:
            const EdgeInsets.all(16),
            decoration:
            BoxDecoration(
              color:
              const Color(0xFF111827),
              borderRadius:
              BorderRadius.circular(14),
              border: Border.all(
                color:
                const Color(0xFF1E293B),
              ),
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      connected
                          ? Icons
                          .cloud_done_rounded
                          : Icons
                          .cloud_off_rounded,
                      size: 18,
                      color: connected
                          ? const Color(
                        0xFF22C55E,
                      )
                          : const Color(
                        0xFF64748B,
                      ),
                    ),
                    const SizedBox(
                        width: 8),
                    const Text(
                      'PostgreSQL',
                      style: TextStyle(
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                    height: 10),
                Text(
                  connected
                      ? 'Conectado'
                      : 'Não conectado',
                  style:
                  const TextStyle(
                    fontSize: 12,
                    color:
                    Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 3,
      ),
      child: Material(
        color: selected
            ? const Color(0xFF312E81)
            : Colors.transparent,
        borderRadius:
        BorderRadius.circular(10),
        child: InkWell(
          borderRadius:
          BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: selected
                      ? const Color(
                    0xFFA5B4FC,
                  )
                      : const Color(
                    0xFF64748B,
                  ),
                ),
                const SizedBox(
                    width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : const Color(
                      0xFF94A3B8,
                    ),
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TOP BAR
// ============================================================

class TopBar extends StatelessWidget {
  final bool connected;
  final String? host;
  final VoidCallback onAddDatabase;
  final VoidCallback onDisconnect;
  final VoidCallback? onMenu;

  const TopBar({
    required this.connected,
    required this.host,
    required this.onAddDatabase,
    required this.onDisconnect,
    this.onMenu,
  });

  @override
  Widget build(
      BuildContext context) {
    return Container(
      height: 76,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 28,
      ),
      decoration:
      const BoxDecoration(
        color:
        Color(0xFF0B1120),
        border: Border(
          bottom: BorderSide(
            color:
            Color(0xFF1E293B),
          ),
        ),
      ),
      child: Row(
        children: [
          if (onMenu != null)
            IconButton(
              onPressed: onMenu,
              icon:
              const Icon(Icons.menu),
            ),

          const Expanded(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                Text(
                  'Gerencie seus backups PostgreSQL',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                    Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration:
              BoxDecoration(
                color: connected
                    ? const Color(0xFF052E16)
                    : const Color(0xFF1E293B),
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    connected ? Icons.circle : Icons.cloud_off,
                    size: 8,
                    color: connected
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(
                      width: 7),
                  Text(
                    connected ? (host ?? 'Conectado') : 'Desconectado',
                    style:
                    TextStyle(
                      fontSize: 12,
                      color: connected
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(width: 15),

          FilledButton.icon(
            onPressed: connected ? onDisconnect : onAddDatabase,
            icon: Icon(
              connected ? Icons.link_off : Icons.add,
              size: 18,
            ),
            label: Text(connected ? 'Desconectar' : 'Conectar'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DASHBOARD CONTENT
// ============================================================

class DashboardContent
    extends StatelessWidget {
  final bool isMobile;
  final List<DatabaseServer> databases;
  final List<BackupRecord> backups;
  final bool backupRunning;
  final double progress;
  final String? currentBackupDatabase;
  final String currentBackupMessage;
  final Function(DatabaseServer) onBackup;
  final VoidCallback onAddDatabase;
  final bool connected;
  final String? host;

  const DashboardContent({
    required this.isMobile,
    required this.databases,
    required this.backups,
    required this.backupRunning,
    required this.progress,
    required this.currentBackupDatabase,
    required this.currentBackupMessage,
    required this.onBackup,
    required this.onAddDatabase,
    required this.connected,
    required this.host,
  });

  @override
  Widget build(
      BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        if (!connected)
          _ConnectionWelcome(
            onConnect: onAddDatabase,
          ),

        if (!connected)
          const SizedBox(height: 20),

        if (backupRunning)
          _BackupProgressCard(
            progress: progress,
            database:
            currentBackupDatabase,
            message:
            currentBackupMessage,
          ),

        if (backupRunning)
          const SizedBox(height: 20),

        GridView.count(
          crossAxisCount:
          isMobile ? 1 : 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics:
          const NeverScrollableScrollPhysics(),
          childAspectRatio:
          isMobile ? 3.2 : 1.5,
          children: [
            _StatCard(
              title:
              'Bancos encontrados',
              value:
              '${databases.length}',
              subtitle: connected
                  ? 'Servidor conectado'
                  : 'Conecte um servidor',
              icon:
              Icons.storage_rounded,
              color:
              const Color(0xFF6366F1),
            ),
            _StatCard(
              title:
              'Backups realizados',
              value:
              '${backups.length}',
              subtitle:
              'Nesta sessão',
              icon:
              Icons.backup_rounded,
              color:
              const Color(0xFF22C55E),
            ),
            _StatCard(
              title:
              'Backups com sucesso',
              value:
              '${backups.where((b) => b.status == BackupStatus.success).length}',
              subtitle:
              'Arquivos criados',
              icon:
              Icons.check_circle_rounded,
              color:
              const Color(0xFF0EA5E9),
            ),
            _StatCard(
              title:
              'Falhas',
              value:
              '${backups.where((b) => b.status == BackupStatus.failed).length}',
              subtitle:
              'Nesta sessão',
              icon:
              Icons.error_rounded,
              color:
              const Color(0xFFEF4444),
            ),
          ],
        ),

        const SizedBox(height: 30),

        Row(
          children: [
            const Expanded(
              child: Text(
                'Bancos de dados',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed:
              onAddDatabase,
              child: const Text(
                  'Conectar servidor'),
            ),
          ],
        ),

        const SizedBox(height: 14),

        if (databases.isEmpty)
          _EmptyDatabases(
            onConnect: onAddDatabase,
          )
        else
          _DatabaseTable(
            databases: databases,
            onBackup: onBackup,
            backupRunning:
            backupRunning,
          ),

        const SizedBox(height: 30),

        const Text(
          'Backups recentes',
          style: TextStyle(
            fontSize: 19,
            fontWeight:
            FontWeight.bold,
          ),
        ),

        const SizedBox(height: 14),

        if (backups.isEmpty)
          const _EmptyBackups()
        else
          _BackupTable(
            backups: backups,
          ),
      ],
    );
  }
}

// ============================================================
// WELCOME
// ============================================================

class _ConnectionWelcome
    extends StatelessWidget {
  final VoidCallback onConnect;

  const _ConnectionWelcome({
    required this.onConnect,
  });

  @override
  Widget build(
      BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient:
        const LinearGradient(
          colors: [
            Color(0xFF1E1B4B),
            Color(0xFF172554),
          ],
        ),
        borderRadius:
        BorderRadius.circular(15),
        border: Border.all(
          color:
          const Color(0xFF3730A3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration:
            BoxDecoration(
              color:
              const Color(0xFF6366F1)
                  .withValues(
                alpha: .15,
              ),
              borderRadius:
              BorderRadius.circular(
                13,
              ),
            ),
            child: const Icon(
              Icons.storage_rounded,
              size: 28,
              color:
              Color(0xFFA5B4FC),
            ),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Conecte seu servidor PostgreSQL',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Informe host, porta, usuário e senha para descobrir automaticamente os bancos disponíveis.',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                    Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onConnect,
            icon:
            const Icon(Icons.link),
            label:
            const Text('Conectar'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EMPTY STATES
// ============================================================

class _EmptyDatabases
    extends StatelessWidget {
  final VoidCallback onConnect;

  const _EmptyDatabases({
    required this.onConnect,
  });

  @override
  Widget build(
      BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.all(35),
      width: double.infinity,
      decoration: BoxDecoration(
        color:
        const Color(0xFF111827),
        borderRadius:
        BorderRadius.circular(15),
        border: Border.all(
          color:
          const Color(0xFF1E293B),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.storage_outlined,
            size: 45,
            color:
            Color(0xFF475569),
          ),
          const SizedBox(height: 12),
          const Text(
            'Nenhum banco encontrado',
            style: TextStyle(
              fontWeight:
              FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Conecte-se a um servidor PostgreSQL.',
            style: TextStyle(
              color:
              Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: onConnect,
            child:
            const Text('Conectar'),
          ),
        ],
      ),
    );
  }
}

class _EmptyBackups
    extends StatelessWidget {
  const _EmptyBackups();

  @override
  Widget build(
      BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.all(30),
      width: double.infinity,
      decoration: BoxDecoration(
        color:
        const Color(0xFF111827),
        borderRadius:
        BorderRadius.circular(15),
        border: Border.all(
          color:
          const Color(0xFF1E293B),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.backup_outlined,
            size: 40,
            color:
            Color(0xFF475569),
          ),
          SizedBox(height: 12),
          Text(
            'Nenhum backup realizado ainda.',
            style: TextStyle(
              color:
              Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STAT CARD
// ============================================================

class _StatCard
    extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(
      BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
        const Color(0xFF111827),
        borderRadius:
        BorderRadius.circular(15),
        border: Border.all(
          color:
          const Color(0xFF1E293B),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration:
            BoxDecoration(
              color:
              color.withValues(
                alpha: .12,
              ),
              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(
              width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontSize: 12,
                    color:
                    Color(0xFF64748B),
                  ),
                ),
                const SizedBox(
                    height: 5),
                Text(
                  value,
                  style:
                  const TextStyle(
                    fontSize: 22,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style:
                  const TextStyle(
                    fontSize: 11,
                    color:
                    Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DATABASE TABLE
// ============================================================

class _DatabaseTable
    extends StatelessWidget {
  final List<DatabaseServer> databases;
  final Function(DatabaseServer) onBackup;
  final bool backupRunning;

  const _DatabaseTable({
    required this.databases,
    required this.onBackup,
    required this.backupRunning,
  });

  @override
  Widget build(
      BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:
        const Color(0xFF111827),
        borderRadius:
        BorderRadius.circular(15),
        border: Border.all(
          color:
          const Color(0xFF1E293B),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection:
        Axis.horizontal,
        child: DataTable(
          headingRowColor:
          WidgetStateProperty.all(
            const Color(0xFF0F172A),
          ),
          columns: const [
            DataColumn(
              label: Text('Banco'),
            ),
            DataColumn(
              label: Text('Host'),
            ),
            DataColumn(
              label: Text('Porta'),
            ),
            DataColumn(
              label: Text('Ambiente'),
            ),
            DataColumn(
              label: Text('Status'),
            ),
            DataColumn(
              label: Text('Ações'),
            ),
          ],
          rows:
          databases.map((database) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      const Icon(
                        Icons
                            .storage_rounded,
                        size: 18,
                        color:
                        Color(0xFF6366F1),
                      ),
                      const SizedBox(
                          width: 10),
                      Text(
                        database.database,
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    database.host,
                    style:
                    const TextStyle(
                      color:
                      Color(0xFF94A3B8),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${database.port}',
                  ),
                ),
                DataCell(
                  _EnvironmentBadge(
                    environment:
                    database.environment,
                  ),
                ),
                DataCell(
                  const _StatusBadge(
                    online: true,
                  ),
                ),
                DataCell(
                  FilledButton.icon(
                    onPressed:
                    backupRunning
                        ? null
                        : () =>
                        onBackup(
                          database,
                        ),
                    icon: const Icon(
                      Icons
                          .backup_rounded,
                      size: 16,
                    ),
                    label: const Text(
                      'Backup',
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ============================================================
// BACKUP TABLE
// ============================================================

class _BackupTable
    extends StatelessWidget {
  final List<BackupRecord> backups;

  const _BackupTable({
    required this.backups,
  });

  @override
  Widget build(
      BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:
        const Color(0xFF111827),
        borderRadius:
        BorderRadius.circular(15),
        border: Border.all(
          color:
          const Color(0xFF1E293B),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection:
        Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(
              label: Text('Banco'),
            ),
            DataColumn(
              label: Text('Data'),
            ),
            DataColumn(
              label: Text('Tamanho'),
            ),
            DataColumn(
              label: Text('Duração'),
            ),
            DataColumn(
              label: Text('Status'),
            ),
            DataColumn(
              label: Text('Arquivo'),
            ),
          ],
          rows: backups.map((backup) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    backup.database,
                  ),
                ),
                DataCell(
                  Text(
                    _formatDate(
                      backup.date,
                    ),
                    style:
                    const TextStyle(
                      color:
                      Color(0xFF94A3B8),
                    ),
                  ),
                ),
                DataCell(
                  Text('-'),
                ),
                DataCell(
                  Text(
                    backup.duration,
                  ),
                ),
                DataCell(
                  _BackupStatus(
                    status:
                    backup.status,
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 220,
                    child: Text(
                      backup.filePath ??
                          backup.error ??
                          '-',
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      const TextStyle(
                        fontSize: 11,
                        color:
                        Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatDate(
      DateTime date) {
    final hour =
    date.hour.toString().padLeft(
      2,
      '0',
    );

    final minute =
    date.minute.toString().padLeft(
      2,
      '0',
    );

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')} '
        '$hour:$minute';
  }
}

// ============================================================
// PROGRESS
// ============================================================

class _BackupProgressCard
    extends StatelessWidget {
  final double progress;
  final String? database;
  final String message;

  const _BackupProgressCard({
    required this.progress,
    required this.database,
    required this.message,
  });

  @override
  Widget build(
      BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient:
        const LinearGradient(
          colors: [
            Color(0xFF1E1B4B),
            Color(0xFF172554),
          ],
        ),
        borderRadius:
        BorderRadius.circular(15),
        border: Border.all(
          color:
          const Color(0xFF3730A3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(
                  width: 12),
              Expanded(
                child: Text(
                  database == null
                      ? 'Executando backup...'
                      : 'Backup: $database',
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style:
                const TextStyle(
                  fontWeight:
                  FontWeight.bold,
                  color:
                  Color(0xFFA5B4FC),
                ),
              ),
            ],
          ),
          const SizedBox(
              height: 15),
          LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            borderRadius:
            BorderRadius.circular(
              10,
            ),
          ),
          const SizedBox(
              height: 10),
          Align(
            alignment:
            Alignment.centerLeft,
            child: Text(
              message.isEmpty
                  ? 'Executando pg_dump...'
                  : message,
              style:
              const TextStyle(
                fontSize: 12,
                color:
                Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BADGES
// ============================================================

class _StatusBadge
    extends StatelessWidget {
  final bool online;

  const _StatusBadge({
    required this.online,
  });

  @override
  Widget build(
      BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration:
      BoxDecoration(
        color: online
            ? const Color(0xFF052E16)
            : const Color(0xFF450A0A),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration:
            BoxDecoration(
              shape:
              BoxShape.circle,
              color: online
                  ? const Color(
                0xFF22C55E,
              )
                  : const Color(
                0xFFEF4444,
              ),
            ),
          ),
          const SizedBox(
              width: 7),
          Text(
            online
                ? 'Online'
                : 'Offline',
            style:
            TextStyle(
              fontSize: 12,
              color: online
                  ? const Color(
                0xFF4ADE80,
              )
                  : const Color(
                0xFFF87171,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnvironmentBadge
    extends StatelessWidget {
  final String environment;

  const _EnvironmentBadge({
    required this.environment,
  });

  @override
  Widget build(
      BuildContext context) {
    Color color;

    switch (environment) {
      case 'PROD':
        color =
        const Color(0xFFF97316);
        break;

      case 'STAGING':
        color =
        const Color(0xFFEAB308);
        break;

      case 'DEV':
        color =
        const Color(0xFF3B82F6);
        break;

      default:
        color =
        const Color(0xFF8B5CF6);
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration:
      BoxDecoration(
        color:
        color.withValues(
          alpha: .12,
        ),
        borderRadius:
        BorderRadius.circular(6),
      ),
      child: Text(
        environment,
        style:
        TextStyle(
          color: color,
          fontSize: 11,
          fontWeight:
          FontWeight.bold,
        ),
      ),
    );
  }
}

class _BackupStatus
    extends StatelessWidget {
  final BackupStatus status;

  const _BackupStatus({
    required this.status,
  });

  @override
  Widget build(
      BuildContext context) {
    switch (status) {
      case BackupStatus.success:
        return const _StatusChip(
          label: 'Sucesso',
          color:
          Color(0xFF22C55E),
          icon:
          Icons.check_circle_rounded,
        );

      case BackupStatus.pending:
        return const _StatusChip(label: 'Pendente', color: Color(0xFF64748B), icon: Icons.pending);
      case BackupStatus.running:
        return const _StatusChip(
          label: 'Executando',
          color:
          Color(0xFF3B82F6),
          icon:
          Icons.sync_rounded,
        );

      case BackupStatus.failed:
        return const _StatusChip(
          label: 'Falhou',
          color:
          Color(0xFFEF4444),
          icon:
          Icons.error_rounded,
        );
    }
  }
}

class _StatusChip
    extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(
      BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration:
      BoxDecoration(
        color:
        color.withValues(
          alpha: .10,
        ),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(
              width: 6),
          Text(
            label,
            style:
            TextStyle(
              fontSize: 11,
              color: color,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DATABASES PAGE
// ============================================================

class DatabasesPage
    extends StatelessWidget {
  final List<DatabaseServer> databases;
  final Function(DatabaseServer) onBackup;
  final VoidCallback onConnect;
  final bool backupRunning;

  const DatabasesPage({
    required this.databases,
    required this.onBackup,
    required this.onConnect,
    required this.backupRunning,
  });

  @override
  Widget build(
      BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Bancos de dados',
                style:
                TextStyle(
                  fontSize: 24,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: onConnect,
              icon:
              const Icon(Icons.link),
              label:
              const Text('Conectar'),
            ),
          ],
        ),

        const SizedBox(
            height: 8),

        const Text(
          'Bancos encontrados diretamente no servidor PostgreSQL.',
          style: TextStyle(
            color:
            Color(0xFF64748B),
          ),
        ),

        const SizedBox(
            height: 25),

        if (databases.isEmpty)
          _EmptyDatabases(
            onConnect: onConnect,
          )
        else
          _DatabaseTable(
            databases: databases,
            onBackup: onBackup,
            backupRunning:
            backupRunning,
          ),
      ],
    );
  }
}

// ============================================================
// BACKUPS PAGE
// ============================================================

class _BackupsPage
    extends StatelessWidget {
  final List<BackupRecord> backups;

  const _BackupsPage({
    required this.backups,
  });

  @override
  Widget build(
      BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'Histórico de backups',
          style:
          TextStyle(
            fontSize: 24,
            fontWeight:
            FontWeight.bold,
          ),
        ),

        const SizedBox(
            height: 8),

        const Text(
          'Backups realizados durante a execução da aplicação.',
          style: TextStyle(
            color:
            Color(0xFF64748B),
          ),
        ),

        const SizedBox(
            height: 25),

        backups.isEmpty
            ? const _EmptyBackups()
            : _BackupTable(
          backups: backups,
        ),
      ],
    );
  }
}

// ============================================================
// SETTINGS
// ============================================================

class _SettingsPage
    extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(
      BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'Configurações',
          style:
          TextStyle(
            fontSize: 24,
            fontWeight:
            FontWeight.bold,
          ),
        ),

        const SizedBox(
            height: 25),

        const _SettingCard(
          icon:
          Icons.backup_rounded,
          title:
          'Formato do backup',
          description:
          'Os backups são gerados utilizando o formato custom do PostgreSQL (.dump).',
        ),

        const _SettingCard(
          icon:
          Icons.computer_rounded,
          title:
          'Execução local',
          description:
          'O pg_dump é executado diretamente nesta máquina pelo aplicativo Flutter.',
        ),

        const _SettingCard(
          icon:
          Icons.storage_rounded,
          title:
          'PostgreSQL',
          description:
          'A conexão e descoberta dos bancos são realizadas diretamente pelo aplicativo.',
        ),
      ],
    );
  }
}

class _SettingCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _SettingCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(
      BuildContext context) {
    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
      const EdgeInsets.all(20),
      decoration:
      BoxDecoration(
        color:
        const Color(0xFF111827),
        borderRadius:
        BorderRadius.circular(15),
        border: Border.all(
          color:
          const Color(0xFF1E293B),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration:
            BoxDecoration(
              color:
              const Color(
                0xFF6366F1,
              ).withValues(
                alpha: .12,
              ),
              borderRadius:
              BorderRadius.circular(
                11,
              ),
            ),
            child: Icon(
              icon,
              color:
              const Color(
                0xFFA5B4FC,
              ),
            ),
          ),
          const SizedBox(
              width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
                const SizedBox(
                    height: 5),
                Text(
                  description,
                  style:
                  const TextStyle(
                    fontSize: 12,
                    color:
                    Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DIALOG FIELD
// ============================================================



