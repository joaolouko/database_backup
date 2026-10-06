import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'app/app.dart';
import 'core/database.dart';
import 'core/config.dart';
import 'services/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  setupServiceLocator();
  await initDatabase();
  appConfig.password = await getIt.secretStore.getPassword('postgres_password') ?? '';

  runApp(const MyApp());
}
