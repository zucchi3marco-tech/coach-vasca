import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/giorni.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../secco/application/secco_providers.dart';
import '../application/allenamenti_providers.dart';
import '../domain/allenamento.dart';
import '../domain/modifica_allenamento.dart';
import '../domain/serie.dart';
import '../domain/testo_allenamento.dart';
import 'banner_modifica.dart';
import 'per_chi_serie.dart';

/// Sotto questa larghezza "Prima" e "Ora" vanno una sopra l'altra.
const _larghezzaAffiancati = 720.0;

/// "Cosa è cambiato": un allenamento cambiato da un altro allenatore,
/// com'era prima e com'è adesso. I dati (titolo, data, note) in una
/// lista "Prima → Ora"; le serie (o gli esercizi, a secco) riga per riga,
/// con le righe tolte segnate in "Prima" e quelle aggiunte in "Ora".
class ConfrontoModificaScreen extends ConsumerWidget {
  const ConfrontoModificaScreen({
    required this.modifica,
    required this.allenamento,
    super.key,
  });

  final ModificaAllenamento modifica;

  /// L'allenamento com'era quando si è aperta la pagina; adesso si legge
  /// dall'elenco, se c'è.
  final Allenamento allenamento;

  Future<void> _visto(BuildContext context, WidgetRef ref) async {
    final navigatore = Navigator.of(context);
    final fatto = await segnaModificaVista(context, ref, modifica);
    if (fatto) navigatore.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a =
        ref
            .watch(allenamentiListProvider(allenamento.clubId))
            .value
            ?.where((x) => x.id == allenamento.id)
            .firstOrNull ??
        allenamento;

    return AppScaffold(
      larghezzaMassima: AppLayout.larghezzaMassimaCruscotto,
      // La testata porta il titolo: la barra in alto resta vuota.
      appBar: AppBar(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s8,
            AppSpacing.s16,
            AppSpacing.s16,
          ),
          child: PrimaryButton(
            label: 'Visto',
            icon: Icons.check,
            onPressed: () => _visto(context, ref),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s32),
        children: [
          TestataPagina(
            occhiello: a.titoloMostrato,
            titolo: 'Cosa è cambiato',
            sottotitolo:
                'Modificato da ${modifica.autoriTesto} · '
                '${quandoFa(modifica.ultimaAt)}',
          ),
          const SizedBox(height: AppSpacing.s20),
          if (modifica.prima == null)
            const RiquadroVuoto(
              'Questo allenamento è stato aggiunto da un altro: non c\'è un '
              '«prima» da confrontare.',
            )
          else ...[
            _CambiDati(prima: modifica.allenamentoDiPrima, ora: a),
            if (a.secco)
              _ConfrontoSecco(modifica: modifica, allenamento: a)
            else
              _ConfrontoSerie(modifica: modifica, allenamento: a),
          ],
        ],
      ),
    );
  }
}

/// Un campo che è cambiato: com'era e com'è.
class CambioCampo {
  const CambioCampo(this.etichetta, this.prima, this.ora);

  final String etichetta;
  final String prima;
  final String ora;
}

String _oVuoto(String? testo) =>
    testo == null || testo.trim().isEmpty ? '(vuoto)' : testo.trim();

/// Titolo, data e note che non sono più come prima.
List<CambioCampo> cambiDeiDati(Map<String, dynamic> prima, Allenamento ora) {
  final cambi = <CambioCampo>[];
  final titoloPrima = (prima['titolo'] as String?)?.trim() ?? '';
  final titoloOra = ora.titolo?.trim() ?? '';
  if (prima.containsKey('titolo') && titoloPrima != titoloOra) {
    cambi.add(CambioCampo('Titolo', _oVuoto(titoloPrima), _oVuoto(titoloOra)));
  }
  final dataPrima = prima['data'] is String
      ? DateTime.tryParse(prima['data'] as String)
      : null;
  if (dataPrima != null && giorniTra(dataPrima, ora.data) != 0) {
    cambi.add(CambioCampo('Data', dataEstesa(dataPrima), dataEstesa(ora.data)));
  }
  final notePrima = (prima['note'] as String?)?.trim() ?? '';
  final noteOra = ora.note?.trim() ?? '';
  if (prima.containsKey('note') && notePrima != noteOra) {
    cambi.add(CambioCampo('Note', _oVuoto(notePrima), _oVuoto(noteOra)));
  }
  return cambi;
}

