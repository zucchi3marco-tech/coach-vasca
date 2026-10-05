import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/titolo_due_righe.dart';
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

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  @override
  Widget build(BuildContext context) {
    final codici = _codici;
    final colori = context.colori;
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: TitoloDueRighe(
          titolo: 'Codice',
          sottotitolo: widget.gruppo.nome,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Genera un codice per il gruppo "${widget.gruppo.nome}": '
            'condividilo una sola volta, ogni atleta che lo usa compila da '
            'solo la propria anagrafica e resta già assegnato a questo '
            'gruppo. Controlla i dati dopo la registrazione.',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          PrimaryButton(
            label: 'Genera codice',
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _generaCodice,
          ),
          if (_errore != null) ...[
            const SizedBox(height: AppSpacing.s16),
            ErrorBanner(messaggio: _errore!),
          ],
          const SizedBox(height: AppSpacing.s28),
          if (codici == null)
            const SizedBox.shrink()
          else if (codici.isEmpty)
            const EmptyState(
              icona: Icons.qr_code_2_outlined,
              titolo: 'Nessun codice generato',
              descrizione:
                  'I codici che generi per questo gruppo compariranno qui, '
                  'per poterli ricondividere in un secondo momento.',
              azionePrincipale: 'Genera il primo codice',
            )
          else
            AppListPanel(
              righe: [
                for (final c in codici)
                  AppListRow(
                    titolo: c.gruppoNome,
                    sottotitolo: c.scaduto
                        ? 'Scaduto il ${_formattaData(c.scadeIl)}'
                        : 'Codice ${c.codice} · valido fino al '
                              '${_formattaData(c.scadeIl)}',
                    trailing: c.scaduto
                        ? null
                        : IconButton(
                            icon: Icon(
                              Icons.copy_outlined,
                              color: colori.testoSecondario,
                            ),
                            tooltip: 'Copia codice',
                            onPressed: () => _copia(c.codice),
                          ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
