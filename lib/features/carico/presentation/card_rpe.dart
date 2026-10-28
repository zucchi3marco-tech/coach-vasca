import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/giorni.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../../allenamenti/application/allenamenti_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../../atleti/domain/squadre_atleta.dart';
import '../../pallanuoto/application/pallanuoto_providers.dart';
import '../../presenze/application/presenze_providers.dart';
import '../../presenze/domain/presenza.dart';
import '../application/carico_providers.dart';
import '../data/rpe_repository.dart';
import '../domain/carico_rpe.dart';

/// Una seduta recente a cui l'atleta può dare l'RPE.
typedef SedutaDaValutare = ({
  String tipo,
  String id,
  DateTime data,
  String descrizione,
});

/// Per quanti giorni dopo una seduta si chiede l'RPE: oltre, il ricordo
/// di quanto è stata dura non è più affidabile.
const giorniPerRispondere = 2;

/// Le sedute degli ultimi [giorniPerRispondere] giorni (oggi compreso):
/// gli allenamenti del suo gruppo in cui non è segnato assente e le
/// partite in cui è convocato (o con la distinta ancora vuota), già
/// cominciate. Dalla più recente.
final seduteDaValutareProvider = Provider.autoDispose
    .family<List<SedutaDaValutare>, Atleta>((ref, atleta) {
      final adesso = DateTime.now();
      final oggi = soloData(adesso);
      final dal = aggiungiGiorni(oggi, -giorniPerRispondere);
      bool recente(DateTime d) =>
          !soloData(d).isBefore(dal) && !soloData(d).isAfter(oggi);
      String quando(DateTime d) => switch (giorniTra(oggi, d)) {
        0 => 'di oggi',
        -1 => 'di ieri',
        _ => 'di ${dataEstesa(d)}',
      };

      final presenzeAtleta =
          ref.watch(presenzePerAtletaProvider(atleta.id)).value ?? const [];
      final assenti = {
        for (final p in presenzeAtleta)
          if (!contaComePresente(p.stato)) p.allenamentoId,
      };
      final presenti = {
        for (final p in presenzeAtleta)
          if (contaComePresente(p.stato)) p.allenamentoId,
      };
      final sedute = <SedutaDaValutare>[
        for (final a
            in ref.watch(allenamentiAtletaProvider(atleta.clubId)).value ??
                const [])
          // Quelle a cui era atteso (anche con l'altra squadra, nei suoi
          // giorni) o in cui è segnato presente.
          if (recente(a.data) &&
              !assenti.contains(a.id) &&
              (atleta.attesoA(a.gruppoId, a.data) || presenti.contains(a.id)))
            (
              tipo: 'allenamento',
              id: a.id,
              data: soloData(a.data),
              descrizione:
                  '${a.secco ? 'Seduta a secco' : 'Allenamento'} '
                  '${quando(a.data)}',
            ),
      ];

      for (final p
          in ref.watch(partiteListProvider(atleta.clubId)).value ?? const []) {
        // Anche le partite dell'altra squadra con cui si allena.
        if (!recente(p.data) || !atleta.vedeGruppo(p.gruppoId)) {
          continue;
        }
        // Una partita di oggi che non è ancora cominciata.
        final ora = RegExp(r'^(\d{1,2})[:.](\d{2})').firstMatch(p.ora ?? '');
        if (ora != null &&
            soloData(p.data) == oggi &&
            DateTime(
              oggi.year,
              oggi.month,
              oggi.day,
              int.parse(ora.group(1)!),
              int.parse(ora.group(2)!),
            ).isAfter(adesso)) {
          continue;
        }
        final distinta = ref.watch(distintaListProvider(p.id)).value;
        if (distinta == null) continue;
        if (distinta.isNotEmpty &&
            !distinta.any((d) => d.atletaId == atleta.id)) {
          continue;
        }
        sedute.add((
          tipo: 'partita',
          id: p.id,
          data: soloData(p.data),
          descrizione: 'Partita ${quando(p.data)} con ${p.avversario}',
        ));
      }
      sedute.sort((a, b) => b.data.compareTo(a.data));
      return sedute;
    });

const _chiaveNascoste = 'rpe_sedute_nascoste';

/// "Quanto è stato duro?": la domanda di fine seduta nella home
/// dell'atleta, sotto la scheda benessere. Una riga per ogni seduta
/// recente; un tocco su un numero salva subito. "Non c'ero" la toglie
/// (solo su questo telefono). Senza sedute recenti non mostra niente.
class CardRpe extends ConsumerStatefulWidget {
  const CardRpe({required this.atleta, super.key});

  final Atleta atleta;

  @override
  ConsumerState<CardRpe> createState() => _CardRpeState();
}

class _CardRpeState extends ConsumerState<CardRpe> {
  Set<String> _nascoste = const {};

  /// Le sedute appena salvate, finché la cache non le restituisce.
  final _inSalvataggio = <String>{};

  @override
  void initState() {
    super.initState();
    _caricaNascoste();
  }

