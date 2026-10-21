import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/tonal_chip.dart';
import '../application/secco_providers.dart';
import '../data/secco_repository.dart';
import '../domain/esercizio_secco.dart';
import 'esercizio_secco_form_screen.dart';
import 'secco_widgets.dart';

/// Una voce dell'elenco da cui scegliere: un esercizio del club o uno
/// pronto non ancora aggiunto (si aggiunge al club quando lo si sceglie).
typedef _Voce = ({
  String chiave,
  String nome,
  CategoriaEsercizio categoria,
  String? attrezzo,
  bool aTempo,
  String? descrizione,
  EsercizioSecco? delClub,
  ModelloEsercizio? pronto,
});

/// Si scelgono gli esercizi da aggiungere a una seduta (o a una seduta di
/// un programma), nell'ordine in cui farli (il numero accanto lo dice):
/// quelli del club e quelli pronti, per categoria. Chi apre la pagina li
/// mette nella seduta, di solito con la prescrizione dell'ultima volta (o
/// quella dell'esercizio pronto), da cambiare poi con un tocco.
///
/// Con [unoSolo] se ne sceglie uno: un tocco sull'esercizio lo consegna
/// subito (per la variante di un atleta).
class ScegliEserciziScreen extends ConsumerStatefulWidget {
  const ScegliEserciziScreen({
    required this.clubId,
    required this.aggiungi,
    this.unoSolo = false,
    super.key,
  });

  final String clubId;

  /// Un solo esercizio: niente numeri né pulsante in fondo, un tocco lo
  /// sceglie.
  final bool unoSolo;

  /// Riceve gli esercizi scelti in ordine (quelli pronti già aggiunti
  /// all'elenco del club) e li mette nella seduta.
  final Future<void> Function(List<EsercizioSecco> scelti) aggiungi;

  @override
  ConsumerState<ScegliEserciziScreen> createState() =>
      _ScegliEserciziScreenState();
}

class _ScegliEserciziScreenState extends ConsumerState<ScegliEserciziScreen> {
  /// Le chiavi scelte, nell'ordine in cui sono state toccate.
  final _scelte = <String>[];
  CategoriaEsercizio? _filtro;
  bool _aggiungo = false;
  String? _errore;

  void _alterna(String chiave) => setState(() {
    if (!_scelte.remove(chiave)) _scelte.add(chiave);
  });

  Future<void> _nuovo() async {
    final creato = await Navigator.of(context).push<EsercizioSecco>(
      MaterialPageRoute(
        builder: (_) => EsercizioSeccoFormScreen(clubId: widget.clubId),
      ),
    );
    if (creato == null || !mounted) return;
    if (widget.unoSolo) {
      await _consegna(() async => [creato]);
    } else {
      setState(() => _scelte.add(creato.id));
    }
  }

  /// Aggiunge alla seduta le voci con queste [chiavi] (quelle pronte
  /// entrano prima nell'elenco del club).
  Future<void> _aggiungi(Map<String, _Voce> voci, List<String> chiavi) =>
      _consegna(() async {
        final repository = ref.read(seccoRepositoryProvider);
        final scelti = <EsercizioSecco>[];
        for (final chiave in chiavi) {
          final voce = voci[chiave];
          if (voce == null) continue;
          scelti.add(
            voce.delClub ??
                await repository.creaEsercizio(
                  EsercizioSecco(
                    id: '',
                    clubId: widget.clubId,
                    nome: voce.pronto!.nome,
                    categoria: voce.pronto!.categoria,
                    misura: voce.pronto!.misura,
                    attrezzo: voce.pronto!.attrezzo,
                    descrizione: voce.pronto!.descrizione,
                    modello: voce.pronto!.chiave,
                  ),
                ),
          );
        }
        return scelti;
      });

  Future<void> _consegna(
    Future<List<EsercizioSecco>> Function() prepara,
  ) async {
    setState(() {
      _aggiungo = true;
      _errore = null;
    });
    final messaggero = ScaffoldMessenger.of(context);
    try {
      final scelti = await prepara();
      await widget.aggiungi(scelti);
      final aggiunti = scelti.length;
      if (!mounted) return;
      Navigator.of(context).pop();
      // Chi ne sceglie uno solo dice da sé che cosa ne ha fatto.
      if (widget.unoSolo) return;
      messaggero.showSnackBar(
        SnackBar(
          content: Text(
            aggiunti == 1
                ? 'Esercizio aggiunto'
                : '$aggiunti esercizi aggiunti',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errore = messaggioErrore(e);
          _aggiungo = false;
        });
      }
    }
  }

  void _comeSiFa(_Voce v) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(v.nome),
      content: Text(v.descrizione ?? ''),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Chiudi'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final eserciziAsync = ref.watch(eserciziSeccoProvider(widget.clubId));

