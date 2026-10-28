import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/condivisione/apri_indirizzo.dart';
import '../../../core/condivisione/condividi_testo.dart';
import '../../../core/demo/modalita_demo.dart';
import '../../../core/utils/date_italiane.dart';
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
import '../../club/application/current_club_provider.dart';
import '../data/calendario_telefono_repository.dart';
import '../domain/indirizzi_calendario.dart';

/// La pagina che collega le partite al calendario del telefono:
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

  /// Il foglio "Condividi" del telefono, per mandarsi l'indirizzo sul
  /// computer; dove non c'è, l'indirizzo si copia.
  Future<void> _condividi(String indirizzo) async {
    if (await condividiTesto(indirizzo)) return;
    await _copia(indirizzo);
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
    final nomeClub = ref.watch(currentClubProvider).value?.nome;

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
                'Le partite delle tue squadre nel calendario del telefono, '
                'con l\'ora e il luogo. Gli allenamenti no.',
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
              nomeCalendario: nomeClub == null
                  ? 'Partite'
                  : 'Partite · $nomeClub',
              perAtleta: perAtleta,
              cambiando: _cambiando,
              onCopia: _copia,
              onCondividi: _condividi,
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
    required this.nomeCalendario,
    required this.perAtleta,
    required this.cambiando,
    required this.onCopia,
    required this.onCondividi,
    required this.onCambia,
  });

  final String https;
  final String webcal;
  final String google;

  /// Come il calendario si chiama nel telefono ("Partite · Canottieri
  /// Milano", il nome che gli dà la funzione `calendario`).
  final String nomeCalendario;
  final bool perAtleta;
  final bool cambiando;
  final Future<void> Function(String indirizzo) onCopia;
  final Future<void> Function(String indirizzo) onCondividi;
  final Future<void> Function() onCambia;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StatoCollegamento(),
        const SizedBox(height: AppSpacing.s24),
        const TitoloSezione('Collegalo una volta'),
        const _Scheda(
          figli: [
            _Passo(
              'iPhone',
              'Tocca «Aggiungi al calendario», poi «Iscriviti».',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        PrimaryButton(
          label: 'Aggiungi al calendario',
          onPressed: () => apriCollegamento(webcal),
        ),
        const SizedBox(height: AppSpacing.s24),
        _Scheda(
          figli: [
            const _Passo(
              'Android, con Google Calendar',
              'Dal telefono Google non aggiunge un calendario da un '
                  'indirizzo: serve un computer, una volta sola.',
            ),
            const _Passo(
              '1.',
              'Tocca «Condividi l\'indirizzo» e mandalo a te stesso, per '
                  'email o su WhatsApp.',
            ),
            const _Passo(
              '2.',
              'Dal computer apri calendar.google.com con lo stesso account '
                  'Google del telefono. Accanto ad «Altri calendari» tocca '
                  '«+», poi «Da URL»: incolla l\'indirizzo e tocca «Aggiungi '
                  'calendario». Dal computer basta anche aprire «Apri in '
                  'Google Calendar».',
            ),
            _Passo(
              '3.',
              'Sul telefono, nell\'app Google Calendar: ☰, «Impostazioni», '
                  'tocca «$nomeCalendario» e accendi «Sincronizzazione».',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        SecondaryButton(
          label: 'Condividi l\'indirizzo',
          icon: Icons.share_outlined,
          onPressed: () => onCondividi(https),
        ),
        const SizedBox(height: AppSpacing.s8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => apriIndirizzo(google),
            icon: const Icon(Icons.open_in_new, size: 20),
            label: const Text('Apri in Google Calendar (dal computer)'),
          ),
        ),
        const SizedBox(height: AppSpacing.s24),
        const _Scheda(
          figli: [
            _Passo(
              'Altro calendario',
              'Copia l\'indirizzo e aggiungilo come calendario da indirizzo '
                  '(a volte si chiama «iscrizione»).',
            ),
          ],
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
              'Le partite nuove o spostate arrivano da sole, ma è il '
              'calendario che decide quando rileggerle: Google ogni qualche '
              'ora, a volte fino a un giorno; iPhone di solito più spesso.',
            ),
            if (perAtleta)
              const _Nota(
                Icons.how_to_reg_outlined,
                'Sulle partite in cui sei convocato c\'è «Convocato».',
              ),
            const _Nota(
              Icons.lock_outline,
              'L\'indirizzo è personale: chi lo ha vede le partite delle '
              'tue squadre. Non mandarlo ad altri.',
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

/// Se il collegamento è riuscito: l'ultima volta che un calendario ha letto
/// l'indirizzo, e da quale app. Senza letture il collegamento non è finito
/// (di solito su Android, dove dal telefono Google non lo aggiunge).
class _StatoCollegamento extends ConsumerWidget {
  const _StatoCollegamento();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    final lettura = ref.watch(letturaCalendarioProvider);
    if (lettura.isLoading && !lettura.hasValue) {
      return const LoadingSkeletonList(righe: 1);
    }
    // Senza rete non si sa: meglio non dire niente che dire il falso.
    if (lettura.hasError && !lettura.hasValue) return const SizedBox.shrink();
    final ultima = lettura.value;
    final collegato = ultima != null;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.paddingPannello),
      decoration: BoxDecoration(
        color: collegato ? colori.okTenue : colori.attenzioneTenue,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        border: Border.all(color: collegato ? colori.ok : colori.attenzione),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                collegato ? Icons.check_circle_outline : Icons.info_outline,
                size: 22,
                color: collegato ? colori.ok : colori.attenzione,
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Text(
                  collegato
                      ? 'Collegato: l\'ha letto ${ultima.app} '
                            '${quandoFa(ultima.quando)}.'
                      : 'Nessun calendario l\'ha ancora letto: il '
                            'collegamento non è finito. Segui i passi qui '
                            'sotto, poi torna qui.',
                  style: AppTypography.corpo.copyWith(color: colori.testo),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: lettura.isLoading
                  ? null
                  : () => ref.invalidate(letturaCalendarioProvider),
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Controlla di nuovo'),
            ),
          ),
        ],
      ),
    );
  }
}