  Future<void> _caricaNascoste() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lette = prefs.getStringList(_chiaveNascoste) ?? const [];
      if (mounted) setState(() => _nascoste = lette.toSet());
    } catch (_) {
      // Senza preferenze le sedute restano tutte visibili.
    }
  }

  Future<void> _nascondi(SedutaDaValutare s) async {
    setState(() => _nascoste = {..._nascoste, s.id});
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_chiaveNascoste, _nascoste.toList());
    } catch (_) {}
  }

  Future<void> _salva(SedutaDaValutare s, int rpe) async {
    setState(() => _inSalvataggio.add(s.id));
    try {
      await ref
          .read(rpeRepositoryProvider)
          .salva(
            atletaId: widget.atleta.id,
            clubId: widget.atleta.clubId,
            eventoTipo: s.tipo,
            eventoId: s.id,
            data: s.data,
            rpe: rpe,
          );
      ref.invalidate(seduteCaricoProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Risposta non salvata. ${messaggioErrore(e)}')),
      );
    } finally {
      if (mounted) setState(() => _inSalvataggio.remove(s.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final accento = context.dominio.evidenzaCiano;
    final risposte = {
      for (final r
          in ref.watch(rpeAtletaProvider(widget.atleta.id)).value ?? const [])
        r.eventoId: r.rpe,
    };
    final sedute = ref
        .watch(seduteDaValutareProvider(widget.atleta))
        .where((s) => !_nascoste.contains(s.id))
        .take(3)
        .toList();
    if (sedute.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colori.superficie,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colori.linea),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accento.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.speed, color: accento),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quanto è stato duro?',
                        style: AppTypography.corpoForte.copyWith(
                          color: colori.testo,
                        ),
                      ),
                      Text(
                        'Da 0 (riposo) a 10 (al massimo), a fine seduta',
                        style: AppTypography.etichetta.copyWith(
                          color: colori.testoSecondario,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            for (final s in sedute) ...[
              const SizedBox(height: 14),
              _RigaSeduta(
                seduta: s,
                rpe: risposte[s.id],
                inSalvataggio: _inSalvataggio.contains(s.id),
                onScelto: (rpe) => _salva(s, rpe),
                onNonCero: risposte[s.id] == null ? () => _nascondi(s) : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RigaSeduta extends StatefulWidget {
  const _RigaSeduta({
    required this.seduta,
    required this.rpe,
    required this.inSalvataggio,
    required this.onScelto,
    required this.onNonCero,
  });

  final SedutaDaValutare seduta;
  final int? rpe;
  final bool inSalvataggio;
  final ValueChanged<int> onScelto;
  final VoidCallback? onNonCero;

  @override
  State<_RigaSeduta> createState() => _RigaSedutaState();
}

class _RigaSedutaState extends State<_RigaSeduta> {
  /// Con una risposta già data la scala si apre solo per cambiarla.
  bool _modifica = false;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final rpe = widget.rpe;
    final aperta = rpe == null || _modifica;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.seduta.descrizione,
                style: AppTypography.corpo.copyWith(color: colori.testo),
              ),
            ),
            if (rpe != null && !_modifica) ...[
              Text(
                descriviRpe(rpe),
                style: AppTypography.numerica(AppTypography.corpoForte)
                    .copyWith(color: colori.testo),
              ),
              TextButton(
                onPressed: () => setState(() => _modifica = true),
                child: const Text('Cambia'),
              ),
            ] else if (widget.onNonCero != null)
              TextButton(
                onPressed: widget.onNonCero,
                child: const Text('Non c\'ero'),
              ),
          ],
        ),
        if (aperta) ...[
          const SizedBox(height: AppSpacing.s8),
          ScalaRpe(
            valore: rpe,
            abilitata: !widget.inSalvataggio,
            onScelto: (v) {
              setState(() => _modifica = false);
              widget.onScelto(v);
            },
          ),
        ],
      ],
    );
  }
}

/// I numeri da 0 a 10 in due righe (0-5 e 6-10), grandi abbastanza per
/// il dito; sotto, la parola del numero scelto.
class ScalaRpe extends StatelessWidget {
  const ScalaRpe({
    required this.valore,
    required this.onScelto,
    this.abilitata = true,
    super.key,
  });

  final int? valore;
  final ValueChanged<int> onScelto;
  final bool abilitata;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return LayoutBuilder(
      builder: (context, vincoli) {
        const spazio = 6.0;
        final lato = ((vincoli.maxWidth - 5 * spazio) / 6).clamp(36.0, 56.0);
        Widget numero(int v) {
          final scelto = v == valore;
          return Semantics(
            button: true,
            selected: scelto,
            label: descriviRpe(v),
            excludeSemantics: true,
            child: SizedBox(
              width: lato,
              height: 44,
              child: Material(
                color: scelto ? colori.azione : colori.superficieAlt,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: scelto ? colori.azione : colori.linea,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: abilitata ? () => onScelto(v) : null,
                  child: Center(
                    child: Text(
                      '$v',
                      style: AppTypography.numerica(AppTypography.corpoForte)
                          .copyWith(
                            color: scelto ? colori.azioneInk : colori.testo,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: spazio,
              runSpacing: spazio,
              children: [for (var v = 0; v <= 10; v++) numero(v)],
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              valore == null
                  ? '0 riposo · 3 moderato · 5 duro · 7 molto duro · 10 al massimo'
                  : descriviRpe(valore!),
              style: AppTypography.etichetta.copyWith(
                color: colori.testoSecondario,
              ),
            ),
          ],
        );
      },
    );
  }
}
