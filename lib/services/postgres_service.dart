import 'package:postgres/postgres.dart';

class PostgresService {
  Connection? _connection;

  Future<void> connect({
    required String host,
    required int port,
    required String username,
    required String password,
    required String database,
  }) async {
    await disconnect();

    _connection = await Connection.open(
      Endpoint(
        host: host,
        port: port,
        database: database,
        username: username,
        password: password,
      ),
      settings: const ConnectionSettings(
        sslMode: SslMode.disable,
      ),
    );

    // Force UTF-8 and English messages to prevent FormatException on Socket due to Windows local encodings (like CP1252)
    await _connection!.execute("SET client_encoding TO 'UTF8'");
    await _connection!.execute("SET lc_messages TO 'C'");
  }

  Future<void> disconnect() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
    }
  }

  bool get isConnected => _connection != null;

  Future<List<String>> getDatabases() async {
    if (_connection == null) {
      throw Exception('Não existe uma conexão PostgreSQL ativa.');
    }

    final result = await _connection!.execute(
      Sql.named('''
        SELECT datname
        FROM pg_database
        WHERE datistemplate = false
        AND datallowconn = true
        ORDER BY datname
      '''),
    );

    return result.map((row) => row[0].toString()).toList();
  }

  Future<String> getDatabaseSize(String database) async {
    if (_connection == null) {
      throw Exception('Não conectado.');
    }

    final result = await _connection!.execute(
      Sql.named('SELECT pg_size_pretty(pg_database_size(@database))'),
      parameters: {'database': database},
    );

    if (result.isEmpty) return 'N/A';
    return result.first[0].toString();
  }

  Future<void> executeMaintenance(String query, {
    required String host,
    required int port,
    required String username,
    required String password,
    required String database,
  }) async {
    // VACUUM cannot run inside a transaction block.
    // The postgres package wraps every execute() in an implicit transaction.
    // Solution: open a dedicated, short-lived connection just for the VACUUM.
    final vacuumConn = await Connection.open(
      Endpoint(
        host: host,
        port: port,
        database: database,
        username: username,
        password: password,
      ),
      settings: const ConnectionSettings(
        sslMode: SslMode.disable,
      ),
    );
    try {
      await vacuumConn.execute(query);
    } finally {
      await vacuumConn.close();
    }
  }

  Future<Map<String, dynamic>?> getLastMaintenance(String database) async {
    if (_connection == null) throw Exception('Não conectado.');
    
    // Check if table exists
    final checkTable = await _connection!.execute(Sql.named(
      "SELECT to_regclass('public.manutencao_log')"
    ));
    if (checkTable.isEmpty || checkTable.first[0] == null) {
      return null;
    }

    final result = await _connection!.execute(Sql.named(
      '''
      SELECT tipo_manutencao, inicio, fim, resultado 
      FROM manutencao_log 
      WHERE database = @database AND resultado = 'SUCESSO' 
      ORDER BY inicio DESC LIMIT 1
      '''
    ), parameters: {'database': database});

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
    if (_connection == null) return;
    
    // Ensure table exists
    await _connection!.execute('''
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

    await _connection!.execute(Sql.named(
      '''
      INSERT INTO manutencao_log (database, tipo_manutencao, origem_decisao, regra_aplicada, inicio, fim, resultado, mensagem_erro)
      VALUES (@database, @tipo, @origem, @regra, @inicio, @fim, @resultado, @erro)
      '''
    ), parameters: {
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
