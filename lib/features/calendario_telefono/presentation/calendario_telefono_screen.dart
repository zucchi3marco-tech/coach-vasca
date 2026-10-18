import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/condivisione/apri_indirizzo.dart';
import '../../../core/demo/modalita_demo.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../atleti/application/current_atleta_provider.dart';
import '../data/calendario_telefono_repository.dart';
import '../domain/indirizzi_calendario.dart';

/// La pagina che collega le partite e le gare al calendario del telefono:
/// mostra l'indirizzo personale (il codice lo dà il server), i pulsanti per
/// aggiungerlo a iPhone o a Google Calendar e, per i rari casi in cui
/// l'indirizzo è finito in mani sbagliate, "Cambia indirizzo".
class CalendarioTelefonoScreen extends ConsumerStatefulWidget {
  const CalendarioTelefonoScreen({super.key});

  @override
  ConsumerState<CalendarioTelefonoScreen> createState() =>
      _CalendarioTelefonoScreenState();
}

class _CalendarioTelefonoScreenState
    extends ConsumerState<CalendarioTelefonoScreen> {
  bool _cambiando = false;

  String get _urlSupabase =>
      dotenv.isInitialized ? dotenv.env['SUPABASE_URL'] ?? '' : '';

  Future<void> _copia(String indirizzo) async {
    await Clipboard.setData(ClipboardData(text: indirizzo));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Indirizzo copiato')));
  }

  Future<void> _cambiaIndirizzo() async {
    final conferma =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Cambiare indirizzo?'),
            content: const Text(
              'Il vecchio indirizzo smette di funzionare e il calendario '
              'collegato non si aggiorna più: dovrai collegare quello '
              'nuovo. Serve se l\'hai mandato a qualcuno per sbaglio.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Annulla'),
              ),
              PrimaryButton(
                label: 'Cambia',
                expanded: false,
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
            ],
          ),
        ) ==
        true;
    if (!conferma || !mounted) return;
    setState(() => _cambiando = true);
    try {
      await ref.read(codiceCalendarioProvider.notifier).cambia();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Indirizzo cambiato: collega di nuovo il calendario'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Non è stato possibile cambiare l\'indirizzo: '
            '${messaggioErrore(e)}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _cambiando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (modalitaDemo) {
      return AppScaffold(
        appBar: AppBar(),
        body: EmptyState(
          icona: Icons.event_available_outlined,
          titolo: 'Nella demo il calendario non si collega',
          descrizione:
              'Con l\'app vera qui trovi l\'indirizzo da aggiungere al '
              'calendario del telefono.',
          azionePrincipale: 'Torna indietro',
          onAzionePrincipale: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    final codiceAsync = ref.watch(codiceCalendarioProvider);
    final perAtleta = ref.watch(currentAtletaProvider).value != null;

    return AppScaffold(
      // La testata porta il titolo: la barra in alto resta vuota.
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s32),
        children: [
          const TestataPagina(
            occhiello: 'Calendario del telefono',
            titolo: 'Partite nel calendario',
            sottotitolo:
                'Le partite e le gare delle tue squadre nel calendario del '
                'telefono, con l\'ora e il luogo. Gli allenamenti no.',
          ),
          const SizedBox(height: AppSpacing.s28),
          codiceAsync.when(
            loading: () => const LoadingSkeletonList(righe: 4),
            error: (error, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ErrorBanner(
                  messaggio:
                      'Non è stato possibile preparare l\'indirizzo del '
                      'calendario.',
                  suggerimento: 'Controlla la connessione e riprova.',
                  dettaglioTecnico: messaggioErrore(error),
                ),
                const SizedBox(height: AppSpacing.s12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => ref.invalidate(codiceCalendarioProvider),
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('Riprova'),
                  ),
                ),
              ],
            ),
            data: (codice) => _Contenuto(
              https: indirizzoCalendario(_urlSupabase, codice),
              webcal: indirizzoWebcal(_urlSupabase, codice),
              google: indirizzoGoogleCalendar(_urlSupabase, codice),
              perAtleta: perAtleta,
              cambiando: _cambiando,
              onCopia: _copia,
              onCambia: _cambiaIndirizzo,
            ),
          ),
        ],
      ),
    );
  }
}

