import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:postgres/postgres.dart';

class PostgresService extends ChangeNotifier {
  Connection? _connection;
  String? _connectedHost;
  int? _connectedPort;

  bool get isConnected => _connection != null;
  String? get connectedHost => _connectedHost;
  int? get connectedPort => _connectedPort;

  Future<void> connect({
    required String host,
    required int port,
    required String username,
    required String password,
    required String database,
  }) async {
    await disconnect();
    final resolvedHost = await _resolveIpv4(host.trim());
    try {
      final connection = await _openConnection(
        host: resolvedHost,
        port: port,
        database: database,
        username: username,
        password: password,
      );
      _connection = connection;
      _connectedHost = host.trim();
      _connectedPort = port;
      notifyListeners();
      await connection.execute("SET client_encoding TO 'UTF8'");
      await connection.execute("SET lc_messages TO 'C'");
    } catch (error) {
      await disconnect();
      if (error is SocketException) {
        throw Exception(
          'Não foi possível alcançar o PostgreSQL em $host:$port. '
          'Verifique o serviço, a porta, pg_hba.conf e o firewall. ${error.message}',
        );
      }
      rethrow;
    }
  }

  Future<String> _resolveIpv4(String host) async {
    final literal = InternetAddress.tryParse(host);
    if (literal != null) {
      if (literal.type != InternetAddressType.IPv4) {
        throw Exception('O host deve ser um endereço IPv4 ou nome resolvível para IPv4.');
      }
      return literal.address;
    }
    final addresses = await InternetAddress.lookup(
      host,
      type: InternetAddressType.IPv4,
    );
    if (addresses.isEmpty) {
      throw Exception('O host $host não possui um endereço IPv4 resolvível.');
    }
    return addresses.first.address;
  }

  Future<Connection> _openConnection({
    required String host,
    required int port,
    required String database,
    required String username,
    required String password,
  }) async {
    final endpoint = Endpoint(
      host: host,
      port: port,
      database: database,
      username: username,
      password: password,
    );
    try {
      return await Connection.open(
        endpoint,
        settings: ConnectionSettings(
          encoding: utf8,
          sslMode: SslMode.require,
          connectTimeout: const Duration(seconds: 15),
          queryTimeout: const Duration(seconds: 60),
        ),
      );
    } on PgException catch (error) {
      if (!error.toString().contains('does not support SSL')) rethrow;
      return Connection.open(
        endpoint,
        settings: ConnectionSettings(
          encoding: utf8,
          sslMode: SslMode.disable,
          connectTimeout: const Duration(seconds: 15),
          queryTimeout: const Duration(seconds: 60),
        ),
      );
    }
  }

  Future<void> disconnect() async {
    final connection = _connection;
    _connection = null;
    _connectedHost = null;
    _connectedPort = null;
    if (connection != null) {
      try {
        await connection.close();
      } finally {
        notifyListeners();
      }
    } else {
      notifyListeners();
    }
  }

  Future<List<String>> getDatabases() async {
    final connection = _connection;
    if (connection == null) {
      throw Exception('Não existe uma conexão PostgreSQL ativa.');
    }
    final result = await connection.execute(Sql.named('''
      SELECT datname
      FROM pg_database
      WHERE datistemplate = false
      AND datallowconn = true
      ORDER BY datname
    '''));
    return result.map((row) => row[0].toString()).toList();
  }

  Future<String> getDatabaseSize(String database) async {
    final connection = _connection;
    if (connection == null) throw Exception('Não conectado.');
    final result = await connection.execute(
      Sql.named('SELECT pg_size_pretty(pg_database_size(@database))'),
      parameters: {'database': database},
    );
    if (result.isEmpty) return 'N/A';
    return result.first[0].toString();
  }

  Future<Map<String, dynamic>> getDatabaseIntegrity() async {
    final connection = _connection;
    if (connection == null) throw Exception('Não conectado.');
    final tables = await connection.execute(Sql.named('''
      SELECT COUNT(*)
      FROM information_schema.tables
      WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
        AND table_type = 'BASE TABLE'
    '''));
    final rows = await connection.execute(Sql.named('''
      SELECT COALESCE(SUM(n_live_tup), 0)::bigint
      FROM pg_stat_user_tables
    '''));
    final databaseName = await connection.execute(Sql.named('SELECT current_database()'));
    final size = await getDatabaseSize(databaseName.first[0].toString());
    return {
      'tableCount': (tables.first[0] as num).toInt(),
      'rowEstimate': (rows.first[0] as num).toInt(),
      'size': size,
    };
  }

  Future<void> executeMaintenance(String query, {
    required String host,
    required int port,
    required String username,
    required String password,
    required String database,
  }) async {
    final resolvedHost = await _resolveIpv4(host.trim());
    final vacuumConn = await _openConnection(
      host: resolvedHost,
      port: port,
      database: database,
      username: username,
      password: password,
    );
    try {
      await vacuumConn.execute(query);
    } finally {
      await vacuumConn.close();
    }
  }

  Future<Map<String, dynamic>?> getLastMaintenance(String database) async {
    final connection = _connection;
    if (connection == null) throw Exception('Não conectado.');
    final checkTable = await connection.execute(
      Sql.named("SELECT to_regclass('public.manutencao_log')"),
    );
    if (checkTable.isEmpty || checkTable.first[0] == null) return null;
    final result = await connection.execute(Sql.named('''
      SELECT tipo_manutencao, inicio, fim, resultado
      FROM manutencao_log
      WHERE database = @database AND resultado = 'SUCESSO'
      ORDER BY inicio DESC LIMIT 1
    '''), parameters: {'database': database});
    if (result.isEmpty) return null;
    return {
      'tipo_manutencao': result.first[0],
      'inicio': result.first[1],
      'fim': result.first[2],
      'resultado': result.first[3],
    };
  }

  Future<void> logMaintenance({
    required String database,
    required String tipoManutencao,
    required String origemDecisao,
    required String regraAplicada,
    required DateTime inicio,
    required DateTime fim,
    required String resultado,
    String? mensagemErro,
  }) async {
    final connection = _connection;
    if (connection == null) return;
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS manutencao_log (
        id SERIAL PRIMARY KEY,
        database VARCHAR(255) NOT NULL,
        tipo_manutencao VARCHAR(50) NOT NULL,
        origem_decisao VARCHAR(50) NOT NULL,
        regra_aplicada VARCHAR(100) NOT NULL,
        inicio TIMESTAMP NOT NULL,
        fim TIMESTAMP NOT NULL,
        resultado VARCHAR(50) NOT NULL,
        mensagem_erro TEXT
      )
    ''');
    await connection.execute(Sql.named('''
      INSERT INTO manutencao_log
        (database, tipo_manutencao, origem_decisao, regra_aplicada,
         inicio, fim, resultado, mensagem_erro)
      VALUES (@database, @tipo, @origem, @regra, @inicio, @fim, @resultado, @erro)
    '''), parameters: {
      'database': database,
      'tipo': tipoManutencao,
      'origem': origemDecisao,
      'regra': regraAplicada,
      'inicio': inicio,
      'fim': fim,
      'resultado': resultado,
      'erro': mensagemErro,
    });
  }
}
