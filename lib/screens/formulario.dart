import 'package:flutter/material.dart';
import '../components/editor.dart';
import '../models/transferencia.dart';

class FormularioTransferencia extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return FormularioTransferenciaState();
  }
}

class FormularioTransferenciaState extends State<FormularioTransferencia> {
  final TextEditingController _controladorCampoOrdem = TextEditingController();
  final TextEditingController _controladorCampoValor = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Ordem de Serviço')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Editor(
              controlador: _controladorCampoOrdem,
              rotulo: 'Ordem de Serviço',
              dica: '0000',
              icone: Icons.pedal_bike,
            ),
            Editor(
              controlador: _controladorCampoValor,
              rotulo: 'Valor do Serviço',
              dica: '0,00',
              icone: Icons.monetization_on,
            ),
            ElevatedButton(
              onPressed: () => _criaServico(context),
              child: const Text('Cadastrar'),
            ),
          ],
        ),
      ),
    );
  }

  void _criaServico(BuildContext context) {
    final int? ordem = int.tryParse(_controladorCampoOrdem.text);
    final double? valor = double.tryParse(_controladorCampoValor.text);

    if (ordem != null && valor != null) {
      final servicoCriado = ServicoBicicleta(valor, ordem);
      Navigator.pop(context, servicoCriado);
    }
  }
}
