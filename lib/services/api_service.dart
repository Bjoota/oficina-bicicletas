import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ordem_servico.dart';

/// Erro de comunicação com a API.
class ApiException implements Exception {
  const ApiException(this.mensagem, {this.semConexao = false});

  final String mensagem;

  /// `true` quando o problema foi de rede/servidor indisponível, ou seja,
  /// vale a pena manter o registro pendente para sincronizar depois.
  final bool semConexao;

  @override
  String toString() => mensagem;
}

/// Camada de serviços HTTP da API Oficina de Bicicletas.
///
/// A URL base pode ser trocada sem recompilar o código usando:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.0.10:3000`
class ApiService {
  ApiService({http.Client? cliente, String? urlBase})
      : _cliente = cliente ?? http.Client(),
        urlBase = _normalizarUrl(
          urlBase ??
              const String.fromEnvironment(
                'API_BASE_URL',
                defaultValue: 'https://oficina-bicicletas.onrender.com',
              ),
        );

  final http.Client _cliente;
  final String urlBase;

  // O Render "dorme" instâncias gratuitas; o primeiro acesso pode levar
  // ~30 s para acordar. O timeout precisa cobrir esse cold start.
  static const Duration _tempoLimite = Duration(seconds: 45);

  static String _normalizarUrl(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  Future<List<OrdemServico>> listarOrdens() async {
    final resposta = await _requisitar(
      () => _cliente.get(Uri.parse('$urlBase/ordens')).timeout(_tempoLimite),
    );

    final dados = _decodificar(resposta);
    if (dados is! List) {
      throw const ApiException('Resposta inesperada em GET /ordens.');
    }

    return dados
        .map(
          (item) => OrdemServico.doJsonApi(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<OrdemServico> criarOrdem(OrdemServico ordem) async {
    final resposta = await _requisitar(
      () => _cliente
          .post(
            Uri.parse('$urlBase/ordens'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(ordem.paraJsonApi()),
          )
          .timeout(_tempoLimite),
    );

    final dados = _decodificar(resposta);
    if (dados is! Map) {
      throw const ApiException('Resposta inesperada em POST /ordens.');
    }

    return OrdemServico.doJsonApi(Map<String, dynamic>.from(dados));
  }

  Future<http.Response> _requisitar(
    Future<http.Response> Function() envio,
  ) async {
    try {
      final resposta = await envio();

      if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
        throw ApiException(
          _mensagemDeErro(resposta),
          semConexao: resposta.statusCode >= 500,
        );
      }

      return resposta;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'A API demorou demais para responder.',
        semConexao: true,
      );
    } catch (_) {
      throw const ApiException(
        'Não foi possível conectar à API.',
        semConexao: true,
      );
    }
  }

  Object? _decodificar(http.Response resposta) {
    try {
      return jsonDecode(utf8.decode(resposta.bodyBytes));
    } on FormatException {
      throw const ApiException('A API retornou uma resposta inválida.');
    }
  }

  String _mensagemDeErro(http.Response resposta) {
    try {
      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (dados is Map && dados['erro'] is String) {
        return 'API (${resposta.statusCode}): ${dados['erro']}';
      }
    } on FormatException {
      // Corpo não JSON: usa a mensagem genérica abaixo.
    }

    return 'API respondeu com status ${resposta.statusCode}.';
  }

  void fechar() {
    _cliente.close();
  }
}
