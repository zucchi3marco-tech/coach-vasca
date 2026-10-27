import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/giorni.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/riquadri.dart';
import '../../../widgets/secondary_button.dart';
import '../../club/application/current_club_provider.dart';
import '../../gare/application/gare_providers.dart';
import '../../gare/domain/gara.dart';
import '../../pallanuoto/application/pallanuoto_providers.dart';
import '../../pallanuoto/domain/partita.dart';
import '../data/stagioni_repository.dart';
import '../domain/evento_calendario.dart';
import '../domain/fasi_a_ritroso.dart';
import '../domain/stagione.dart';

/// «Proponi le fasi»: l'allenatore sceglie fino a tre obiettivi (una
/// partita, una gara o un giorno scritto a mano) e l'app costruisce le fasi
/// a ritroso: preparazione, andata e ritorno dalle partite della squadra,
/// scarico e il giorno dell'obiettivo (vedi [proponiFasi]). Si allungano o
/// si accorciano di una settimana alla volta, poi «Usa queste fasi».
class ProponiFasiScreen extends ConsumerStatefulWidget {
  const ProponiFasiScreen({required this.stagione, super.key});

  final Stagione stagione;

  @override
  ConsumerState<ProponiFasiScreen> createState() => _ProponiFasiScreenState();
}

class _ProponiFasiScreenState extends ConsumerState<ProponiFasiScreen> {
  final _obiettivi = <ObiettivoStagione>[];
  int _scarico = 1;

  /// Le fasi con i confini spostati a mano; null = quelle proposte.
  List<FaseProposta>? _spostate;
  bool _salvataggio = false;
  String? _errore;

  void _cambia(VoidCallback cambio) => setState(() {
    cambio();
    _spostate = null;
  });

  Future<String?> _chiediNome(String iniziale) => showDialog<String>(
    context: context,
    builder: (_) => _DialogoNome(iniziale: iniziale),
  );

