import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import '../screens/dashboard/dashboard_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Postgres Backup Manager',
      theme: AppTheme.darkTheme,
      home: const DashboardPage(),
    );
  }
}
