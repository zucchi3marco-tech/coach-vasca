import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/giorni.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../secco/data/secco_repository.dart';
import '../data/allenamenti_repository.dart';
import '../data/seduta_aperta_repository.dart';
import '../data/serie_repository.dart';

/// "alle 18:07", "ieri alle 18:07", "lun 26 ott alle 18:07".
String quandoCambiata(DateTime d, {DateTime? oggi}) {
  final giorni = giorniTra(d, oggi ?? DateTime.now());
  final ora = 'alle ${oraMinuti(d)}';
  if (giorni == 0) return ora;
  if (giorni == 1) return 'ieri $ora';
  return '${dataCompatta(d)} $ora';
}

/// Rilegge dal server la seduta, le sue serie e i suoi esercizi a secco,
/// e segna la versione letta.
Future<void> rileggiSeduta(
  WidgetRef ref, {
  required String allenamentoId,
  required String clubId,
  int? versione,
}) async {
  try {
    await Future.wait([
      ref.read(serieRepositoryProvider).refreshFromRemote(allenamentoId),
      ref.read(seccoRepositoryProvider).refreshSeduta(allenamentoId),
      ref.read(allenamentiRepositoryProvider).refreshFromRemote(clubId),
    ]);
  } catch (_) {
    // Senza rete resta la copia del telefono.
    return;
  }
  if (versione != null) {
    ref.read(versioniLetteProvider)[allenamentoId] = versione;
  }
}

/// Prima di salvare una modifica alla seduta: se intanto un collega l'ha
/// cambiata, lo dice e fa scegliere. true = si salva; false = si è scelto
/// di vedere la sua versione (la seduta è già riletta: chi chiama chiude
/// il modulo senza salvare); null = finestra chiusa senza scegliere (non
/// si salva, il modulo resta aperto). Senza rete si salva come sempre.
Future<bool?> controllaPrimaDiSalvare(
  BuildContext context,
  WidgetRef ref, {
  required String allenamentoId,
  required String clubId,
}) async {
  final stato = await ref
      .read(sedutaApertaRepositoryProvider)
      .apri(allenamentoId);
  if (stato == null) return true;
  final lette = ref.read(versioniLetteProvider);
  final letta = lette[allenamentoId];
  if (!stato.cambiataDaUnAltro(letta)) {
    lette[allenamentoId] = stato.versione;
    return true;
  }
  if (!context.mounted) return null;
  final chi = stato.cambiataNome ?? 'Un collega';
  final quando = stato.cambiataAt == null
      ? ''
      : ' ${quandoCambiata(stato.cambiataAt!)}';
  final salva = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('La seduta è cambiata'),
      content: Text(
        '$chi l\'ha cambiata$quando, mentre tu la modificavi. Se salvi, '
        'quello che hai scritto qui prende il posto della sua versione.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Vedi la sua versione'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Salva la mia'),
        ),
      ],
    ),
  );
  if (salva == true) {
    lette[allenamentoId] = stato.versione;
    return true;
  }
  if (salva == false) {
    await rileggiSeduta(
      ref,
      allenamentoId: allenamentoId,
      clubId: clubId,
      versione: stato.versione,
    );
    return false;
  }
  return null;
}

/// Dopo un salvataggio andato: la versione letta diventa la mia.
Future<void> sedutaSalvata(WidgetRef ref, String allenamentoId) async {
  final lette = ref.read(versioniLetteProvider);
  final stato = await ref
      .read(sedutaApertaRepositoryProvider)
      .apri(allenamentoId);
  if (stato != null && stato.cambiataDaMe) {
    lette[allenamentoId] = stato.versione;
  }
}

/// In cima alla seduta: chi altro la sta modificando adesso e, se intanto
/// un collega l'ha cambiata, «Aggiorna». Dice al server che la seduta è
/// aperta finché la pagina resta aperta (ogni minuto). Senza rete non
/// mostra niente.
class AvvisoSedutaAperta extends ConsumerStatefulWidget {
  const AvvisoSedutaAperta({
    required this.allenamentoId,
    required this.clubId,
    this.ogni = const Duration(minutes: 1),
    super.key,
  });