  Future<void> _aggiungi(List<EventoCalendario> eventi) async {
    final usati = {for (final o in _obiettivi) o.eventoId};
    final scelta = await showModalBottomSheet<_Scelta>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ScegliObiettivo(
        eventi: [
          for (final e in eventi)
            if (!usati.contains(e.id)) e,
        ],
      ),
    );
    if (scelta == null || !mounted) return;
    var data = scelta.evento?.data;
    if (data == null) {
      final s = widget.stagione;
      final oggi = soloData(DateTime.now());
      data = await showDatePicker(
        context: context,
        initialDate: oggi.isBefore(s.dataInizio) || oggi.isAfter(s.dataFine)
            ? s.dataFine
            : oggi,
        firstDate: s.dataInizio,
        lastDate: s.dataFine,
        helpText: 'Il giorno dell\'obiettivo',
      );
      if (data == null || !mounted) return;
    }
    final nome = await _chiediNome(scelta.evento?.titolo ?? 'Obiettivo');
    if (nome == null || !mounted) return;
    _cambia(
      () => _obiettivi
        ..add(
          ObiettivoStagione(
            nome: nome,
            data: soloData(data!),
            eventoId: scelta.evento?.id,
          ),
        )
        ..sort((a, b) => a.data.compareTo(b.data)),
    );
  }

  Future<void> _rinomina(int i) async {
    final nome = await _chiediNome(_obiettivi[i].nome);
    if (nome == null || !mounted) return;
    _cambia(() => _obiettivi[i] = _obiettivi[i].conNome(nome));
  }

  Future<void> _usa(List<FaseProposta> fasi) async {
    final attuali = widget.stagione.fasi;
    if (attuali.isNotEmpty) {
      final conferma = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sostituire le fasi?'),
          content: Text(
            'La stagione ha già ${attuali.length == 1 ? 'una fase' : '${attuali.length} fasi'}: '
            'al loro posto vanno queste ${fasi.length}. Una fase con lo '
            'stesso nome di una di adesso tiene «A cosa serve», gli '
            'obiettivi di volume e carico e le righe delle settimane.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sostituisci'),
            ),
          ],
        ),
      );
      if (conferma != true || !mounted) return;
    }
    setState(() {
      _salvataggio = true;
      _errore = null;
    });
    try {
      await ref
          .read(stagioniRepositoryProvider)
          .salvaFasi(widget.stagione.id, fasiDaProposta(fasi, attuali));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _salvataggio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final stagione = widget.stagione;
    final sport = ref.watch(currentClubProvider).value?.sport;
    final conPartite = sport == null || sport == 'pallanuoto';
    final conGare = sport == null || sport == 'nuoto';
    final partite = conPartite
        ? ref.watch(partiteListProvider(stagione.clubId)).value ??
              const <Partita>[]
        : const <Partita>[];
    final gare = conGare
        ? ref.watch(gareListProvider(stagione.clubId)).value ?? const <Gara>[]
        : const <Gara>[];
    final eventi = eventiVisibiliInStagione(stagione, [
      for (final p in partite) EventoCalendario.daPartita(p),
      for (final g in gare) EventoCalendario.daGara(g),
    ])..sort((a, b) => a.data.compareTo(b.data));
    final giorniPartite = [
      for (final e in eventi)
        if (e.tipo == TipoEventoCalendario.partita) e.data,
    ];

    final proposte = proponiFasi(
      inizioStagione: stagione.dataInizio,
      fineStagione: stagione.dataFine,
      partite: giorniPartite,
      obiettivi: _obiettivi,
      settimaneScarico: _scarico,
    );
    final fasi = _spostate ?? proposte;
    // Quelle che fanno andata e ritorno: prima del primo obiettivo, senza
    // le partite scelte come obiettivo.
    final giorniObiettivi = {for (final o in _obiettivi) soloData(o.data)};
    final primoObiettivo = _obiettivi.isEmpty ? null : _obiettivi.first.data;
    final diCampionato = giorniPartite
        .where(
          (d) =>
              !giorniObiettivi.contains(soloData(d)) &&
              (primoObiettivo == null || d.isBefore(primoObiettivo)),
        )
        .length;

    void sposta(int i, int giorni) {
      final nuove = spostaConfine(fasi, i, giorni);
      if (nuove != null) setState(() => _spostate = nuove);
    }

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(title: const Text('Proponi le fasi')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormGroup(
            titolo: 'Obiettivi',
            spiegazione:
                'Le partite o le gare per cui la squadra deve essere al '
                'massimo, fino a tre. Le fasi si contano a ritroso da lì.',
            campi: [
              if (_obiettivi.isEmpty)
                Text(
                  'Nessun obiettivo: le fasi seguono solo le partite.',
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                )
              else
                AppListPanel(
                  righe: [
                    for (final (i, o) in _obiettivi.indexed)
                      AppListRow(
                        leading: Icon(
                          Icons.flag_outlined,
                          color: colori.azione,
                        ),
                        titolo: o.nome,
                        sottotitolo:
                            '${dataLunga(o.data)} · tocca per cambiare il nome',
                        trailing: IconButton(
                          tooltip: 'Togli l\'obiettivo',
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              _cambia(() => _obiettivi.removeAt(i)),
                        ),
                        onTap: () => _rinomina(i),
                      ),
                  ],
                ),
              if (_obiettivi.length < obiettiviMassimi)
                Align(
                  alignment: Alignment.centerLeft,
                  child: SecondaryButton(
                    label: 'Aggiungi un obiettivo',
                    icon: Icons.add,
                    expanded: false,
                    onPressed: () => _aggiungi(eventi),
                  ),
                ),
              if (_obiettivi.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Settimane di scarico prima di ogni obiettivo',
                        style: AppTypography.corpo.copyWith(
                          color: colori.testo,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Una settimana di scarico in meno',
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _scarico > 0
                          ? () => _cambia(() => _scarico--)
                          : null,
                    ),
                    Text(
                      '$_scarico',
                      style: AppTypography.corpoForte.copyWith(
                        color: colori.testo,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Una settimana di scarico in più',
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _scarico < settimaneScaricoMassime
                          ? () => _cambia(() => _scarico++)
                          : null,
                    ),
                  ],
                ),
            ],
          ),
          FormGroup(
            titolo: 'Le fasi',
            spiegazione:
                'Con − e + una fase finisce una settimana prima o dopo, e '
                'la successiva comincia di conseguenza. Il giorno di un '
                'obiettivo non si sposta.',
            isUltimo: true,
            campi: [
              Text(
                diCampionato == 0
                    ? 'Nessuna partita della squadra prima dell\'obiettivo: '
                          'andata e ritorno compariranno quando aggiungi le '
                          'partite.'
                    : 'Andata e ritorno dalle $diCampionato partite della '
                          'squadra${diCampionato > 1 ? ', divise a metà' : ''}.',
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
              if (fasi.isEmpty)
                const RiquadroVuoto('La stagione non ha giorni.')
              else
                AppListPanel(
                  righe: [
                    for (final (i, f) in fasi.indexed)
                      AppListRow(
                        leading: f.bloccata
                            ? Icon(Icons.flag, color: colori.azione)
                            : null,
                        titolo: f.nome,
                        sottotitolo:
                            '${dataCompatta(f.dataInizio)} – '
                            '${dataCompatta(f.dataFine)} · ${_durata(f)}',
                        trailing:
                            i + 1 < fasi.length &&
                                !f.bloccata &&
                                !fasi[i + 1].bloccata
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: '${f.nome}: una settimana in meno',
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    onPressed:
                                        spostaConfine(fasi, i, -7) == null
                                        ? null
                                        : () => sposta(i, -7),
                                  ),
                                  IconButton(
                                    tooltip: '${f.nome}: una settimana in più',
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: spostaConfine(fasi, i, 7) == null
                                        ? null
                                        : () => sposta(i, 7),
                                  ),
                                ],
                              )
                            : null,
                      ),
                  ],
                ),
            ],
          ),
          if (_errore != null) ...[
            ErrorBanner(messaggio: _errore!),
            const SizedBox(height: AppSpacing.s16),
          ],
          PrimaryButton(
            label: 'Usa queste fasi',
            isLoading: _salvataggio,
            onPressed: _salvataggio || fasi.isEmpty ? null : () => _usa(fasi),
          ),
        ],
      ),
    );
  }
}

