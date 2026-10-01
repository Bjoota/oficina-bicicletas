class ServicoBicicleta {
  final double valor;
  final int ordemServico;

  ServicoBicicleta(this.valor, this.ordemServico);

  @override
  String toString() {
    return 'ServicoBicicleta{valor: $valor, ordemServico: $ordemServico}';
  }
}
