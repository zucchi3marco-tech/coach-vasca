import 'package:flutter/material.dart';
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
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/riquadri.dart';
import '../../../widgets/scheda_elenco.dart';
import '../../../widgets/section_header.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/data/atleti_repository.dart';
import '../../atleti/domain/atleta.dart';
import '../../atleti/domain/categoria_fin.dart';
import '../application/gruppi_providers.dart';

/// I cambi di categoria della stagione [annoStagione] per il club; null
/// finché atleti e squadre non sono arrivati.
List<CambioCategoria>? _cambi(WidgetRef ref, String clubId, int annoStagione) {
  final atleti = ref
      .watch(atletiListProvider((clubId: clubId, includeInactive: false)))
      .value;
  final squadre = ref.watch(gruppiListProvider(clubId)).value;
  if (atleti == null || squadre == null) return null;
  return cambiDiCategoria(
    atleti: atleti,
    squadre: squadre,
    annoStagione: annoStagione,
  );
}

String _atleti(int n) => n == 1 ? '1 atleta' : '$n atleti';

/// In «Squadre» a settembre e ottobre, quando qualcuno sale di categoria:
/// un tocco apre [CambioCategoriaScreen]. Altrimenti non occupa spazio.
class RiquadroCambioCategoria extends ConsumerWidget {
  const RiquadroCambioCategoria({required this.clubId, this.oggi, super.key});

  final String clubId;

  /// Per le prove; di solito oggi.
  final DateTime? oggi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final giorno = oggi ?? DateTime.now();
    if (!inizioStagioneSportiva(giorno)) return const SizedBox.shrink();
    final anno = annoStagioneSportiva(giorno);
    final cambi = _cambi(ref, clubId, anno);
    if (cambi == null || cambi.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      child: SchedaElenco(
        leading: const IconaRiquadro(Icons.upgrade, dimensione: 44),
        titolo: 'Chi cambia categoria',
        sottotitolo:
            'Nel ${etichettaStagioneSportiva(anno)} ${cambi.length == 1 ? 'sale' : 'salgono'} '
            'di categoria ${_atleti(cambi.length)}',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                CambioCategoriaScreen(clubId: clubId, annoStagione: anno),
          ),
        ),
      ),
    );
  }
}

/// L'elenco di chi sale di categoria nella stagione [annoStagione], con la
/// squadra proposta (quella con il nome della categoria nuova). Si toglie
/// la spunta a chi resta, poi «Sposta». Le squadre restano una scelta
/// dell'allenatore: senza conferma non cambia niente.
class CambioCategoriaScreen extends ConsumerStatefulWidget {
  const CambioCategoriaScreen({
    required this.clubId,
    required this.annoStagione,
    super.key,
  });

  final String clubId;
  final int annoStagione;

  @override
  ConsumerState<CambioCategoriaScreen> createState() =>
      _CambioCategoriaScreenState();
}

class _CambioCategoriaScreenState extends ConsumerState<CambioCategoriaScreen> {
  /// Chi resta dov'è (spunta tolta).
  final _restano = <String>{};

  /// La squadra scelta a mano al posto di quella proposta.
  final _scelte = <String, String>{};

  bool _inCorso = false;
  String? _errore;

  String? _squadra(CambioCategoria c) =>
      _scelte[c.atleta.id] ?? c.squadraProposta?.id;

  bool _spostato(CambioCategoria c) =>
      !_restano.contains(c.atleta.id) && _squadra(c) != null;

