import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/pace_format.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/zone_chip.dart';
import '../../atleti/domain/atleta.dart';
import '../../test/domain/test_ingresso.dart';
import '../application/tabelle_passi_providers.dart';
import '../data/tabelle_passi_repository.dart';
import '../domain/tabella_passo.dart';
import '../domain/zone_defaults.dart';

class TabellePassiScreen extends ConsumerStatefulWidget {
  const TabellePassiScreen({
    required this.test,
    required this.atleta,
    super.key,
  });

  final TestIngresso test;
  final Atleta atleta;

  @override
  ConsumerState<TabellePassiScreen> createState() => _TabellePassiScreenState();
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
      if (percentuale != null &&
          _percentualeControllers.containsKey(riga.zona)) {
        _percentualeControllers[riga.zona]!.text = percentuale.toStringAsFixed(
          1,
        );
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
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Tabella passi salvata')));
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = messaggioErrore(e));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esistentiAsync = ref.watch(tabellePassiProvider(widget.test.id));
    final colori = context.colori;

    esistentiAsync.whenData(_prefillDaEsistenti);

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text('Tabella passi — ${widget.atleta.nomeCompleto}'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.test.tipo} · passo medio '
            '${formatPaceSeconds(widget.test.passoMedio100S)}/100m',
            style: AppTypography.numerica(
              AppTypography.corpo.copyWith(color: colori.testo),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Percentuali di partenza generiche: modificale liberamente in '
            'base alla tua metodologia prima di generare.',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          for (final zona in ordineZone) ...[
            Row(
              children: [
                ZoneChip(sigla: zona),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: TextFormField(
                    controller: _percentualeControllers[zona],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: AppTypography.condensata(
                      AppTypography.numerica(
                        AppTypography.corpo.copyWith(color: colori.testo),
                      ),
                    ),
                    decoration: const InputDecoration(
                      labelText: '% del passo medio',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                SizedBox(
                  width: 90,
                  child: Text(
                    '${formatPaceSeconds(_passoPerZona(zona))}/100m',
                    textAlign: TextAlign.end,
                    style: AppTypography.condensata(
                      AppTypography.numerica(
                        AppTypography.corpoForte.copyWith(color: colori.testo),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s8),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.s8),
            ErrorBanner(messaggio: _errorMessage!),
          ],
          const SizedBox(height: AppSpacing.s16),
          PrimaryButton(
            label: 'Genera tabella passi',
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _genera,
          ),
        ],
      ),
    );
  }
}
