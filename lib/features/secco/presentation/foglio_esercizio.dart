import 'package:flutter/material.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/tonal_chip.dart';
import '../domain/esercizio_secco.dart';
import 'video_esercizio.dart';

/// Il foglio di un esercizio di una seduta (o di una seduta di un
/// programma): come si fa, poi serie, ripetizioni o tempo, carico,
/// recupero e note. [salva] riceve la riga cambiata.
Future<void> mostraFoglioEsercizio(
  BuildContext context, {
  required EsercizioSecco? esercizio,
  required EsercizioSeduta riga,
  required Future<void> Function(EsercizioSeduta riga) salva,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) =>
      _FoglioEsercizio(esercizio: esercizio, riga: riga, salva: salva),
);

/// I recuperi fra le serie che si scelgono con un tocco.
const _recuperi = [0, 15, 30, 45, 60, 90, 120, 180];

class _FoglioEsercizio extends StatefulWidget {
  const _FoglioEsercizio({
    required this.esercizio,
    required this.riga,
    required this.salva,
  });

  final EsercizioSecco? esercizio;
  final EsercizioSeduta riga;
  final Future<void> Function(EsercizioSeduta riga) salva;

  @override
  State<_FoglioEsercizio> createState() => _FoglioEsercizioState();
}

class _FoglioEsercizioState extends State<_FoglioEsercizio> {
  late int _serie = widget.riga.serie;
  late int _quanto = widget.riga.durataS ?? widget.riga.ripetizioni ?? 12;
  late int? _recupero = widget.riga.recuperoS;
  late final _carico = TextEditingController(text: widget.riga.carico ?? '');
  late final _note = TextEditingController(text: widget.riga.note ?? '');
  bool _salvo = false;
  String? _errore;

  bool get _aTempo => widget.riga.durataS != null;

  @override
  void dispose() {
    _carico.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _salva() async {
    setState(() {
      _salvo = true;
      _errore = null;
    });
    final r = widget.riga;
    try {
      await widget.salva(
        EsercizioSeduta(
          id: r.id,
          allenamentoId: r.allenamentoId,
          clubId: r.clubId,
          esercizioId: r.esercizioId,
          ordine: r.ordine,
          serie: _serie,
          ripetizioni: _aTempo ? null : _quanto,
          durataS: _aTempo ? _quanto : null,
          carico: _carico.text,
          recuperoS: _recupero,
          note: _note.text,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _salvo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final e = widget.esercizio;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          0,
          AppSpacing.s16,
          AppSpacing.s24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              e?.nome ?? 'Esercizio',
              style: AppTypography.sezione.copyWith(color: colori.testo),
            ),
            if (e?.descrizione case final d? when d.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                d,
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
            ],
            if (e?.videoYoutube case final video?) ...[
              const SizedBox(height: AppSpacing.s12),
              VideoEsercizio(videoId: video, inizio: e!.videoDaS),
            ],
            const SizedBox(height: AppSpacing.s20),
            _Contatore(
              etichetta: 'Serie',
              valore: '$_serie',
              onMeno: _serie > 1 ? () => setState(() => _serie--) : null,
              onPiu: _serie < 20 ? () => setState(() => _serie++) : null,
            ),
            const SizedBox(height: AppSpacing.s12),
            _Contatore(
              etichetta: _aTempo ? 'Tempo di ogni serie' : 'Ripetizioni',
              valore: _aTempo ? formattaSecondi(_quanto) : '$_quanto',
              onMeno: _quanto > (_aTempo ? 5 : 1)
                  ? () => setState(() => _quanto -= _aTempo ? 5 : 1)
                  : null,
              onPiu: _quanto < (_aTempo ? 3600 : 500)
                  ? () => setState(() => _quanto += _aTempo ? 5 : 1)
                  : null,
            ),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              etichetta: 'Carico (facoltativo)',
              controller: _carico,
              aiuto: 'Per esempio «8 kg» o «elastico rosso».',
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              'Recupero fra le serie',
              style: AppTypography.etichetta.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                for (final s in {..._recuperi, ?_recupero}.toList()..sort())
                  TonalChip(
                    etichetta: s == 0 ? 'Nessuno' : formattaSecondi(s),
                    selezionato: (_recupero ?? 0) == s,
                    onSelezionato: (_) =>
                        setState(() => _recupero = s == 0 ? null : s),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              etichetta: 'Note (facoltativo)',
              controller: _note,
              maxLines: 2,
              aiuto: 'Le leggi tu: all\'atleta non arrivano.',
            ),
            if (_errore != null) ...[
              const SizedBox(height: AppSpacing.s12),
              ErrorBanner(messaggio: _errore!),
            ],
            const SizedBox(height: AppSpacing.s20),
            PrimaryButton(
              label: 'Salva esercizio',
              isLoading: _salvo,
              onPressed: _salvo ? null : _salva,
            ),
          ],
        ),
      ),
    );
  }
}

/// Un numero con − e + ai lati.
class _Contatore extends StatelessWidget {
  const _Contatore({
    required this.etichetta,
    required this.valore,
    required this.onMeno,
    required this.onPiu,
  });

  final String etichetta;
  final String valore;
  final VoidCallback? onMeno;
  final VoidCallback? onPiu;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Row(
      children: [
        Expanded(
          child: Text(
            etichetta,
            style: AppTypography.corpo.copyWith(color: colori.testo),
          ),
        ),
        IconButton.outlined(
          tooltip: 'Meno',
          onPressed: onMeno,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 72,
          child: Text(
            valore,
            textAlign: TextAlign.center,
            style: AppTypography.numerica(AppTypography.titolo)
                .copyWith(color: colori.testo),
          ),
        ),
        IconButton.outlined(
          tooltip: 'Più',
          onPressed: onPiu,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
