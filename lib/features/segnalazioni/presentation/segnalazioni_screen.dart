import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../../widgets/tonal_chip.dart';
import '../data/segnalazioni_repository.dart';
import '../domain/segnalazione.dart';
import 'scrivimi_screen.dart';

enum _Filtro { aperte, risolte, tutte }

/// Le segnalazioni di tutti i club, per chi sviluppa WaterTactics (menu ☰,
/// solo per gli amministratori dell'app): prima le aperte. Toccandone una
/// si leggono la schermata e i dettagli, e si risponde.
class SegnalazioniScreen extends ConsumerStatefulWidget {
  const SegnalazioniScreen({super.key});

  @override
  ConsumerState<SegnalazioniScreen> createState() => _SegnalazioniScreenState();
}

class _SegnalazioniScreenState extends ConsumerState<SegnalazioniScreen> {
  _Filtro _filtro = _Filtro.aperte;

  @override
  Widget build(BuildContext context) {
    final tutte = ref.watch(tutteSegnalazioniProvider);
    final elenco = tutte.value ?? const <Segnalazione>[];
    final aperte = elenco.where((s) => !s.risolta).length;
    final risolte = elenco.length - aperte;
    final visibili = [
      for (final s in elenco)
        if (switch (_filtro) {
          _Filtro.aperte => !s.risolta,
          _Filtro.risolte => s.risolta,
          _Filtro.tutte => true,
        })
          s,
    ];

    return AppScaffold(
      appBar: AppBar(),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(tutteSegnalazioniProvider.future),
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.s32),
          children: [
            TestataPagina(
              titolo: 'Segnalazioni',
              sottotitolo: 'Quello che hanno scritto con «Scrivimi».',
              numeri: [
                NumeroTestata(valore: '$aperte', etichetta: 'Aperte'),
                NumeroTestata(valore: '$risolte', etichetta: 'Risolte'),
              ],
            ),
            const SizedBox(height: AppSpacing.s20),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                for (final f in _Filtro.values)
                  TonalChip(
                    etichetta: switch (f) {
                      _Filtro.aperte => 'Aperte',
                      _Filtro.risolte => 'Risolte',
                      _Filtro.tutte => 'Tutte',
                    },
                    selezionato: _filtro == f,
                    onSelezionato: (_) => setState(() => _filtro = f),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s20),
            if (tutte.isLoading && !tutte.hasValue)
              const LoadingSkeletonList(righe: 3)
            else if (tutte.hasError && !tutte.hasValue)
              ErrorBanner(
                messaggio: 'Non riesco a leggere le segnalazioni.',
                suggerimento: 'Controlla la rete e tira giù per riprovare.',
                dettaglioTecnico: messaggioErrore(tutte.error!),
              )
            else if (visibili.isEmpty)
              RiquadroVuoto(switch (_filtro) {
                _Filtro.aperte => 'Nessuna segnalazione aperta.',
                _Filtro.risolte => 'Nessuna segnalazione risolta.',
                _Filtro.tutte => 'Ancora nessuna segnalazione.',
              }, icona: Icons.mark_email_read_outlined)
            else
              for (final s in visibili) ...[
                RigaSegnalazione(
                  segnalazione: s,
                  intestazione: _chi(s),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SegnalazioneScreen(segnalazione: s),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.spazioPannelli),
              ],
          ],
        ),
      ),
    );
  }
}

/// "Marco Rossi, Canottieri Milano".
String _chi(Segnalazione s) => [
  s.autore ?? 'Un allenatore',
  if (s.clubNome != null) s.clubNome!,
].join(', ');

/// Una segnalazione per intero: testo, dove e con cosa, la schermata, e la
/// risposta con lo stato.
class SegnalazioneScreen extends ConsumerStatefulWidget {
  const SegnalazioneScreen({required this.segnalazione, super.key});

  final Segnalazione segnalazione;

  @override
  ConsumerState<SegnalazioneScreen> createState() => _SegnalazioneScreenState();
}

class _SegnalazioneScreenState extends ConsumerState<SegnalazioneScreen> {
  late final _risposta = TextEditingController(
    text: widget.segnalazione.risposta ?? '',
  );
  late bool _risolta = widget.segnalazione.risolta;
  bool _salvo = false;
  Object? _errore;

  @override
  void dispose() {
    _risposta.dispose();
    super.dispose();
  }

