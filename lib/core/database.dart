import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

late Database appDatabase;

Future<void> initDatabase() async {
  final appDocDir = await getApplicationDocumentsDirectory();
  final dbPath = join(appDocDir.path, 'database_backup', 'app.db');

  final dir = Directory(dirname(dbPath));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  appDatabase = await openDatabase(
    dbPath,
    version: 1,
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
    },
  );
}
