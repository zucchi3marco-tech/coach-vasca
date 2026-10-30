import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/condivisione/apri_indirizzo.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../atleti/domain/atleta.dart';
import '../../club/application/current_club_provider.dart';
import '../data/contatti_specialisti_repository.dart';
import '../data/profilo_fisico_repository.dart';
import '../data/specialisti_repository.dart';
import '../domain/chi_mi_puo_aiutare.dart';
import '../domain/misura_fisica.dart';
import '../domain/specialista.dart';

Widget _testo(BuildContext context, String t) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
  child: Text(
    t,
    style: AppTypography.corpo.copyWith(color: context.colori.testoSecondario),
  ),
);

/// «Chi mi può aiutare?», dalla home dell'atleta (profilo fisico, passo
/// C): l'atleta sceglie cosa sente e vede gli specialisti del club
/// adatti, con il messaggio WhatsApp già scritto. Sotto i 18 anni resta
/// chiusa finché lo staff non segna il consenso del genitore. Dal passo
/// D ogni contatto si segna per il responsabile (con il codice
/// dell'atleta); l'assistente non lo legge.
class ChiMiPuoAiutareScreen extends ConsumerWidget {
  const ChiMiPuoAiutareScreen({required this.atleta, this.oggi, super.key});

  final Atleta atleta;

  /// Solo per le prove.
  final DateTime? oggi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adesso = oggi ?? DateTime.now();
    final minorenne = !maggiorenne(atleta.dataNascita, adesso);
    final consensoAsync = minorenne
        ? ref.watch(consensoProfiloFisicoProvider(atleta.id))
        : const AsyncData<DateTime?>(null);
    final consenso = consensoAsync.value;
    final aperto = profiloFisicoAperto(
      dataNascita: atleta.dataNascita,
      conConsenso: consenso != null,
      oggi: adesso,
    );

    return AppScaffold(
      appBar: AppBar(),
      larghezzaMassima: AppLayout.larghezzaMassimaCruscotto,
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s32),
        children: [
          const TestataPagina(
            occhiello: 'Specialisti del club',
            titolo: 'Chi mi può aiutare?',
          ),
          const SizedBox(height: AppSpacing.s24),
          if (minorenne && consensoAsync.isLoading && consenso == null)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.s16),
              child: LoadingSkeletonList(righe: 4),
            )
          else if (!aperto) ...[
            _testo(
              context,
              'Hai meno di 18 anni: per chiedere aiuto agli specialisti del '
              'club serve il consenso di un genitore. Chiedi il modulo al tuo '
              'allenatore: quando lo riporti firmato, questa pagina si apre.',
            ),
            const SizedBox(height: AppSpacing.s16),
            _testo(
              context,
              'Se hai un dolore forte o che non passa, dillo subito ai tuoi '
              'genitori e al tuo allenatore.',
            ),
          ] else ...[
            _testo(
              context,
              'Scegli cosa senti: ti mostriamo lo specialista del club adatto. '
              'È solo un indirizzo, non una diagnosi.',
            ),
            const SizedBox(height: AppSpacing.s24),
            const TitoloSezione('Cosa senti?'),
            AppListPanel(
              righe: [
                for (final p in ProblemaFisico.values)
                  AppListRow(
                    titolo: p.etichetta,
                    sottotitolo: switch (p) {
                      ProblemaFisico.forte => 'Senti il medico',
                      ProblemaFisico.nonLoSo =>
                        'Tutti gli specialisti del club',
                      _ => p.tipo!.etichetta,
                    },
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ProblemaSpecialistiScreen(
                          atleta: atleta,
                          problema: p,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s24),
            _testo(
              context,
              'Quando scrivi a uno specialista o apri il suo sito, il '
              'responsabile del club vede chi l\'ha contattato, quando e per '
              'quale tipo di problema, senza altri dettagli. L\'assistente '
              'non lo legge.',
            ),
          ],
        ],
      ),
    );
  }
}

/// Gli specialisti del club per un problema, con «Scrivi su WhatsApp» (il
/// messaggio già scritto) e «Apri il sito». Per un dolore forte solo
/// «senti il medico».
class ProblemaSpecialistiScreen extends ConsumerWidget {
  const ProblemaSpecialistiScreen({
    required this.atleta,
    required this.problema,
    super.key,
  });

  final Atleta atleta;
  final ProblemaFisico problema;

