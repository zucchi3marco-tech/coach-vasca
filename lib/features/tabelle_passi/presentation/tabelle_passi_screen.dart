import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/pace_format.dart';
import '../../atleti/domain/atleta.dart';
import '../../test/domain/test_ingresso.dart';
import '../application/tabelle_passi_providers.dart';
import '../data/tabelle_passi_repository.dart';
import '../domain/tabella_passo.dart';
import '../domain/zone_defaults.dart';

class TabellePassiScreen extends ConsumerStatefulWidget {
  const TabellePassiScreen({required this.test, required this.atleta, super.key});

  final TestIngresso test;
  final Atleta atleta;

  @override
  ConsumerState<TabellePassiScreen> createState() =>
      _TabellePassiScreenState();
}

class _TabellePassiScreenState extends ConsumerState<TabellePassiScreen> {
  final Map<String, TextEditingController> _percentualeControllers = {
    for (final zona in ordineZone)
      zona: TextEditingController(
        text: defaultPercentualiZona[zona]!.toStringAsFixed(0),
      ),
  };

  bool _prefillFatto = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (final controller in _percentualeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _prefillDaEsistenti(List<TabellaPasso> righeEsistenti) {
    if (_prefillFatto || righeEsistenti.isEmpty) return;
    for (final riga in righeEsistenti) {
      final percentuale = riga.percentualeRiferimento;
      if (percentuale != null && _percentualeControllers.containsKey(riga.zona)) {
        _percentualeControllers[riga.zona]!.text = percentuale.toStringAsFixed(1);
      }
    }
    _prefillFatto = true;
  }

  double _passoPerZona(String zona) {
    final percentuale =
        double.tryParse(_percentualeControllers[zona]!.text.trim()) ??
        defaultPercentualiZona[zona]!;
    return widget.test.passoMedio100S * percentuale / 100;
  }

  Future<void> _genera() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final righe = [
        for (final zona in ordineZone)
          RigaTabellaPasso(
            zona: zona,
            passo100S: _passoPerZona(zona),
            percentualeRiferimento:
                double.tryParse(_percentualeControllers[zona]!.text.trim()) ??
                defaultPercentualiZona[zona]!,
          ),
      ];
      await ref
          .read(tabellePassiRepositoryProvider)
          .upsertPerTest(testId: widget.test.id, righe: righe);
      ref.invalidate(tabellePassiProvider(widget.test.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tabella passi salvata')),
      );
    } catch (_) {
      setState(() => _errorMessage = 'Salvataggio non riuscito. Riprova.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esistentiAsync = ref.watch(tabellePassiProvider(widget.test.id));

    esistentiAsync.whenData(_prefillDaEsistenti);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tabella passi — ${widget.atleta.nomeCompleto}',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.test.tipo} · passo medio '
                '${formatPaceSeconds(widget.test.passoMedio100S)}/100m',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Percentuali di partenza generiche: modificale liberamente '
                'in base alla tua metodologia prima di generare.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              for (final zona in ordineZone) ...[
                Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        zona,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _percentualeControllers[zona],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: '% del passo medio',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 90,
                      child: Text(
                        '${formatPaceSeconds(_passoPerZona(zona))}/100m',
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isSubmitting ? null : _genera,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Genera tabella passi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