String _durata(FaseProposta f) {
  if (f.giorni == 1) return 'un giorno';
  if (f.giorni < 7) return '${f.giorni} giorni';
  final settimane = (f.giorni / 7).round();
  return settimane == 1 ? 'una settimana' : '$settimane settimane';
}

/// Quello che si sceglie nel foglio: un evento del calendario, o (null) un
/// giorno scritto a mano.
class _Scelta {
  const _Scelta(this.evento);
  final EventoCalendario? evento;
}

/// Le partite e le gare della stagione da cui scegliere l'obiettivo, e in
/// cima «Un giorno scritto a mano».
class _ScegliObiettivo extends StatelessWidget {
  const _ScegliObiettivo({required this.eventi});

  final List<EventoCalendario> eventi;

  bool _importante(EventoCalendario e) => switch (e.origine) {
    Partita(:final importanza) => importanza == 'alta',
    Gara(:final importanza) => importanza == 'alta',
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          0,
          AppSpacing.s16,
          AppSpacing.s24,
        ),
        children: [
          Text(
            'Scegli l\'obiettivo',
            style: AppTypography.sezione.copyWith(color: colori.testo),
          ),
          const SizedBox(height: AppSpacing.s12),
          AppListPanel(
            righe: [
              AppListRow(
                leading: Icon(
                  Icons.edit_calendar_outlined,
                  color: colori.azione,
                ),
                titolo: 'Un giorno scritto a mano',
                sottotitolo: 'Per un obiettivo che non è nel calendario',
                onTap: () => Navigator.of(context).pop(const _Scelta(null)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          if (eventi.isEmpty)
            const RiquadroVuoto(
              'Nel calendario della stagione non ci sono partite o gare.',
            )
          else
            AppListPanel(
              righe: [
                for (final e in eventi)
                  AppListRow(
                    leading: Icon(
                      e.tipo == TipoEventoCalendario.partita
                          ? Icons.sports_handball_outlined
                          : Icons.pool_outlined,
                      color: colori.testoSecondario,
                    ),
                    titolo: e.titolo,
                    extraTitolo: _importante(e)
                        ? Padding(
                            padding: const EdgeInsets.only(left: AppSpacing.s8),
                            child: Pastiglia(
                              'Importante',
                              colore: colori.attenzione,
                            ),
                          )
                        : null,
                    sottotitolo: dataLunga(e.data),
                    onTap: () => Navigator.of(context).pop(_Scelta(e)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Il nome di un obiettivo, che diventa il nome della sua fase. Torna il
/// nome scritto, null se si annulla.
class _DialogoNome extends StatefulWidget {
  const _DialogoNome({required this.iniziale});

  final String iniziale;

  @override
  State<_DialogoNome> createState() => _DialogoNomeState();
}

class _DialogoNomeState extends State<_DialogoNome> {
  late final _testo = TextEditingController(text: widget.iniziale);

  @override
  void dispose() {
    _testo.dispose();
    super.dispose();
  }

  void _ok() {
    final t = _testo.text.trim();
    if (t.isEmpty) return;
    Navigator.of(context).pop(t);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Nome dell\'obiettivo'),
    content: TextField(
      controller: _testo,
      autofocus: true,
      maxLength: 60,
      decoration: const InputDecoration(
        helperText: 'Diventa il nome della sua fase, es. «Finali nazionali».',
      ),
      onSubmitted: (_) => _ok(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Annulla'),
      ),
      FilledButton(onPressed: _ok, child: const Text('Fatto')),
    ],
  );
}
