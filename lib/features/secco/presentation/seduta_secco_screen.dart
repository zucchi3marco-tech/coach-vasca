import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/pool_card.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../../widgets/tonal_chip.dart';
import '../../allenamenti/application/allenamenti_providers.dart';
import '../../allenamenti/data/allenamenti_repository.dart';
import '../../allenamenti/data/duplicazione_settimana_service.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../allenamenti/presentation/allenamento_form_screen.dart';
import '../../allenamenti/presentation/duplica_allenamento_dialog.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../presenze/presentation/presenze_screen.dart';
import '../application/secco_providers.dart';
import '../data/secco_repository.dart';
import '../domain/esercizio_secco.dart';
import 'esercizi_secco_screen.dart';
import 'scegli_esercizi_screen.dart';
import 'secco_widgets.dart';

/// Una seduta a secco vista dall'allenatore: in testata quando, quanti
/// esercizi e quanto dura, con "Presenze"; sotto gli esercizi in ordine.
/// Il "+" li sceglie dall'elenco del club; un tocco su una riga cambia
/// serie, ripetizioni o tempo, carico e recupero.
class SedutaSeccoScreen extends ConsumerWidget {
  const SedutaSeccoScreen({required this.allenamento, super.key});

  final Allenamento allenamento;

  void _apri(BuildContext context, Widget schermata) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => schermata));

  void _avviso(BuildContext context, String testo) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(testo)));

  Future<void> _duplica(
    BuildContext context,
    WidgetRef ref,
    Allenamento a,
  ) async {
    final gruppi = ref.read(gruppiListProvider(a.clubId)).value ?? const [];
    final dove = await chiediDoveDuplicare(
      context,
      allenamento: a,
      gruppi: gruppi,
    );
    if (dove == null || !context.mounted) return;
    final navigatore = Navigator.of(context);
    try {
      final copia = await ref
          .read(duplicazioneSettimanaServiceProvider)
          .copiaAllenamento(a, data: dove.data, gruppoId: dove.gruppoId);
      if (!context.mounted) return;
      _avviso(context, 'Seduta copiata: ora puoi modificarla');
      await navigatore.pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => SedutaSeccoScreen(allenamento: copia),
        ),
      );
    } catch (e) {
      if (context.mounted) _avviso(context, messaggioErrore(e));
    }
  }

  Future<void> _elimina(
    BuildContext context,
    WidgetRef ref,
    Allenamento a,
  ) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminare la seduta a secco?'),
        content: const Text(
          'Verranno eliminati per sempre anche i suoi esercizi e le presenze '
          'registrate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annulla'),
          ),
          DangerButton(
            label: 'Elimina',
            expanded: false,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (conferma != true || !context.mounted) return;
    try {
      await ref.read(allenamentiRepositoryProvider).deleteAllenamento(a.id);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) _avviso(context, messaggioErrore(e));
    }
  }

  Future<void> _sposta(
    BuildContext context,
    WidgetRef ref,
    List<EsercizioSeduta> righe,
    int da,
    int a,
  ) async {
    final ordinate = [...righe];
    final r = ordinate.removeAt(da);
    ordinate.insert(a, r);
    try {
      await ref.read(seccoRepositoryProvider).riordina(ordinate);
    } catch (e) {
      if (context.mounted) _avviso(context, messaggioErrore(e));
    }
  }

  Future<void> _togli(
    BuildContext context,
    WidgetRef ref,
    List<EsercizioSeduta> righe,
    EsercizioSeduta riga,
  ) async {
    try {
      final repository = ref.read(seccoRepositoryProvider);
      await repository.eliminaRiga(riga.id);
      await repository.riordina([
        for (final r in righe)
          if (r.id != riga.id) r,
      ]);
    } catch (e) {
      if (context.mounted) _avviso(context, messaggioErrore(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    // La seduta com'è adesso (dopo una modifica di data, titolo o durata).
    final a =
        ref
            .watch(allenamentiListProvider(allenamento.clubId))
            .value
            ?.where((x) => x.id == allenamento.id)
            .firstOrNull ??
        allenamento;
    final righeAsync = ref.watch(eserciziSedutaProvider(a.id));
    final esercizi = {
      for (final e
          in ref.watch(eserciziSeccoProvider(a.clubId)).value ??
              const <EsercizioSecco>[])
        e.id: e,
    };
    String? nomeGruppo;
    for (final g in ref.watch(gruppiListProvider(a.clubId)).value ?? []) {
      if (g.id == a.gruppoId) nomeGruppo = g.nome;
    }
    final righe = righeAsync.value ?? const <EsercizioSeduta>[];
    final stima = minutiStimati(righe);

    void scegli() => _apri(
      context,
      ScegliEserciziScreen(allenamento: a, ordineSuccessivo: righe.length + 1),
    );

    final testata = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TestataPagina(
          occhiello: [quandoEsteso(a.data), ?nomeGruppo].join(' · '),
          titolo: a.titoloMostrato,
          sottotitolo: a.titolo != null && a.titolo!.trim().isNotEmpty
              ? 'Seduta a secco'
              : null,
          numeri: [
            NumeroTestata(valore: '${righe.length}', etichetta: 'Esercizi'),
            NumeroTestata(valore: "${minutiSeduta(a)}'", etichetta: 'Durata'),
          ],
          azioni: [
            AzioneTestata(
              icona: Icons.how_to_reg_outlined,
              etichetta: 'Presenze',
              principale: true,
              onTap: () => _apri(context, PresenzeScreen(allenamento: a)),
            ),
          ],
        ),
        if (a.note != null && a.note!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s12),
          PoolCard(
            child: Text(
              a.note!,
              style: AppTypography.piccolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.s24),
      ],
    );

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Seduta a secco'),
        actions: [
          PopupMenuButton<VoidCallback>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Altre azioni',
            onSelected: (azione) => azione(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: () => _apri(
                  context,
                  AllenamentoFormScreen(clubId: a.clubId, allenamento: a),
                ),
                child: const Text('Modifica data, titolo, durata e note'),
              ),
              PopupMenuItem(
                value: () =>
                    _apri(context, EserciziSeccoScreen(clubId: a.clubId)),
                child: const Text('Elenco esercizi del club'),
              ),
              PopupMenuItem(
                value: () => _duplica(context, ref, a),
                child: const Text('Duplica'),
              ),
              PopupMenuItem(
                value: () => _elimina(context, ref, a),
                child: const Text('Elimina'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-seduta-secco',
        tooltip: 'Aggiungi esercizi',
        onPressed: scegli,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          testata,
          ...righeAsync.when(
            data: (righe) => righe.isEmpty
                ? [
                    EmptyState(
                      icona: Icons.fitness_center,
                      titolo: 'Nessun esercizio',
                      descrizione:
                          'Scegli gli esercizi dall\'elenco del club: spalla, '
                          'scapole, core, gambe. Per ognuno serie, '
                          'ripetizioni o tempo e recupero.',
                      azionePrincipale: 'Aggiungi esercizi',
                      onAzionePrincipale: scegli,
                    ),
                  ]
                : [
                    TitoloSezione(
                      'Esercizi',
                      conteggio: righe.length,
                      // La stima solo quando dice qualcosa in più della
                      // durata scritta.
                      spiegazione: (stima - minutiSeduta(a)).abs() >= 5
                          ? "Fatti come scritto durano circa $stima'."
                          : null,
                    ),
                    AppListPanel(
                      righe: [
                        for (final (i, r) in righe.indexed)
                          RigaEsercizio(
                            numero: i + 1,
                            esercizio: esercizi[r.esercizioId],
                            riga: r,
                            sotto: r.note,
                            onTap: () => mostraFoglioEsercizio(
                              context,
                              esercizio: esercizi[r.esercizioId],
                              riga: r,
                            ),
                            trailing: PopupMenuButton<String>(
                              tooltip: 'Azioni dell\'esercizio',
                              icon: Icon(
                                Icons.more_vert,
                                color: colori.testoSecondario,
                              ),
                              onSelected: (azione) => switch (azione) {
                                'su' => _sposta(context, ref, righe, i, i - 1),
                                'giu' => _sposta(context, ref, righe, i, i + 1),
                                _ => _togli(context, ref, righe, r),
                              },
                              itemBuilder: (_) => [
                                if (i > 0)
                                  const PopupMenuItem(
                                    value: 'su',
                                    child: Text('Sposta su'),
                                  ),
                                if (i < righe.length - 1)
                                  const PopupMenuItem(
                                    value: 'giu',
                                    child: Text('Sposta giù'),
                                  ),
                                const PopupMenuItem(
                                  value: 'togli',
                                  child: Text('Togli dalla seduta'),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
            loading: () => const [LoadingSkeletonList(righe: 4)],
            error: (errore, _) => [
              ErrorBanner(
                messaggio: 'Non è stato possibile caricare gli esercizi.',
                suggerimento:
                    'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
                dettaglioTecnico: messaggioErrore(errore),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Il foglio di un esercizio della seduta: come si fa, poi serie,
/// ripetizioni o tempo, carico, recupero e note.
Future<void> mostraFoglioEsercizio(
  BuildContext context, {
  required EsercizioSecco? esercizio,
  required EsercizioSeduta riga,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _FoglioEsercizio(esercizio: esercizio, riga: riga),
);

/// I recuperi fra le serie che si scelgono con un tocco.
const _recuperi = [0, 30, 45, 60, 90, 120, 180];

class _FoglioEsercizio extends ConsumerStatefulWidget {
  const _FoglioEsercizio({required this.esercizio, required this.riga});

  final EsercizioSecco? esercizio;
  final EsercizioSeduta riga;

  @override
  ConsumerState<_FoglioEsercizio> createState() => _FoglioEsercizioState();
}

class _FoglioEsercizioState extends ConsumerState<_FoglioEsercizio> {
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
      await ref
          .read(seccoRepositoryProvider)
          .aggiornaRiga(
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
                for (final s in _recuperi)
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
