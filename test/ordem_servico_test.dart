import 'package:flutter_test/flutter_test.dart';
import 'package:helloworld/models/ordem_servico.dart';

void main() {
  test('converte OrdemServico para o mapa local e de volta', () {
    final original = OrdemServico(
      id: 7,
      idRemoto: 42,
      ordemServico: 1024,
      valor: 89.9,
      criadaEm: DateTime.utc(2026, 11, 18, 12, 30),
      sincronizado: true,
    );

    final restaurada = OrdemServico.doMapaLocal(
      original.paraMapaLocal(incluirId: true),
    );

    expect(restaurada.id, 7);
    expect(restaurada.idRemoto, 42);
    expect(restaurada.ordemServico, 1024);
    expect(restaurada.valor, 89.9);
    expect(restaurada.sincronizado, isTrue);
    expect(
      restaurada.criadaEm.toUtc(),
      original.criadaEm.toUtc(),
    );
  });

  test('JSON da API é interpretado como sincronizado', () {
    final ordem = OrdemServico.doJsonApi({
      'id': 15,
      'ordemServico': 2026,
      'valor': 150,
      'criadoEm': '2026-11-18T12:30:00.000Z',
    });

    expect(ordem.idRemoto, 15);
    expect(ordem.ordemServico, 2026);
    expect(ordem.valor, 150);
    expect(ordem.sincronizado, isTrue);
    expect(ordem.paraJsonApi(), {'ordemServico': 2026, 'valor': 150.0});
  });
}
