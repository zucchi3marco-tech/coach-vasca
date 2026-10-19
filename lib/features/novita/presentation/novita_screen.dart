import 'package:flutter/material.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/versione/versione_app.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../data/novita_viste.dart';
import '../domain/novita.dart';

/// «Novità»: cosa è cambiato a ogni aggiornamento, dalla più recente,
/// raggruppato per giorno. Aprirla segna le novità come viste. [registro]
/// serve ai test: di norma è [registroNovita].
class NovitaScreen extends StatefulWidget {
  const NovitaScreen({required this.atleta, this.registro, super.key});

  /// Chi guarda: un atleta (vede le sue novità) o un allenatore.
  final bool atleta;

  final List<Novita>? registro;

  @override
  State<NovitaScreen> createState() => _NovitaScreenState();
}

class _NovitaScreenState extends State<NovitaScreen> {
  List<Novita> get _registro => widget.registro ?? registroNovita;

  @override
  void initState() {
    super.initState();
    // Non si aspetta: la pagina si legge subito. Un errore delle preferenze
    // non deve rompere niente.
    segnaNovitaViste(_registro).catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final novita = novitaPer(registro: _registro, atleta: widget.atleta);

    return AppScaffold(
      appBar: AppBar(title: const Text('Novità')),
      body: novita.isEmpty
          ? const EmptyState(
              icona: Icons.campaign_outlined,
              titolo: 'Ancora nessuna novità',
              descrizione: 'Quando l\'app cambia lo trovi scritto qui.',
              azionePrincipale: 'Torna indietro',
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.s32),
              children: [
                Text(
                  VersioneApp.corrente.etichetta,
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
                for (final (i, n) in novita.indexed) ...[
                  if (i == 0 || !_stessoGiorno(novita[i - 1].data, n.data)) ...[
                    SizedBox(height: i == 0 ? AppSpacing.s20 : AppSpacing.s24),
                    Text(
                      dataLunga(n.data),
                      style: AppTypography.sezione.copyWith(
                        color: colori.testo,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                  ] else
                    const Divider(height: AppSpacing.s24),
                  VoceNovita(novita: n),
                ],
                if (!widget.atleta) ...[
                  const SizedBox(height: AppSpacing.s32),
                  Text(
                    'Qualcosa non va? Dal menu ☰ tocca «Scrivimi».',
                    style: AppTypography.piccolo.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

bool _stessoGiorno(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Una novità: il titolo in grassetto (con «Importante» accanto, se lo è)
/// e il testo. Sta nella pagina e nella finestra dopo l'aggiornamento.
class VoceNovita extends StatelessWidget {
  const VoceNovita({required this.novita, super.key});

  final Novita novita;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                novita.titolo,
                style: AppTypography.corpoForte.copyWith(
                  color: colori.testo,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (novita.importante) const _EtichettaImportante(),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            novita.testo,
            style: AppTypography.corpo.copyWith(
              color: colori.testoSecondario,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// La pastiglia «Importante»: fondo e testo dai colori dell'azione.
class _EtichettaImportante extends StatelessWidget {
  const _EtichettaImportante();

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s4 / 2,
      ),
      decoration: BoxDecoration(
        color: colori.azioneTenue,
        borderRadius: BorderRadius.circular(AppRadius.pillola),
      ),
      child: Text(
        'Importante',
        style: AppTypography.etichetta.copyWith(
          color: colori.azione,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
