import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/pool_card.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../gruppi/domain/gruppo.dart';
import '../data/codici_gruppo_repository.dart';
import '../domain/codice_gruppo.dart';

/// Codici riutilizzabili per far registrare da soli tutti gli atleti di
/// UN gruppo (FASE 9, ristretta al singolo gruppo dalla FASE 13 punto 2:
/// generarne uno richiede di essere sulla pagina di quel gruppo, cosicche'
/// lo sport da assegnare all'atleta sia sempre certo).
class CodiciGruppoScreen extends ConsumerStatefulWidget {
  const CodiciGruppoScreen({required this.gruppo, super.key});

  final Gruppo gruppo;

  @override
  ConsumerState<CodiciGruppoScreen> createState() => _CodiciGruppoScreenState();
}

class _CodiciGruppoScreenState extends ConsumerState<CodiciGruppoScreen> {
  List<CodiceGruppo>? _codici;
  bool _isLoading = false;
  String? _errore;

  @override
  void initState() {
    super.initState();
    _carica();
  }

  Future<void> _carica() async {
    setState(() => _errore = null);
    try {
      final codici = await ref
          .read(codiciGruppoRepositoryProvider)
          .elencoPerGruppo(widget.gruppo.id);
      if (mounted) setState(() => _codici = codici);
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    }
  }

  Future<void> _generaCodice() async {
    setState(() {
      _isLoading = true;
      _errore = null;
    });
    try {
      await ref
          .read(codiciGruppoRepositoryProvider)
          .generaCodice(
            clubId: widget.gruppo.clubId,
            gruppoId: widget.gruppo.id,
          );
      await _carica();
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _copia(String codice) async {
    await Clipboard.setData(ClipboardData(text: codice));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Codice copiato negli appunti')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final codici = _codici;
    final colori = context.colori;
    final validi = codici?.where((c) => !c.scaduto).toList() ?? const [];
    final scaduti = codici?.where((c) => c.scaduto).toList() ?? const [];

    String data(DateTime d) => '${dataCompatta(d)} ${d.year}';

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(title: const Text('Codice di registrazione')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TestataPagina(
            occhiello: widget.gruppo.nome,
            titolo: 'Codice di registrazione',
            sottotitolo:
                'Condividilo con il gruppo: ogni atleta che lo usa compila '
                'da solo la propria anagrafica e resta già assegnato a '
                'questo gruppo. Controlla i dati dopo la registrazione.',
            azioni: [
              AzioneTestata(
                icona: Icons.add,
                etichetta: _isLoading ? 'Genero...' : 'Genera un codice',
                principale: true,
                onTap: _isLoading ? () {} : _generaCodice,
              ),
            ],
          ),
          if (_errore != null) ...[
            const SizedBox(height: AppSpacing.s16),
            ErrorBanner(messaggio: _errore!),
          ],
          const SizedBox(height: AppSpacing.s24),
          if (codici == null)
            const SizedBox.shrink()
          else if (codici.isEmpty)
            EmptyState(
              icona: Icons.qr_code_2_outlined,
              titolo: 'Nessun codice generato',
              descrizione:
                  'I codici che generi per questo gruppo compariranno qui, '
                  'per poterli ricondividere in un secondo momento.',
              azionePrincipale: 'Genera il primo codice',
              onAzionePrincipale: _isLoading ? null : _generaCodice,
            )
          else ...[
            if (validi.isNotEmpty) ...[
              TitoloSezione('Validi', conteggio: validi.length),
              // Il codice in grande, da dettare o copiare con un tocco.
              for (final c in validi) ...[
                PoolCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(
                              c.codice,
                              style: AppTypography.numerica(
                                AppTypography.numeroGrande.copyWith(
                                  color: colori.testo,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s4),
                            Text(
                              'Valido fino a ${data(c.scadeIl)}',
                              style: AppTypography.piccolo.copyWith(
                                color: colori.testoSecondario,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.copy_outlined),
                        tooltip: 'Copia codice',
                        onPressed: () => _copia(c.codice),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
              ],
              const SizedBox(height: AppSpacing.s12),
            ],
            if (scaduti.isNotEmpty) ...[
              TitoloSezione('Scaduti', conteggio: scaduti.length),
              AppListPanel(
                righe: [
                  for (final c in scaduti)
                    AppListRow(
                      titolo: c.codice,
                      sottotitolo: 'Scaduto il ${data(c.scadeIl)}',
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
