import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'config.dart';

late Database appDatabase;

Future<void> initDatabase() async {
  // Em desenvolvimento, manter o banco no projeto permite que `flutter clean`
  // remova o estado local junto com os artefatos de desenvolvimento.
  final projectDir = Directory.current;
  final dbPath = join(
    projectDir.path,
    '.dart_tool',
    'sqflite_common_ffi',
    'databases',
    'app.db',
  );

  final dir = Directory(dirname(dbPath));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  final newDbFile = File(dbPath);
  if (!await newDbFile.exists()) {
    final oldDocs = await getApplicationDocumentsDirectory();
    final oldDb = File(join(oldDocs.path, 'database_backup', 'app.db'));
    if (await oldDb.exists()) {
      await oldDb.copy(dbPath);
    }
  }

  appDatabase = await openDatabase(
    dbPath,
    version: 2,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE execution_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          database TEXT NOT NULL,
          date TEXT NOT NULL,
          duration TEXT NOT NULL,
          status TEXT NOT NULL,
          file_path TEXT,
          error TEXT,
          maintenance_decision TEXT,
          maintenance_rule TEXT
        )
      ''');
      
      await db.execute('''
        CREATE TABLE execution_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          execution_id INTEGER NOT NULL,
          date TEXT NOT NULL,
          step TEXT NOT NULL,
          message TEXT NOT NULL,
          error TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE app_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS app_settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      }
    },
  );
  await loadAppConfig();
}

Future<void> loadAppConfig() async {
  final rows = await appDatabase.query('app_settings');
  appConfig.loadFromStorage({
    for (final row in rows)
      row['key'] as String: row['value'] as String,
  });
}

Future<void> saveAppConfig() async {
  final values = appConfig.toStorageMap();
  await appDatabase.transaction((txn) async {
    for (final entry in values.entries) {
      await txn.insert(
        'app_settings',
        {'key': entry.key, 'value': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  });
}