class _CambiDati extends StatelessWidget {
  const _CambiDati({required this.prima, required this.ora});

  final Map<String, dynamic> prima;
  final Allenamento ora;

  @override
  Widget build(BuildContext context) {
    final cambi = cambiDeiDati(prima, ora);
    if (cambi.isEmpty) return const SizedBox.shrink();
    final colori = context.colori;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TitoloSezione('Dati'),
          Container(
            decoration: BoxDecoration(
              color: colori.superficie,
              borderRadius: BorderRadius.circular(AppRadius.pannello),
              border: Border.all(color: colori.linea),
            ),
            child: Column(
              children: [
                for (var i = 0; i < cambi.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.paddingPannello),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cambi[i].etichetta,
                          style: AppTypography.etichetta.copyWith(
                            color: colori.testoSecondario,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        _Valore(
                          'Prima',
                          cambi[i].prima,
                          sfondo: colori.rossoTenue,
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        _Valore('Ora', cambi[i].ora, sfondo: colori.okTenue),
                      ],
                    ),
                  ),
                  if (i != cambi.length - 1)
                    Divider(height: 1, color: colori.linea),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Valore extends StatelessWidget {
  const _Valore(this.etichetta, this.valore, {required this.sfondo});

  final String etichetta;
  final String valore;
  final Color sfondo;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: sfondo,
        borderRadius: BorderRadius.circular(AppRadius.controllo),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              etichetta,
              style: AppTypography.etichetta.copyWith(
                color: colori.testoSecondario,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valore,
              style: AppTypography.corpo.copyWith(color: colori.testo),
            ),
          ),
        ],
      ),
    );
  }
}

/// Un allenamento in acqua: le serie com'erano, scritte come sul foglio
/// (`testoDaSerie`), e come sono ora.
class _ConfrontoSerie extends ConsumerWidget {
  const _ConfrontoSerie({required this.modifica, required this.allenamento});

  final ModificaAllenamento modifica;
  final Allenamento allenamento;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serieAsync = ref.watch(serieListProvider(allenamento.id));
    final serieOra = serieAsync.value;
    if (serieOra == null) {
      if (serieAsync.hasError) {
        return ErrorBanner(
          messaggio: 'Non è stato possibile leggere le serie.',
          dettaglioTecnico: messaggioErrore(serieAsync.error!),
        );
      }
      return const LoadingSkeletonList(righe: 3);
    }
    final serieDiPrima = modifica.serieDiPrima();
    final tutti =
        ref
            .watch(
              atletiListProvider((
                clubId: allenamento.clubId,
                includeInactive: true,
              )),
            )
            .value ??
        const [];
    // Gli stessi atleti per i due testi, così un nome si scrive uguale in
    // "Prima" e in "Ora" e non compare come differenza.
    final atleti = atletiDellAllenamento(
      tutti,
      gruppoId: allenamento.gruppoId,
      serie: [...serieDiPrima, ...serieOra],
    );
    String testo(List<Serie> serie) => testoDaSerie(serie, atleti: atleti);
    return _ConfrontoRighe(
      titolo: 'Serie',
      righe: confrontaRighe(
        testo(serieDiPrima).split('\n'),
        testo(serieOra).split('\n'),
      ),
    );
  }
}

/// Una seduta a secco: gli esercizi com'erano e come sono ora, una riga
/// ciascuno ("Squat 3×12 60 kg").
class _ConfrontoSecco extends ConsumerWidget {
  const _ConfrontoSecco({required this.modifica, required this.allenamento});

