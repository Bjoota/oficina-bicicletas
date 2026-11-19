import 'package:flutter/material.dart';

import '../components/editor.dart';
import '../repository/ordem_servico_repository.dart';

class FormularioTransferencia extends StatefulWidget {
  const FormularioTransferencia({super.key});

  @override
  State<FormularioTransferencia> createState() =>
      _FormularioTransferenciaState();
}

class _FormularioTransferenciaState extends State<FormularioTransferencia> {
  final GlobalKey<FormState> _formularioKey = GlobalKey<FormState>();
  final OrdemServicoRepository _repositorio =
      OrdemServicoRepository.instancia;

  final TextEditingController _controladorCampoOrdem =
      TextEditingController();
  final TextEditingController _controladorCampoValor =
      TextEditingController();

  bool _salvando = false;

  @override
  void dispose() {
    _controladorCampoOrdem.dispose();
    _controladorCampoValor.dispose();
    super.dispose();
  }

  double? _converterValor(String texto) {
    final limpo = texto
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .trim();

    if (limpo.isEmpty) return null;

    if (limpo.contains(',')) {
      return double.tryParse(
        limpo.replaceAll('.', '').replaceAll(',', '.'),
      );
    }

    return double.tryParse(limpo);
  }

  Future<void> _salvar() async {
    if (!_formularioKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _salvando = true;
    });

    final numero = int.parse(_controladorCampoOrdem.text.trim());
    final valor = _converterValor(_controladorCampoValor.text)!;

    try {
      final resultado = await _repositorio.cadastrar(
        ordemServico: numero,
        valor: valor,
      );

      if (!mounted) return;
      Navigator.pop(context, resultado);
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        _salvando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível cadastrar a ordem: $erro'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Nova Ordem de Serviço')),
      body: Form(
        key: _formularioKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: esquema.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_sync_outlined, color: esquema.primary),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Sem conexão com a API, a ordem é salva no SQLite '
                        'e fica pendente de sincronização.',
                      ),
                    ),
                  ],
                ),
              ),
              Editor(
                controlador: _controladorCampoOrdem,
                rotulo: 'Ordem de Serviço',
                dica: '0000',
                icone: Icons.pedal_bike,
                validador: (texto) {
                  final numero = int.tryParse(texto?.trim() ?? '');
                  if (numero == null || numero <= 0) {
                    return 'Informe um número de OS válido.';
                  }
                  return null;
                },
              ),
              Editor(
                controlador: _controladorCampoValor,
                rotulo: 'Valor do Serviço',
                dica: '0,00',
                icone: Icons.monetization_on,
                tipoTeclado: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                acaoTeclado: TextInputAction.done,
                validador: (texto) {
                  final valor = _converterValor(texto ?? '');
                  if (valor == null || valor < 0) {
                    return 'Informe um valor válido.';
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton.icon(
                  onPressed: _salvando ? null : _salvar,
                  icon: _salvando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_salvando ? 'Cadastrando...' : 'Cadastrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
