import 'package:flutter_test/flutter_test.dart';
import 'package:database_backup/services/maintenance_service.dart';
import 'package:database_backup/services/postgres_service.dart';

// Mock simple service just to demonstrate unit tests for maintenance rules
class MockPostgresService extends PostgresService {
  final Map<String, dynamic>? mockLastMaintenance;
  
  MockPostgresService(this.mockLastMaintenance);

  @override
  Future<Map<String, dynamic>?> getLastMaintenance(String database) async {
    return mockLastMaintenance;
  }
}

void main() {
  group('Maintenance Service Rules', () {
    test('Nenhum historico deve retornar VACUUM FULL ANALYZE', () async {
      final service = MaintenanceService(postgresService: MockPostgresService(null));
      final result = await service.determineMaintenanceAction('postgres');
      expect(result, 'VACUUM FULL ANALYZE');
    });

    test('Menos de 30 dias deve retornar Nenhuma', () async {
      final mockData = {
        'inicio': DateTime.now().subtract(const Duration(days: 10))
      };
      final service = MaintenanceService(postgresService: MockPostgresService(mockData));
      final result = await service.determineMaintenanceAction('postgres');
      expect(result, 'Nenhuma');
    });

    test('Entre 30 e 60 dias deve retornar VACUUM', () async {
      final mockData = {
        'inicio': DateTime.now().subtract(const Duration(days: 45))
      };
      final service = MaintenanceService(postgresService: MockPostgresService(mockData));
      final result = await service.determineMaintenanceAction('postgres');
      expect(result, 'VACUUM');
    });

    test('Exatamente 30 dias deve retornar VACUUM', () async {
      final mockData = {
        'inicio': DateTime.now().subtract(const Duration(days: 30))
      };
      final service = MaintenanceService(postgresService: MockPostgresService(mockData));
      expect(await service.determineMaintenanceAction('postgres'), 'VACUUM');
    });

    test('Exatamente 60 dias deve retornar VACUUM', () async {
      final mockData = {
        'inicio': DateTime.now().subtract(const Duration(days: 60))
      };
      final service = MaintenanceService(postgresService: MockPostgresService(mockData));
      expect(await service.determineMaintenanceAction('postgres'), 'VACUUM');
    });

    test('Mais de 60 dias deve retornar VACUUM FULL ANALYZE', () async {
      final mockData = {
        'inicio': DateTime.now().subtract(const Duration(days: 90))
      };
      final service = MaintenanceService(postgresService: MockPostgresService(mockData));
      final result = await service.determineMaintenanceAction('postgres');
      expect(result, 'VACUUM FULL ANALYZE');
    });
  });
}