  final ModificaAllenamento modifica;
  final Allenamento allenamento;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final righeAsync = ref.watch(eserciziSedutaProvider(allenamento.id));
    final righeOra = righeAsync.value;
    if (righeOra == null) {
      if (righeAsync.hasError) {
        return ErrorBanner(
          messaggio: 'Non è stato possibile leggere gli esercizi.',
          dettaglioTecnico: messaggioErrore(righeAsync.error!),
        );
      }
      return const LoadingSkeletonList(righe: 3);
    }
    final nomi = <String, String>{
      for (final e
          in ref.watch(eserciziSeccoProvider(allenamento.clubId)).value ??
              const [])
        e.id: e.nome,
    };
    return _ConfrontoRighe(
      titolo: 'Esercizi',
      righe: confrontaRighe(
        righeSecco(modifica.eserciziDiPrima(), nomi),
        righeSecco(righeOra, nomi),
      ),
    );
  }
}

/// "Prima" e "Ora" fianco a fianco su schermo largo, uno sopra l'altro su
/// telefono. Le righe tolte sono segnate in "Prima", quelle aggiunte in
/// "Ora".
class _ConfrontoRighe extends StatelessWidget {
  const _ConfrontoRighe({required this.titolo, required this.righe});

  final String titolo;
  final List<RigaConfronto> righe;

  @override
  Widget build(BuildContext context) {
    final prima = [
      for (final r in righe)
        if (r.stato != StatoRiga.aggiunta) r,
    ];
    final ora = [
      for (final r in righe)
        if (r.stato != StatoRiga.tolta) r,
    ];
    final identico = righe.every((r) => r.stato == StatoRiga.uguale);
    final colori = context.colori;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitoloSezione(titolo),
        if (identico)
          RiquadroVuoto(
            titolo == 'Serie'
                ? 'Le serie non sono cambiate.'
                : 'Gli esercizi non sono cambiati.',
          )
        else
          LayoutBuilder(
            builder: (context, vincoli) {
              final pannelloPrima = _PannelloRighe(
                titolo: 'Prima',
                righe: prima,
                colore: colori.rosso,
                sfondo: colori.rossoTenue,
              );
              final pannelloOra = _PannelloRighe(
                titolo: 'Ora',
                righe: ora,
                colore: colori.ok,
                sfondo: colori.okTenue,
              );
              if (vincoli.maxWidth >= _larghezzaAffiancati) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: pannelloPrima),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(child: pannelloOra),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  pannelloPrima,
                  const SizedBox(height: AppSpacing.s12),
                  pannelloOra,
                ],
              );
            },
          ),
      ],
    );
  }
}

class _PannelloRighe extends StatelessWidget {
  const _PannelloRighe({
    required this.titolo,
    required this.righe,
    required this.colore,
    required this.sfondo,
  });

  final String titolo;
  final List<RigaConfronto> righe;

  /// Il colore del segno (le righe tolte in "Prima", aggiunte in "Ora").
  final Color colore;
  final Color sfondo;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final evidenziata = titolo == 'Prima'
        ? StatoRiga.tolta
        : StatoRiga.aggiunta;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
      decoration: BoxDecoration(
        color: colori.superficie,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        border: Border.all(color: colori.linea),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.paddingPannello,
              0,
              AppSpacing.paddingPannello,
              AppSpacing.s8,
            ),
            child: Text(
              titolo,
              style: AppTypography.corpoForte.copyWith(color: colori.testo),
            ),
          ),
          if (righe.isEmpty || righe.every((r) => r.testo.trim().isEmpty))
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.paddingPannello,
              ),
              child: Text(
                'Niente',
                style: AppTypography.piccolo.copyWith(color: colori.testoTenue),
              ),
            )
          else
            for (final riga in righe)
              if (riga.testo.trim().isEmpty)
                const SizedBox(height: AppSpacing.s8)
              else
                Container(
                  color: riga.stato == evidenziata ? sfondo : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.paddingPannello,
                    vertical: 3,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 16,
                        child: Text(
                          riga.stato == StatoRiga.tolta
                              ? '−'
                              : riga.stato == StatoRiga.aggiunta
                              ? '+'
                              : '',
                          style: AppTypography.corpoForte.copyWith(
                            color: colore,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          riga.testo,
                          style: AppTypography.corpo.copyWith(
                            color: colori.testo,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