  Future<void> _sposta(List<CambioCategoria> cambi) async {
    final daSpostare = [
      for (final c in cambi)
        if (_spostato(c)) (atleta: c.atleta, squadra: _squadra(c)!),
    ];
    setState(() {
      _inCorso = true;
      _errore = null;
    });
    final repository = ref.read(atletiRepositoryProvider);
    var fatti = 0;
    final nonFatti = <String>[];
    for (final (:atleta, :squadra) in daSpostare) {
      try {
        await _cambiaSquadra(repository, atleta, squadra);
        fatti++;
      } catch (e) {
        nonFatti.add('${atleta.nomeCompleto}: ${messaggioErrore(e)}');
      }
    }
    if (!mounted) return;
    setState(() => _inCorso = false);
    if (nonFatti.isNotEmpty) {
      setState(
        () => _errore =
            '${fatti == 0 ? 'Nessuno spostato' : 'Spostati ${_atleti(fatti)}'}, '
            'non spostati:\n${nonFatti.join('\n')}',
      );
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Spostati ${_atleti(fatti)}.')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final cambi = _cambi(ref, widget.clubId, widget.annoStagione);
    final squadre = [...?ref.watch(gruppiListProvider(widget.clubId)).value]
      ..sort((x, y) => x.ordine.compareTo(y.ordine));
    final nomeSquadra = {for (final s in squadre) s.id: s.nome};
    final stagione = etichettaStagioneSportiva(widget.annoStagione);

    Widget corpo;
    if (cambi == null) {
      corpo = const LoadingSkeletonList(righe: 4);
    } else if (cambi.isEmpty) {
      corpo = EmptyState(
        icona: Icons.check_circle_outline,
        titolo: 'Nessuno cambia categoria',
        descrizione:
            'Nel $stagione chi sale di categoria è già nella squadra della '
            'categoria nuova.',
        azionePrincipale: 'Ho capito',
        onAzionePrincipale: () => Navigator.of(context).pop(),
      );
    } else {
      final categorie = {for (final c in cambi) c.a}.toList();
      final daSpostare = cambi.where(_spostato).length;
      corpo = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nel $stagione ${cambi.length == 1 ? 'sale' : 'salgono'} di '
            'categoria ${_atleti(cambi.length)}. Per ognuno c\'è la squadra '
            'della categoria nuova: togli la spunta a chi resta dov\'è.',
            style: AppTypography.corpo.copyWith(color: colori.testo),
          ),
          const SizedBox(height: AppSpacing.s16),
          for (final categoria in categorie) ...[
            TitoloSezione(
              'Negli $categoria',
              conteggio: cambi.where((c) => c.a == categoria).length,
            ),
            AppListPanel(
              righe: [
                for (final c in cambi.where((c) => c.a == categoria))
                  AppListRow(
                    leading: Checkbox(
                      value: _spostato(c),
                      onChanged: _squadra(c) == null || _inCorso
                          ? null
                          : (si) => setState(
                              () => si == true
                                  ? _restano.remove(c.atleta.id)
                                  : _restano.add(c.atleta.id),
                            ),
                    ),
                    titolo: c.atleta.nomeCompleto,
                    sottotitolo:
                        'classe ${c.atleta.dataNascita.year} · '
                        '${nomeSquadra[c.atleta.gruppoId] == null ? 'senza squadra' : 'ora in ${nomeSquadra[c.atleta.gruppoId]}'}',
                    trailing: DropdownButton<String>(
                      value: _squadra(c),
                      hint: const Text('Scegli'),
                      underline: const SizedBox.shrink(),
                      onChanged: _inCorso
                          ? null
                          : (id) => setState(() {
                              if (id == null) return;
                              _scelte[c.atleta.id] = id;
                              _restano.remove(c.atleta.id);
                            }),
                      items: [
                        for (final s in squadre)
                          DropdownMenuItem(value: s.id, child: Text(s.nome)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
          ],
          if (_errore != null) ...[
            ErrorBanner(messaggio: _errore!),
            const SizedBox(height: AppSpacing.s16),
          ],
          PrimaryButton(
            label: daSpostare == 0 ? 'Sposta' : 'Sposta ${_atleti(daSpostare)}',
            isLoading: _inCorso,
            onPressed: daSpostare == 0 || _inCorso
                ? null
                : () => _sposta(cambi),
          ),
        ],
      );
    }

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(title: const Text('Chi cambia categoria')),
      body: corpo,
    );
  }
}

/// Mette [atleta] nella squadra [squadraId], lasciando tutto il resto com'è.
/// Se si allenava già con quella squadra in giorni fissi, i giorni fissi
/// non servono più.
Future<void> _cambiaSquadra(
  AtletiRepository repository,
  Atleta atleta,
  String squadraId,
) async {
  if (atleta.gruppoId == squadraId) return;
  final eraLAltra = atleta.altroGruppoId == squadraId;
  await repository.updateAtleta(
    originale: atleta,
    nome: atleta.nome,
    cognome: atleta.cognome,
    dataNascita: atleta.dataNascita,
    sesso: atleta.sesso,
    gruppoId: squadraId,
    emailGenitore: atleta.emailGenitore,
    telefonoGenitore: atleta.telefonoGenitore,
    consensoPrivacyFirmato: atleta.consensoPrivacyFirmato,
    consensoPrivacyData: atleta.consensoPrivacyData,
    note: atleta.note,
    numeroTesseraFin: atleta.numeroTesseraFin,
    visitaMedicaScadenza: atleta.visitaMedicaScadenza,
    ruolo: atleta.ruolo,
    altroGruppoId: eraLAltra ? null : atleta.altroGruppoId,
    giorniAltroGruppo: eraLAltra ? const [] : atleta.giorniAltroGruppo,
  );
}
