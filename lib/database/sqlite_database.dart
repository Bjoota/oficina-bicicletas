import 'package:path/path.dart' as caminho;
import 'package:sqflite/sqflite.dart';

import '../models/ordem_servico.dart';

/// Acesso exclusivo ao SQLite local.
///
/// A tabela `ordens_servico` guarda todas as ordens cadastradas, inclusive as
/// que ainda não chegaram à API. A coluna `sincronizado` é a fonte da verdade
/// para a sincronização manual.
class SqliteDatabase {
  SqliteDatabase({String? caminhoDoBanco})
      : _caminhoDoBanco = caminhoDoBanco;

  /// Instância compartilhada pelo aplicativo.
  static final SqliteDatabase instancia = SqliteDatabase();

  static const String nomeBanco = 'oficina_bicicletas.db';
  static const int versaoBanco = 1;
  static const String tabelaOrdens = 'ordens_servico';

  final String? _caminhoDoBanco;
  Future<Database>? _abertura;

  Future<Database> get banco => _abertura ??= _abrir();

  Future<Database> _abrir() async {
    final caminhoPadrao = _caminhoDoBanco ??
        caminho.join(await getDatabasesPath(), nomeBanco);

    return openDatabase(
      caminhoPadrao,
      version: versaoBanco,
      onCreate: _criarTabelas,
    );
  }

  Future<void> _criarTabelas(Database db, int versao) async {
    await db.execute('''
      CREATE TABLE $tabelaOrdens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ordem_servico INTEGER NOT NULL,
        valor REAL NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        remote_id INTEGER,
        criado_em TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_ordens_sincronizado '
      'ON $tabelaOrdens (sincronizado)',
    );
  }

  Future<OrdemServico> inserir(OrdemServico ordem) async {
    final db = await banco;
    final id = await db.insert(
      tabelaOrdens,
      ordem.paraMapaLocal(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return ordem.copiarCom(id: id);
  }

  /// Ordens mais recentes primeiro.
  Future<List<OrdemServico>> listarTodas() async {
    final db = await banco;
    final registros = await db.query(
      tabelaOrdens,
      orderBy: 'id DESC',
    );

    return registros.map(OrdemServico.doMapaLocal).toList();
  }

  /// Ordens que ainda não foram confirmadas pela API.
  Future<List<OrdemServico>> listarPendentes() async {
    final db = await banco;
    final registros = await db.query(
      tabelaOrdens,
      where: 'sincronizado = ?',
      whereArgs: [0],
      orderBy: 'id ASC',
    );

    return registros.map(OrdemServico.doMapaLocal).toList();
  }

  Future<int> contarPendentes() async {
    final db = await banco;
    final resultado = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM $tabelaOrdens WHERE sincronizado = 0',
    );

    return Sqflite.firstIntValue(resultado) ?? 0;
  }

  /// Marca uma ordem local como sincronizada após a API devolver o id remoto.
  Future<void> marcarComoSincronizada(int idLocal, {required int idRemoto}) async {
    final db = await banco;
    final atualizados = await db.update(
      tabelaOrdens,
      {
        'sincronizado': 1,
        'remote_id': idRemoto,
      },
      where: 'id = ?',
      whereArgs: [idLocal],
    );

    if (atualizados == 0) {
      throw StateError('Ordem local $idLocal não encontrada.');
    }
  }

  Future<void> fechar() async {
    final abertura = _abertura;
    if (abertura != null) {
      final db = await abertura;
      await db.close();
      _abertura = null;
    }
  }
}