  final String allenamentoId;
  final String clubId;

  /// Ogni quanto si rinnova (le prove lo accorciano).
  final Duration ogni;

  @override
  ConsumerState<AvvisoSedutaAperta> createState() => _AvvisoSedutaApertaState();
}

class _AvvisoSedutaApertaState extends ConsumerState<AvvisoSedutaAperta> {
  late final SedutaApertaRepository _repository;
  late final Map<String, int> _lette;
  Timer? _timer;
  StatoSeduta? _stato;
  var _rileggo = false;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(sedutaApertaRepositoryProvider);
    _lette = ref.read(versioniLetteProvider);
    _primaVolta();
    _timer = Timer.periodic(widget.ogni, (_) => _rinnova());
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_repository.chiudi(widget.allenamentoId));
    super.dispose();
  }

  /// Aprendo la seduta: se la copia del telefono è più vecchia di quella
  /// del server (o non si sa), si rilegge subito.
  Future<void> _primaVolta() async {
    final stato = await _repository.apri(widget.allenamentoId);
    if (stato == null || !mounted) return;
    final letta = _lette[widget.allenamentoId];
    if (letta == null || stato.cambiataDaUnAltro(letta)) {
      await rileggiSeduta(
        ref,
        allenamentoId: widget.allenamentoId,
        clubId: widget.clubId,
        versione: stato.versione,
      );
    } else {
      _lette[widget.allenamentoId] = stato.versione;
    }
    if (mounted) setState(() => _stato = stato);
  }

  Future<void> _rinnova() async {
    final stato = await _repository.apri(widget.allenamentoId);
    if (stato == null || !mounted) return;
    if (stato.cambiataDaMe) _lette[widget.allenamentoId] = stato.versione;
    setState(() => _stato = stato);
  }

  Future<void> _aggiorna() async {
    final stato = _stato;
    if (stato == null) return;
    setState(() => _rileggo = true);
    await rileggiSeduta(
      ref,
      allenamentoId: widget.allenamentoId,
      clubId: widget.clubId,
      versione: stato.versione,
    );
    if (mounted) setState(() => _rileggo = false);
  }

  @override
  Widget build(BuildContext context) {
    final stato = _stato;
    if (stato == null) return const SizedBox.shrink();
    final cambiata = stato.cambiataDaUnAltro(_lette[widget.allenamentoId]);
    if (stato.altri.isEmpty && !cambiata) return const SizedBox.shrink();
    final colori = context.colori;
    final aperta = [
      for (final a in stato.altri)
        '${a.nome} la sta modificando (dalle ${oraMinuti(a.dal)})',
    ].join('\n');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: colori.attenzioneTenue,
          borderRadius: BorderRadius.circular(AppRadius.controllo),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.people_alt_outlined, color: colori.attenzione, size: 20),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (aperta.isNotEmpty)
                    Text(
                      aperta,
                      style: AppTypography.corpoForte.copyWith(
                        color: colori.testo,
                      ),
                    ),
                  if (cambiata)
                    Text(
                      '${stato.cambiataNome ?? 'Un collega'} l\'ha cambiata'
                      '${stato.cambiataAt == null ? '' : ' ${quandoCambiata(stato.cambiataAt!)}'}: '
                      'qui vedi ancora la versione di prima.',
                      style: AppTypography.corpo.copyWith(color: colori.testo),
                    )
                  else
                    Text(
                      'Potete lavorare insieme: se salvate tutti e due la '
                      'stessa cosa, l\'app chiede quale versione tenere.',
                      style: AppTypography.piccolo.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                  if (cambiata)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _rileggo ? null : _aggiorna,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Aggiorna'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
