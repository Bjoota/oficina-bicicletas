import 'package:flutter/material.dart';

import 'models/ordem_servico.dart';
import 'repository/ordem_servico_repository.dart';
import 'screens/formulario.dart';

void main() => runApp(const OficinaApp());

class OficinaApp extends StatelessWidget {
  const OficinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oficina de Bicicletas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      home: const ListaServicos(),
    );
  }
}

class ListaServicos extends StatefulWidget {
  const ListaServicos({super.key});

  @override
  State<ListaServicos> createState() => _ListaServicosState();
}

class _ListaServicosState extends State<ListaServicos> {
  final OrdemServicoRepository _repositorio =
      OrdemServicoRepository.instancia;

  List<OrdemServico> _ordens = const [];
  bool _carregando = true;
  bool _sincronizando = false;

  int get _pendentes =>
      _ordens.where((ordem) => !ordem.sincronizado).length;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar({bool exibirCarregamento = true}) async {
    if (exibirCarregamento) {
      setState(() {
        _carregando = true;
      });
    }

    try {
      final ordens = await _repositorio.listar();
      if (!mounted) return;

      setState(() {
        _ordens = ordens;
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });
      _exibirMensagem('Não foi possível ler as ordens salvas: $erro');
    }
  }

  Future<void> _abrirFormulario() async {
    final resultado = await Navigator.push<ResultadoCadastro>(
      context,
      MaterialPageRoute(
        builder: (context) => const FormularioTransferencia(),
      ),
    );

    if (resultado == null) return;

    await _carregar(exibirCarregamento: false);
    if (!mounted) return;

    final numero = resultado.ordem.ordemServico;
    _exibirMensagem(
      resultado.sincronizado
          ? 'OS $numero cadastrada e sincronizada com a API.'
          : 'OS $numero salva localmente e pendente de sincronização.',
    );
  }

  Future<void> _sincronizar() async {
    if (_sincronizando) return;

    setState(() {
      _sincronizando = true;
    });

    try {
      final resultado = await _repositorio.sincronizarPendentes();

      await _carregar(exibirCarregamento: false);
      if (!mounted) return;

      final String mensagem;
      if (resultado.erro != null) {
        mensagem = resultado.enviados == 0
            ? 'Falha na sincronização: ${resultado.erro}'
            : '${resultado.enviados} ordem(ns) sincronizada(s). '
                '${resultado.pendentes} continuam pendentes. '
                '${resultado.erro}';
      } else if (resultado.enviados == 0) {
        mensagem = 'Nenhuma ordem pendente de sincronização.';
      } else {
        mensagem = '${resultado.enviados} ordem(ns) sincronizada(s) com a API.';
      }

      _exibirMensagem(mensagem);
    } catch (erro) {
      if (mounted) {
        _exibirMensagem('Não foi possível sincronizar: $erro');
      }
    } finally {
      if (mounted) {
        setState(() {
          _sincronizando = false;
        });
      }
    }
  }

  void _exibirMensagem(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year} às $hora:$minuto';
  }

  String _formatarValor(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oficina de Bicicletas'),
        actions: [
          IconButton(
            tooltip: 'Sincronizar registros pendentes',
            onPressed: _sincronizando ? null : _sincronizar,
            icon: _sincronizando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Badge(
                    isLabelVisible: _pendentes > 0,
                    label: Text('$_pendentes'),
                    child: const Icon(Icons.cloud_sync_outlined),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_pendentes > 0) _construirAvisoPendentes(),
          Expanded(child: _construirConteudo()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Nova OS'),
      ),
    );
  }

  Widget _construirAvisoPendentes() {
    final esquema = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      color: esquema.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, color: esquema.onSecondaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _pendentes == 1
                  ? '1 ordem pendente de sincronização'
                  : '$_pendentes ordens pendentes de sincronização',
              style: TextStyle(color: esquema.onSecondaryContainer),
            ),
          ),
          TextButton(
            onPressed: _sincronizando ? null : _sincronizar,
            child: const Text('Sincronizar'),
          ),
        ],
      ),
    );
  }

  Widget _construirConteudo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => _carregar(exibirCarregamento: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: _ordens.isEmpty
            ? [const _EstadoVazio()]
            : _ordens.map(_construirCartao).toList(),
      ),
    );
  }

  Widget _construirCartao(OrdemServico ordem) {
    final pendente = !ordem.sincronizado;
    final corStatus =
        pendente ? Colors.orange.shade800 : Colors.green.shade700;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.pedal_bike)),
        title: Text('OS ${ordem.ordemServico}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Valor: ${_formatarValor(ordem.valor)}'),
            Text(
              pendente
                  ? 'Pendente de sincronização'
                  : 'Sincronizada com a API',
              style: TextStyle(color: corStatus, fontWeight: FontWeight.w600),
            ),
            Text(
              'Cadastrada em ${_formatarData(ordem.criadaEm)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Tooltip(
          message: pendente
              ? 'Salva apenas no SQLite'
              : 'Confirmada pelo servidor',
          child: Icon(
            pendente ? Icons.cloud_off : Icons.cloud_done,
            color: corStatus,
          ),
        ),
      ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio();

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.pedal_bike, size: 72, color: esquema.outline),
          const SizedBox(height: 16),
          Text(
            'Nenhuma ordem de serviço cadastrada',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Toque em "Nova OS" para registrar o primeiro serviço. '
            'Sem internet, a ordem fica salva no aparelho e pendente '
            'de sincronização.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
