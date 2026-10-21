import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../application/secco_providers.dart';
import '../data/secco_repository.dart';
import '../domain/esercizio_secco.dart';
import '../domain/varianti_secco.dart';
import 'foglio_esercizio.dart';
import 'scegli_esercizi_screen.dart';

/// Cosa fa [atletaId] di [riga] (un esercizio di tutti), in breve:
/// «come tutti», «variante: Extrarotazione», «non lo fa».
String cosaFaInBreve(
  EsercizioSeduta riga,
  String atletaId,
  Iterable<EsercizioSeduta> righe,
  Map<String, EsercizioSecco> esercizi,
) {
  final fa = cosaFa(riga, atletaId, righe);
  if (fa == null) return 'non lo fa';
  if (!fa.variante) return 'come tutti';
  return 'variante: ${esercizi[fa.esercizioId]?.nome ?? 'esercizio tolto'}';
}

enum _Scelta { cambia, comeTutti, piuLeggero, altro, nonLoFa }

/// Le scelte per un atleta su un esercizio di tutti: cambiare la sua
/// variante, farlo come tutti, farlo più leggero, farne un altro,
/// saltarlo. Le scelte che non cambierebbero niente non ci sono.
/// [dalleSottoRighe] dice «Fallo fare come tutti» invece di «Come tutti».
Future<void> mostraScelteVariante(
  BuildContext context,
  WidgetRef ref, {
  required Allenamento allenamento,
  required EsercizioSeduta riga,
  required String atletaId,
  required String nome,
  bool dalleSottoRighe = false,
}) async {
  final lavoro = _Lavoro(context, ref, allenamento, riga, atletaId, nome);
  final righe = lavoro.righe;
  final esercizi = lavoro.esercizi;
  final fa = cosaFa(lavoro.riga, atletaId, righe);
  final scelta = await showModalBottomSheet<_Scelta>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final colori = sheetContext.colori;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            0,
            AppSpacing.s16,
            AppSpacing.s16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                nome,
                style: AppTypography.sezione.copyWith(color: colori.testo),
              ),
              Text(
                '${esercizi[lavoro.riga.esercizioId]?.nome ?? 'Esercizio'}: '
                '${cosaFaInBreve(lavoro.riga, atletaId, righe, esercizi)}',
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              if (fa != null && fa.variante)
                _RigaScelta(
                  icona: Icons.edit_outlined,
                  titolo: 'Cambia',
                  aiuto: 'Serie, ripetizioni o carico della sua variante',
                  onTap: () => Navigator.of(sheetContext).pop(_Scelta.cambia),
                ),
              if (fa == null || fa.variante)
                _RigaScelta(
                  icona: Icons.groups_outlined,
                  titolo: dalleSottoRighe
                      ? 'Fallo fare come tutti'
                      : 'Come tutti',
                  aiuto: 'Torna all\'esercizio del gruppo',
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_Scelta.comeTutti),
                ),
              _RigaScelta(
                icona: Icons.trending_down,
                titolo: 'Lo stesso, più leggero',
                aiuto: 'Stesso esercizio con meno serie, ripetizioni o carico',
                onTap: () => Navigator.of(sheetContext).pop(_Scelta.piuLeggero),
              ),
              _RigaScelta(
                icona: Icons.swap_horiz,
                titolo: 'Un altro esercizio',
                aiuto: 'Lo scegli dall\'elenco del club',
                onTap: () => Navigator.of(sheetContext).pop(_Scelta.altro),
              ),
              if (fa != null)
                _RigaScelta(
                  icona: Icons.block,
                  titolo: 'Non lo fa',
                  aiuto: 'Salta questo esercizio',
                  onTap: () => Navigator.of(sheetContext).pop(_Scelta.nonLoFa),
                ),
            ],
          ),
        ),
      );
    },
  );
  if (scelta == null || !context.mounted) return;
  switch (scelta) {
    case _Scelta.cambia:
      await lavoro.cambia();
    case _Scelta.comeTutti:
      await lavoro.comeTutti();
    case _Scelta.piuLeggero:
      await lavoro.piuLeggero();
    case _Scelta.altro:
      await lavoro.altroEsercizio();
    case _Scelta.nonLoFa:
      await lavoro.nonLoFa();
  }
}

/// Una scelta del foglio: l'icona, cosa fa e, sotto, una riga che lo
/// spiega.
class _RigaScelta extends StatelessWidget {
  const _RigaScelta({
    required this.icona,
    required this.titolo,
    required this.aiuto,
    required this.onTap,
  });