    return AppScaffold(
      appBar: AppBar(
        title: Text(
          widget.unoSolo ? 'Scegli un esercizio' : 'Aggiungi esercizi',
        ),
        actions: [
          IconButton(
            tooltip: 'Nuovo esercizio',
            icon: const Icon(Icons.add),
            onPressed: _aggiungo ? null : _nuovo,
          ),
        ],
      ),
      body: eserciziAsync.when(
        data: (esercizi) {
          final voci = _voci(esercizi);
          final perCategoria = <CategoriaEsercizio, List<_Voce>>{};
          for (final v in voci.values) {
            if (_filtro == null || v.categoria == _filtro) {
              (perCategoria[v.categoria] ??= []).add(v);
            }
          }
          final categorie = [
            for (final c in CategoriaEsercizio.values)
              if (voci.values.any((v) => v.categoria == c)) c,
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s16),
                  children: [
                    Text(
                      widget.unoSolo
                          ? 'Tocca l\'esercizio da fare.'
                          : 'Tocca gli esercizi nell\'ordine in cui farli.',
                      style: AppTypography.corpo.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          TonalChip(
                            etichetta: 'Tutti',
                            selezionato: _filtro == null,
                            onSelezionato: (_) =>
                                setState(() => _filtro = null),
                          ),
                          for (final c in categorie) ...[
                            const SizedBox(width: AppSpacing.s8),
                            TonalChip(
                              etichetta: c.etichetta,
                              selezionato: _filtro == c,
                              onSelezionato: (_) => setState(() => _filtro = c),
                            ),
                          ],
                        ],
                      ),
                    ),
                    for (final c in CategoriaEsercizio.values)
                      if (perCategoria[c] case final elenco?) ...[
                        const SizedBox(height: AppSpacing.s20),
                        TitoloSezione(c.etichetta, conteggio: elenco.length),
                        AppListPanel(
                          righe: [
                            for (final v in elenco)
                              _RigaScelta(
                                voce: v,
                                posizione: _scelte.indexOf(v.chiave) + 1,
                                onTap: widget.unoSolo
                                    ? (_aggiungo
                                          ? null
                                          : () => _aggiungi(voci, [v.chiave]))
                                    : () => _alterna(v.chiave),
                                onComeSiFa:
                                    v.descrizione == null ||
                                        v.descrizione!.trim().isEmpty
                                    ? null
                                    : () => _comeSiFa(v),
                              ),
                          ],
                        ),
                      ],
                  ],
                ),
              ),
              if (_errore != null) ...[
                ErrorBanner(
                  messaggio: 'Non è stato possibile aggiungere gli esercizi.',
                  suggerimento:
                      'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
                  dettaglioTecnico: _errore,
                ),
                const SizedBox(height: AppSpacing.s12),
              ],
              if (!widget.unoSolo)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.s8),
                    child: PrimaryButton(
                      label: _scelte.isEmpty
                          ? 'Scegli gli esercizi'
                          : _scelte.length == 1
                          ? 'Aggiungi 1 esercizio'
                          : 'Aggiungi ${_scelte.length} esercizi',
                      isLoading: _aggiungo,
                      onPressed: _scelte.isEmpty || _aggiungo
                          ? null
                          : () => _aggiungi(voci, _scelte),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const LoadingSkeletonList(righe: 6),
        error: (errore, _) => ErrorBanner(
          messaggio: 'Non è stato possibile caricare gli esercizi.',
          suggerimento:
              'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
          dettaglioTecnico: messaggioErrore(errore),
        ),
      ),
    );
  }

  /// Gli esercizi attivi del club e quelli pronti non ancora aggiunti
  /// (chiave: id dell'esercizio o del modello), per nome.
  Map<String, _Voce> _voci(List<EsercizioSecco> esercizi) {
    final giaNelClub = {for (final e in esercizi) ?e.modello};
    final voci = <_Voce>[
      for (final e in esercizi)
        if (!e.archiviato)
          (
            chiave: e.id,
            nome: e.nome,
            categoria: e.categoria,
            attrezzo: e.attrezzo,
            aTempo: e.aTempo,
            descrizione: e.descrizione,
            delClub: e,
            pronto: null,
          ),
      for (final m in modelliEsercizi)
        if (!giaNelClub.contains(m.chiave))
          (
            chiave: 'pronto:${m.chiave}',
            nome: m.nome,
            categoria: m.categoria,
            attrezzo: m.attrezzo,
            aTempo: m.aTempo,
            descrizione: m.descrizione,
            delClub: null,
            pronto: m,
          ),
    ]..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return {for (final v in voci) v.chiave: v};
  }
}

class _RigaScelta extends StatelessWidget {
  const _RigaScelta({
    required this.voce,
    required this.posizione,
    required this.onTap,
    required this.onComeSiFa,
  });

  final _Voce voce;

  /// Da 1 in su l'ordine nella seduta, 0 se non scelto.
  final int posizione;
  final VoidCallback? onTap;
  final VoidCallback? onComeSiFa;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final scelto = posizione > 0;
    final dettagli = [
      voce.attrezzo ?? 'Corpo libero',
      if (voce.aTempo) 'a tempo',
    ].join(' · ');
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.altezzaMinimaRiga,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s8,
            AppSpacing.s4,
            AppSpacing.s8,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scelto ? colori.azione : null,
                  border: scelto
                      ? null
                      : Border.all(color: colori.lineaForte, width: 1.5),
                ),
                child: scelto
                    ? Text(
                        '$posizione',
                        style: AppTypography.numerica(AppTypography.corpoForte)
                            .copyWith(color: colori.azioneInk),
                      )
                    : Icon(
                        iconaCategoria(voce.categoria),
                        size: 16,
                        color: colori.testoSecondario,
                      ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      voce.nome,
                      style: AppTypography.corpoForte.copyWith(
                        color: colori.testo,
                      ),
                    ),
                    Text(
                      dettagli,
                      style: AppTypography.piccolo.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                  ],
                ),
              ),
              if (onComeSiFa != null)
                IconButton(
                  tooltip: 'Come si fa',
                  onPressed: onComeSiFa,
                  icon: Icon(Icons.info_outline, color: colori.testoSecondario),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
