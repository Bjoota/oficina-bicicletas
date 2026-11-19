/// Ordem de serviço da oficina de bicicletas.
///
/// O mesmo modelo é usado no SQLite (campos em snake_case) e na API
/// (JSON em camelCase). O campo [sincronizado] só existe localmente e
/// indica se o registro já foi confirmado pelo servidor.
class OrdemServico {
  const OrdemServico({
    this.id,
    this.idRemoto,
    required this.ordemServico,
    required this.valor,
    required this.criadaEm,
    this.sincronizado = false,
  });

  /// Identificador local (SQLite). Nulo antes da inserção.
  final int? id;

  /// Identificador devolvido pela API/PostgreSQL.
  final int? idRemoto;

  /// Número da ordem de serviço da oficina.
  final int ordemServico;

  /// Valor cobrado pelo serviço, em reais.
  final double valor;

  final DateTime criadaEm;

  /// `true` quando o registro já existe no PostgreSQL.
  final bool sincronizado;

  factory OrdemServico.doMapaLocal(Map<String, Object?> mapa) {
    return OrdemServico(
      id: (mapa['id'] as num?)?.toInt(),
      idRemoto: (mapa['remote_id'] as num?)?.toInt(),
      ordemServico: (mapa['ordem_servico'] as num).toInt(),
      valor: (mapa['valor'] as num).toDouble(),
      criadaEm:
          DateTime.tryParse('${mapa['criado_em'] ?? ''}')?.toLocal() ??
          DateTime.now(),
      sincronizado: (mapa['sincronizado'] as num?)?.toInt() == 1,
    );
  }

  Map<String, Object?> paraMapaLocal({bool incluirId = false}) {
    return {
      if (incluirId && id != null) 'id': id,
      'ordem_servico': ordemServico,
      'valor': valor,
      'remote_id': idRemoto,
      'sincronizado': sincronizado ? 1 : 0,
      'criado_em': criadaEm.toUtc().toIso8601String(),
    };
  }

  factory OrdemServico.doJsonApi(Map<String, dynamic> json) {
    return OrdemServico(
      idRemoto: (json['id'] as num?)?.toInt(),
      ordemServico: (json['ordemServico'] as num).toInt(),
      valor: (json['valor'] as num).toDouble(),
      criadaEm:
          DateTime.tryParse('${json['criadoEm'] ?? ''}')?.toLocal() ??
          DateTime.now(),
      sincronizado: true,
    );
  }

  Map<String, dynamic> paraJsonApi() {
    return {
      'ordemServico': ordemServico,
      'valor': valor,
    };
  }

  OrdemServico copiarCom({
    int? id,
    int? idRemoto,
    bool? sincronizado,
  }) {
    return OrdemServico(
      id: id ?? this.id,
      idRemoto: idRemoto ?? this.idRemoto,
      ordemServico: ordemServico,
      valor: valor,
      criadaEm: criadaEm,
      sincronizado: sincronizado ?? this.sincronizado,
    );
  }

  @override
  String toString() {
    return 'OrdemServico{id: $id, idRemoto: $idRemoto, '
        'ordemServico: $ordemServico, valor: $valor, '
        'sincronizado: $sincronizado}';
  }
}