class _Contenuto extends StatelessWidget {
  const _Contenuto({
    required this.https,
    required this.webcal,
    required this.google,
    required this.perAtleta,
    required this.cambiando,
    required this.onCopia,
    required this.onCambia,
  });

  final String https;
  final String webcal;
  final String google;
  final bool perAtleta;
  final bool cambiando;
  final Future<void> Function(String indirizzo) onCopia;
  final Future<void> Function() onCambia;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TitoloSezione('Collegalo una volta'),
        const _Scheda(
          figli: [
            _Passo(
              'iPhone',
              'Tocca «Aggiungi al calendario», poi «Iscriviti».',
            ),
            _Passo(
              'Android',
              'Tocca «Google Calendar», poi «Aggiungi». Compare sul telefono '
                  'insieme agli altri calendari di Google.',
            ),
            _Passo(
              'Altro calendario',
              'Copia l\'indirizzo e aggiungilo come calendario da indirizzo '
                  '(a volte si chiama «iscrizione»).',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        PrimaryButton(
          label: 'Aggiungi al calendario',
          onPressed: () => apriCollegamento(webcal),
        ),
        const SizedBox(height: AppSpacing.s12),
        SecondaryButton(
          label: 'Google Calendar',
          onPressed: () => apriIndirizzo(google),
        ),
        const SizedBox(height: AppSpacing.s8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => onCopia(https),
            icon: const Icon(Icons.copy_outlined, size: 20),
            label: const Text('Copia l\'indirizzo'),
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Container(
          padding: const EdgeInsets.all(AppSpacing.s12),
          decoration: BoxDecoration(
            color: colori.superficieAlt,
            borderRadius: BorderRadius.circular(AppRadius.controllo),
            border: Border.all(color: colori.linea),
          ),
          child: SelectableText(
            https,
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s24),
        _Scheda(
          figli: [
            const _Nota(
              Icons.sync_outlined,
              'Le partite nuove o spostate arrivano da sole: è il telefono '
              'che decide quando aggiornare, di solito entro qualche ora.',
            ),
            if (perAtleta)
              const _Nota(
                Icons.how_to_reg_outlined,
                'Sulle partite in cui sei convocato c\'è «Convocato».',
              ),
            const _Nota(
              Icons.lock_outline,
              'L\'indirizzo è personale: chi lo ha vede le partite e le '
              'gare delle tue squadre. Non mandarlo ad altri.',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: cambiando ? null : onCambia,
            icon: const Icon(Icons.autorenew, size: 20),
            label: const Text('Cambia indirizzo'),
          ),
        ),
      ],
    );
  }
}

/// Una scheda con più voci una sotto l'altra, spaziate di 12.
class _Scheda extends StatelessWidget {
  const _Scheda({required this.figli});

  final List<Widget> figli;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.paddingPannello),
      decoration: BoxDecoration(
        color: colori.superficie,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        border: Border.all(color: colori.linea),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < figli.length; i++) ...[
            figli[i],
            if (i != figli.length - 1) const SizedBox(height: AppSpacing.s12),
          ],
        ],
      ),
    );
  }
}

/// Un passo del collegamento: l'etichetta in semigrassetto e il testo.
class _Passo extends StatelessWidget {
  const _Passo(this.etichetta, this.testo);

  final String etichetta;
  final String testo;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$etichetta  ',
            style: AppTypography.corpoForte.copyWith(color: colori.testo),
          ),
          TextSpan(
            text: testo,
            style: AppTypography.corpo.copyWith(color: colori.testo),
          ),
        ],
      ),
    );
  }
}

/// Una nota con la sua icona a sinistra.
class _Nota extends StatelessWidget {
  const _Nota(this.icona, this.testo);

  final IconData icona;
  final String testo;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icona, size: 20, color: colori.testoSecondario),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Text(
            testo,
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
        ),
      ],
    );
  }
}
