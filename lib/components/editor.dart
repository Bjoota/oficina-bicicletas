import 'package:flutter/material.dart';

class Editor extends StatelessWidget {
  final TextEditingController? controlador;
  final String? rotulo;
  final String? dica;
  final IconData? icone;
  final TextInputType tipoTeclado;
  final TextInputAction acaoTeclado;
  final String? Function(String?)? validador;

  const Editor({
    super.key,
    this.controlador,
    this.rotulo,
    this.dica,
    this.icone,
    this.tipoTeclado = TextInputType.number,
    this.acaoTeclado = TextInputAction.next,
    this.validador,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextFormField(
        controller: controlador,
        keyboardType: tipoTeclado,
        textInputAction: acaoTeclado,
        validator: validador,
        decoration: InputDecoration(
          icon: icone != null ? Icon(icone) : null,
          labelText: rotulo,
          hintText: dica,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