  void _avviso(BuildContext context, String testo) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(testo)));

  /// Segna il contatto per il responsabile, senza aspettarlo: il
  /// contatto si apre comunque.
  void _registra(
    WidgetRef ref,
    Specialista s,
    CanaleContatto canale,
    String? codice,
  ) => unawaited(
    ref
        .read(contattiSpecialistiRepositoryProvider)
        .registra(
          atleta: atleta,
          specialista: s,
          problema: problema,
          canale: canale,
          codice: codice,
        ),
  );

  Future<void> _scrivi(
    BuildContext context,
    WidgetRef ref,
    Specialista s,
    String? nomeClub,
    String? codice,
  ) async {
    final numero = s.whatsapp!;
    final testo = messaggioSpecialista(
      nomeAtleta: '${atleta.nome} ${atleta.cognome}',
      nomeClub: nomeClub,
      problema: problema,
      codice: codice,
    );
    // Si apre subito, dentro il tocco: dopo un'attesa il browser del
    // telefono bloccherebbe la scheda nuova.
    final aperto = apriIndirizzo(collegamentoWhatsapp(numero, testo));
    _registra(ref, s, CanaleContatto.whatsapp, codice);
    if (aperto) return;
    // Fuori dal browser: il messaggio negli appunti.
    await Clipboard.setData(ClipboardData(text: testo));
    if (context.mounted) {
      _avviso(
        context,
        'Messaggio copiato: scrivilo su WhatsApp al ${mostraWhatsapp(numero)}',
      );
    }
  }

  Future<void> _apriSito(
    BuildContext context,
    WidgetRef ref,
    Specialista s,
    String? codice,
  ) async {
    final sito = s.sito!;
    final aperto = apriIndirizzo(sito);
    _registra(ref, s, CanaleContatto.sito, codice);
    if (aperto) return;
    await Clipboard.setData(ClipboardData(text: sito));
    if (context.mounted) _avviso(context, 'Indirizzo del sito copiato');
  }

  Future<void> _copiaCodice(BuildContext context, String codice) async {
    await Clipboard.setData(ClipboardData(text: codice));
    if (context.mounted) _avviso(context, 'Codice copiato');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nomeClub = ref.watch(clubAtletaProvider(atleta.clubId)).value?.nome;
    final codice = problema.soloMedico
        ? null
        : ref.watch(codiceSpecialistiProvider(atleta.id)).value;
    final elencoAsync = problema.soloMedico
        ? null
        : ref.watch(specialistiProvider(atleta.clubId));

    return AppScaffold(
      appBar: AppBar(),
      larghezzaMassima: AppLayout.larghezzaMassimaCruscotto,
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s32),
        children: [
          TestataPagina(
            occhiello: 'Chi mi può aiutare?',
            titolo: problema.etichetta,
          ),
          const SizedBox(height: AppSpacing.s24),
          if (elencoAsync == null)
            _testo(
              context,
              'Con un dolore forte, che non passa o con la febbre, la persona '
              'giusta è il medico: chiamalo e dillo al tuo allenatore. Se è '
              'un\'emergenza, chiama il 112.',
            )
          else ...[
            _testo(
              context,
              problema == ProblemaFisico.nonLoSo
                  ? 'Se non sai chi fa per te, parlane con il tuo allenatore. '
                        'È solo un indirizzo, non una diagnosi; se il dolore è '
                        'forte o non passa, senti il medico.'
                  : 'È solo un indirizzo, non una diagnosi. Se il dolore è '
                        'forte o non passa, senti il medico.',
            ),
            const SizedBox(height: AppSpacing.s24),
            ...elencoAsync.when(
              data: (elenco) => _specialisti(
                context,
                ref,
                problema.specialisti(elenco),
                nomeClub,
                codice,
              ),
              loading: () => const [
                Padding(
                  padding: EdgeInsets.all(AppSpacing.s16),
                  child: LoadingSkeletonList(righe: 3),
                ),
              ],
              error: (error, _) => [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: ErrorBanner(
                    messaggio:
                        'Non è stato possibile caricare gli specialisti.',
                    suggerimento:
                        'Riprova. Se l\'errore continua, chiudi e riapri '
                        'l\'app.',
                    dettaglioTecnico: messaggioErrore(error),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _specialisti(
    BuildContext context,
    WidgetRef ref,
    List<Specialista> elenco,
    String? nomeClub,
    String? codice,
  ) {
    if (elenco.isEmpty) {
      final tipo = problema.tipo;
      return [
        EmptyState(
          icona: Icons.person_search_outlined,
          titolo: tipo == null
              ? 'Il club non ha ancora specialisti'
              : 'Il club non ha ancora un ${tipo.etichetta.toLowerCase()}',
          descrizione:
              'Parlane con il tuo allenatore: ti dice a chi rivolgerti.',
          azionePrincipale: 'Scegli un\'altra cosa',
          onAzionePrincipale: () => Navigator.of(context).maybePop(),
        ),
      ];
    }
    final tutti = problema == ProblemaFisico.nonLoSo;
    return [
      if (codice != null) ...[
        const TitoloSezione('Il tuo codice'),
        AppListPanel(
          righe: [
            AppListRow(
              leading: const Icon(Icons.badge_outlined),
              titolo: codice,
              sottotitolo: elenco.any((s) => s.sito != null)
                  ? 'È già nel messaggio WhatsApp. Se passi dal sito, dillo '
                        'alla prima visita.'
                  : 'È già nel messaggio WhatsApp: serve al club per sapere '
                        'che sei passato da qui.',
              trailing: const Icon(Icons.copy),
              onTap: () => _copiaCodice(context, codice),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),
      ],
      for (final s in elenco) ...[
        TitoloSezione(s.nome),
        if ([
              if (tutti) s.tipo.etichetta,
              if (s.descrizione case final d? when d.isNotEmpty) d,
            ]
            case final righe when righe.isNotEmpty) ...[
          _testo(context, righe.join('. ')),
          const SizedBox(height: AppSpacing.s12),
        ],
        AppListPanel(
          righe: [
            if (s.whatsapp case final numero?)
              AppListRow(
                leading: const Icon(Icons.chat_outlined),
                titolo: 'Scrivi su WhatsApp',
                sottotitolo:
                    '${mostraWhatsapp(numero)}, il messaggio è già scritto',
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _scrivi(context, ref, s, nomeClub, codice),
              ),
            if (s.sito case final sito?)
              AppListRow(
                leading: const Icon(Icons.language),
                titolo: 'Apri il sito',
                sottotitolo: mostraSito(sito),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _apriSito(context, ref, s, codice),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),
      ],
    ];
  }
}
