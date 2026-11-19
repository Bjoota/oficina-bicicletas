import '../database/sqlite_database.dart';
import '../models/ordem_servico.dart';
import '../services/api_service.dart';

/// Resultado de um cadastro feito pelo repositório.
class ResultadoCadastro {
  const ResultadoCadastro({
    required this.ordem,
    required this.sincronizado,
    this.aviso,
  });

  final OrdemServico ordem;

  /// `true` quando a API confirmou o registro imediatamente.
  final bool sincronizado;

  /// Motivo pelo qual o registro ficou pendente (quando houver).
  final String? aviso;
}

/// Resultado da sincronização manual.
class ResultadoSincronizacao {
  const ResultadoSincronizacao({
    required this.enviados,
    required this.pendentes,
    this.erro,
  });

  final int enviados;
  final int pendentes;
  final String? erro;

  bool get sucesso => erro == null;
}

/// Camada de repositório: decide entre API e SQLite (offline-first).
///
/// Fluxo de cadastro:
/// 1. tenta enviar para a API;
/// 2. se a API responder, grava localmente já marcado como sincronizado;
/// 3. se a API falhar, grava localmente como pendente de sincronização.
class OrdemServicoRepository {
  OrdemServicoRepository({
    SqliteDatabase? bancoLocal,
    ApiService? apiService,
  })  : _bancoLocal = bancoLocal ?? SqliteDatabase.instancia,
        _apiService = apiService ?? ApiService();

  static final OrdemServicoRepository instancia = OrdemServicoRepository();

  final SqliteDatabase _bancoLocal;
  final ApiService _apiService;

  Future<List<OrdemServico>> listar() => _bancoLocal.listarTodas();

  Future<List<OrdemServico>> listarPendentes() =>
      _bancoLocal.listarPendentes();

  Future<int> contarPendentes() => _bancoLocal.contarPendentes();

  /// Busca os registros da API e importa para o SQLite os que ainda não
  /// existem localmente (comparação pelo id remoto).
  ///
  /// Retorna quantos registros novos foram importados. Registros já
  /// conhecidos são ignorados para não duplicar a listagem.
  Future<int> importarRemotas() async {
    final remotas = await _apiService.listarOrdens();
    final locais = await _bancoLocal.listarTodas();
    final idsConhecidos = locais
        .map((ordem) => ordem.idRemoto)
        .whereType<int>()
        .toSet();

    var importadas = 0;

    for (final remota in remotas) {
      final idRemoto = remota.idRemoto;
      if (idRemoto == null || idsConhecidos.contains(idRemoto)) {
        continue;
      }

      await _bancoLocal.inserir(
        OrdemServico(
          ordemServico: remota.ordemServico,
          valor: remota.valor,
          criadaEm: remota.criadaEm,
          sincronizado: true,
          idRemoto: idRemoto,
        ),
      );
      idsConhecidos.add(idRemoto);
      importadas++;
    }

    return importadas;
  }

  Future<ResultadoCadastro> cadastrar({
    required int ordemServico,
    required double valor,
  }) async {
    final agora = DateTime.now();

    OrdemServico? remota;
    String? aviso;

    try {
      remota = await _apiService.criarOrdem(
        OrdemServico(
          ordemServico: ordemServico,
          valor: valor,
          criadaEm: agora,
        ),
      );
    } on ApiException catch (erro) {
      aviso = erro.mensagem;
    } catch (erro) {
      aviso = 'Falha ao enviar para a API: $erro';
    }

    final local = await _bancoLocal.inserir(
      OrdemServico(
        ordemServico: ordemServico,
        valor: valor,
        criadaEm: agora,
        sincronizado: remota != null,
        idRemoto: remota?.idRemoto,
      ),
    );

    return ResultadoCadastro(
      ordem: local,
      sincronizado: remota != null,
      aviso: aviso,
    );
  }

  /// Envia todas as ordens pendentes para a API, uma a uma.
  ///
  /// Cada registro só é marcado como sincronizado depois que o servidor
  /// confirma o cadastro e devolve o id remoto. Se a API estiver fora do ar,
  /// a sincronização para na primeira falha de conexão e as ordens restantes
  /// continuam pendentes.
  Future<ResultadoSincronizacao> sincronizarPendentes() async {
    final pendentes = await _bancoLocal.listarPendentes();

    var enviados = 0;
    String? erro;

    for (final ordem in pendentes) {
      try {
        final remota = await _apiService.criarOrdem(ordem);

        final idRemoto = remota.idRemoto;
        if (idRemoto == null) {
          throw const ApiException(
            'A API não devolveu o id do registro criado.',
          );
        }

        await _bancoLocal.marcarComoSincronizada(
          ordem.id!,
          idRemoto: idRemoto,
        );
        enviados++;
      } on ApiException catch (falha) {
        erro = falha.mensagem;
        if (falha.semConexao) {
          break;
        }
      } catch (falha) {
        erro = 'Falha ao sincronizar a OS ${ordem.ordemServico}: $falha';
        break;
      }
    }

    final restantes = await _bancoLocal.contarPendentes();

    return ResultadoSincronizacao(
      enviados: enviados,
      pendentes: restantes,
      erro: erro,
    );
  }
}