  final IconData icona;
  final String titolo;
  final String aiuto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.altezzaMinimaRiga,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
          child: Row(
            children: [
              Icon(icona, color: colori.testoSecondario),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      titolo,
                      style: AppTypography.corpoForte.copyWith(
                        color: colori.testo,
                      ),
                    ),
                    Text(
                      aiuto,
                      style: AppTypography.piccolo.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quello che si fa per un atleta su un esercizio di tutti. Legge le righe
/// della seduta ogni volta (non quelle di quando si è aperto il foglio) e
/// dice a parole ogni errore.
class _Lavoro {
  _Lavoro(
    this.context,
    this.ref,
    this.allenamento,
    this.rigaIniziale,
    this.atletaId,
    this.nome,
  ) : _messaggero = ScaffoldMessenger.of(context);

  final BuildContext context;
  final WidgetRef ref;
  final Allenamento allenamento;
  final EsercizioSeduta rigaIniziale;
  final String atletaId;
  final String nome;
  final ScaffoldMessengerState _messaggero;

  SeccoRepository get _repo => ref.read(seccoRepositoryProvider);

  List<EsercizioSeduta> get righe =>
      ref.read(eserciziSedutaProvider(allenamento.id)).value ?? const [];

  Map<String, EsercizioSecco> get esercizi => {
    for (final e
        in ref.read(eserciziSeccoProvider(allenamento.clubId)).value ??
            const <EsercizioSecco>[])
      e.id: e,
  };

  /// L'esercizio di tutti com'è adesso.
  EsercizioSeduta get riga =>
      righe.where((r) => r.id == rigaIniziale.id).firstOrNull ?? rigaIniziale;

  /// La variante che l'atleta ha già di questo esercizio, se ne ha una.
  EsercizioSeduta? get _sua => variantiDi(
    riga,
    righe,
  ).where((v) => v.destinatari.soloAtleti.contains(atletaId)).firstOrNull;

  String get _nomeEsercizio =>
      esercizi[riga.esercizioId]?.nome ?? 'l\'esercizio';

  void _avviso(String testo, {SnackBarAction? azione}) => _messaggero
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(testo), action: azione));

  /// Esegue [azione]; un errore diventa un avviso, mai un crash.
  Future<void> _prova(Future<void> Function() azione) async {
    try {
      await azione();
    } catch (e) {
      if (context.mounted) _avviso(messaggioErrore(e));
    }
  }

  void _variantePronta() => _avviso(
    'Variante per $nome aggiunta',
    azione: SnackBarAction(label: 'Cambia', onPressed: cambia),
  );

  /// La variante dell'atleta al posto di quella che aveva, se ne aveva.
  Future<void> _metti(EsercizioSeduta nuova) async {
    final attuale = riga;
    if (_sua != null) {
      await _repo.comeTutti(
        attuale,
        atletaId,
        varianti: variantiDi(attuale, righe),
      );
    }
    await _repo.aggiungiVariante(attuale, nuova);
  }

  Future<void> cambia() async {
    final v = _sua;
    if (v == null || !context.mounted) return;
    await mostraFoglioEsercizio(
      context,
      esercizio: esercizi[v.esercizioId],
      riga: v,
      salva: _repo.aggiornaRiga,
    );
  }

  Future<void> comeTutti() => _prova(() async {
    final attuale = riga;
    await _repo.comeTutti(
      attuale,
      atletaId,
      varianti: variantiDi(attuale, righe),
    );
    if (context.mounted) _avviso('$nome fa $_nomeEsercizio come tutti');
  });

  Future<void> nonLoFa() => _prova(() async {
    final attuale = riga;
    await _repo.escludiAtleta(
      attuale,
      atletaId,
      varianti: variantiDi(attuale, righe),
    );
    if (context.mounted) _avviso('$nome non fa $_nomeEsercizio');
  });

  /// Lo stesso esercizio, con la prescrizione cambiata nel foglio (si parte
  /// da quella di tutti, o dalla sua variante se è lo stesso esercizio:
  /// allora la si cambia e basta, senza perdere le serie già registrate).
  Future<void> piuLeggero() async {
    var salvata = false;
    final sua = _sua;
    if (sua != null && sua.esercizioId == riga.esercizioId) {
      await mostraFoglioEsercizio(
        context,
        esercizio: esercizi[sua.esercizioId],
        riga: sua,
        salva: _repo.aggiornaRiga,
      );
      return;
    }
    await mostraFoglioEsercizio(
      context,
      esercizio: esercizi[riga.esercizioId],
      riga: riga,
      salva: (m) async {
        await _metti(
          nuovaVariante(
            riga: riga,
            atletaId: atletaId,
            esercizioId: riga.esercizioId,
            serie: m.serie,
            ripetizioni: m.ripetizioni,
            durataS: m.durataS,
            carico: _pieno(m.carico),
            recuperoS: m.recuperoS,
            note: _pieno(m.note),
          ),
        );
        salvata = true;
      },
    );
    if (salvata && context.mounted) _variantePronta();
  }

  /// Un altro esercizio dell'elenco, con la prescrizione dell'ultima volta.
  Future<void> altroEsercizio() async {
    var fatta = false;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ScegliEserciziScreen(
          clubId: allenamento.clubId,
          unoSolo: true,
          aggiungi: (scelti) async {
            if (scelti.isEmpty) return;
            final e = scelti.first;
            final p = prescrizioneProposta(
              e,
              ultima: await _repo.ultimaVolta(e.id),
            );
            await _metti(
              nuovaVariante(
                riga: riga,
                atletaId: atletaId,
                esercizioId: e.id,
                serie: p.serie,
                ripetizioni: p.ripetizioni,
                durataS: p.durataS,
                carico: p.carico,
                recuperoS: p.recuperoS,
              ),
            );
            fatta = true;
          },
        ),
      ),
    );
    if (fatta && context.mounted) _variantePronta();
  }
}

String? _pieno(String? t) => t == null || t.trim().isEmpty ? null : t.trim();
