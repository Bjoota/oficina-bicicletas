import 'package:flutter/material.dart';
import 'screens/formulario.dart';

void main() => runApp(const OficinaApp());

class OficinaApp extends StatelessWidget {
  const OficinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ListaServicos(),
    );
  }
}

class ListaServicos extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => ListaServicosState();
}

class ListaServicosState extends State<ListaServicos> {
  final List<dynamic> _servicos = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Oficina de Bicicletas')),
      body: ListView.builder(
        itemCount: _servicos.length,
        itemBuilder: (context, indice) {
          final servico = _servicos[indice];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.pedal_bike),
              title: Text('R\$ ${servico.valor}'),
              subtitle: Text('Ordem de Serviço: ${servico.ordemServico}'),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FormularioTransferencia()),
          ).then((servicoRecebido) {
            if (servicoRecebido != null) {
              setState(() {
                _servicos.add(servicoRecebido);
              });
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