  Future<void> _salva() async {
    if (_salvo) return;
    setState(() {
      _salvo = true;
      _errore = null;
    });
    try {
      await ref
          .read(segnalazioniRepositoryProvider)
          .aggiorna(
            widget.segnalazione.id,
            risolta: _risolta,
            risposta: _risposta.text,
          );
      if (!mounted) return;
      ref.invalidate(tutteSegnalazioniProvider);
      final messaggero = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messaggero.showSnackBar(const SnackBar(content: Text('Salvato.')));
    } catch (e) {
      if (mounted) {
        setState(() {
          _salvo = false;
          _errore = e;
        });
      }
    }
  }

  void _apriSchermata(String percorso) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 5,
                child: Center(child: _Schermata(percorso: percorso)),
              ),
            ),
            Positioned(
              top: AppSpacing.s8,
              right: AppSpacing.s8,
              child: IconButton.filledTonal(
                tooltip: 'Chiudi',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final s = widget.segnalazione;
    final schermata = s.schermata;
    final dettagli = <(String, String)>[
      ('Quando', quandoFa(s.creataIl.toLocal())),
      if (s.ruoloLeggibile != null) ('Ruolo', s.ruoloLeggibile!),
      if (s.pagina != null) ('Pagina', s.pagina!),
      ('Versione', s.versione),
      if (s.schermo != null) ('Schermo', s.schermo!),
      if (s.dispositivo != null) ('Telefono o computer', s.dispositivo!),
    ];

    return AppScaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s32),
        children: [
          TestataPagina(
            occhiello: s.clubNome,
            titolo: s.autore ?? 'Segnalazione',
            sottotitolo: s.risolta ? 'Risolta' : 'Aperta',
          ),
          const SizedBox(height: AppSpacing.s28),
          const TitoloSezione('Cosa è successo'),
          SelectableText(
            s.testo,
            style: AppTypography.corpo.copyWith(color: colori.testo),
          ),
          const SizedBox(height: AppSpacing.spazioGruppiForm),
          const TitoloSezione('Dove e con cosa'),
          for (final (etichetta, valore) in dettagli)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    etichetta,
                    style: AppTypography.etichetta.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                  SelectableText(
                    valore,
                    style: AppTypography.piccolo.copyWith(color: colori.testo),
                  ),
                ],
              ),
            ),
          if (schermata != null) ...[
            const SizedBox(height: AppSpacing.spazioGruppiForm),
            const TitoloSezione('La schermata'),
            Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.controllo),
                onTap: () => _apriSchermata(schermata),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.controllo),
                  child: SizedBox(
                    height: 320,
                    child: _Schermata(percorso: schermata),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.spazioGruppiForm),
          const TitoloSezione('Risposta'),
          AppTextField(
            etichetta: 'Cosa rispondi',
            controller: _risposta,
            maxLines: 4,
            keyboardType: TextInputType.multiline,
            aiuto: 'Chi l\'ha scritta la legge sotto la sua segnalazione.',
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _risolta,
            onChanged: _salvo ? null : (v) => setState(() => _risolta = v),
            title: const Text('Risolta'),
          ),
          const SizedBox(height: AppSpacing.s16),
          if (_errore != null) ...[
            ErrorBanner(
              messaggio: 'Non è stato salvato.',
              suggerimento: 'Controlla la rete e riprova.',
              dettaglioTecnico: messaggioErrore(_errore!),
            ),
            const SizedBox(height: AppSpacing.s16),
          ],
          PrimaryButton(
            label: 'Salva',
            icon: Icons.check,
            isLoading: _salvo,
            onPressed: _salvo ? null : _salva,
          ),
        ],
      ),
    );
  }
}

/// La schermata dallo spazio privato delle segnalazioni.
class _Schermata extends ConsumerWidget {
  const _Schermata({required this.percorso});

  final String percorso;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final immagine = ref.watch(schermataSegnalazioneProvider(percorso));
    return immagine.when(
      data: (byte) => Image.memory(
        byte,
        fit: BoxFit.contain,
        semanticLabel: 'La schermata della segnalazione',
      ),
      loading: () => const SizedBox(
        width: 160,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox(
        width: 240,
        child: RiquadroVuoto(
          'La schermata non si apre.',
          icona: Icons.broken_image_outlined,
        ),
      ),
    );
  }
}
