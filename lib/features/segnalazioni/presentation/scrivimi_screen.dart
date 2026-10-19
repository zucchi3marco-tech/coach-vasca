import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/modalita_demo.dart';
import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../data/segnalazioni_repository.dart';
import '../domain/segnalazione.dart';

/// Lungo al massimo quanto il database accetta.
const lunghezzaMassimaSegnalazione = 4000;

/// «Scrivimi» (menu ☰, per allenatori e assistenti): racconta cosa non va
/// e lo manda a chi sviluppa WaterTactics, con la schermata dove si era e
/// quello che serve per ritrovare il problema ([contesto], preparato da
/// chi apre la pagina prima di aprirla). Sotto, le proprie segnalazioni
/// con lo stato e la risposta.
class ScrivimiScreen extends ConsumerStatefulWidget {
  const ScrivimiScreen({
    required this.clubId,
    required this.contesto,
    super.key,
  });

  final String clubId;
  final ContestoSegnalazione contesto;

  @override
  ConsumerState<ScrivimiScreen> createState() => _ScrivimiScreenState();
}

class _ScrivimiScreenState extends ConsumerState<ScrivimiScreen> {
  final _chiaveForm = GlobalKey<FormState>();
  final _testo = TextEditingController();
  late bool _conSchermata = widget.contesto.schermata != null;
  bool _invio = false;
  Object? _errore;

  @override
  void dispose() {
    _testo.dispose();
    super.dispose();
  }

  Future<void> _invia() async {
    if (_invio || !(_chiaveForm.currentState?.validate() ?? false)) return;
    setState(() {
      _invio = true;
      _errore = null;
    });
    final c = widget.contesto;
    try {
      await ref
          .read(segnalazioniRepositoryProvider)
          .invia(
            clubId: widget.clubId,
            testo: _testo.text,
            contesto: ContestoSegnalazione(
              versione: c.versione,
              pagina: c.pagina,
              dispositivo: c.dispositivo,
              schermo: c.schermo,
              schermata: _conSchermata ? c.schermata : null,
            ),
          );
      if (!mounted) return;
      ref.invalidate(mieSegnalazioniProvider);
      final messaggero = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messaggero.showSnackBar(
        const SnackBar(content: Text('Segnalazione inviata. Grazie!')),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _invio = false;
          _errore = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (dotenv.isInitialized && modalitaDemo) {
      return AppScaffold(
        appBar: AppBar(),
        body: EmptyState(
          icona: Icons.mark_email_unread_outlined,
          titolo: 'Nella demo le segnalazioni non partono',
          descrizione:
              'Con l\'app vera da qui racconti cosa non va, con la schermata '
              'dove eri.',
          azionePrincipale: 'Torna indietro',
          onAzionePrincipale: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    final colori = context.colori;
    final c = widget.contesto;
    final schermata = c.schermata;
    final allegati = [
      c.versione,
      if (c.pagina != null) 'Pagina: ${c.pagina}',
      if (c.schermo != null) 'Schermo: ${c.schermo}',
      if (c.dispositivo != null) 'Telefono o computer: ${c.dispositivo}',
    ];

    return AppScaffold(
      // La testata porta il titolo: la barra in alto resta vuota.
      appBar: AppBar(),
      body: Form(
        key: _chiaveForm,
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.s32),
          children: [
            const TestataPagina(
              titolo: 'Scrivimi',
              sottotitolo:
                  'Cosa non va, o cosa ti servirebbe: arriva a chi sviluppa '
                  'WaterTactics.',
            ),
            const SizedBox(height: AppSpacing.s28),
            const TitoloSezione('Cosa è successo?'),
            AppTextField(
              etichetta: 'Racconta',
              controller: _testo,
              maxLines: 6,
              keyboardType: TextInputType.multiline,
              aiuto: 'Cosa stavi facendo, cosa è successo, cosa ti aspettavi.',
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'Scrivi cosa è successo';
                if (t.length > lunghezzaMassimaSegnalazione) {
                  return 'Al massimo $lunghezzaMassimaSegnalazione lettere';
                }
                return null;
              },
            ),
            if (schermata != null) ...[
              const SizedBox(height: AppSpacing.spazioGruppiForm),
              const TitoloSezione('La schermata'),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colori.superficie,
                  borderRadius: BorderRadius.circular(AppRadius.pannello),
                  border: Border.all(color: colori.linea),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.paddingPannello),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: AnimatedOpacity(
                          opacity: _conSchermata ? 1 : 0.3,
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : AppMotion.transizione,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppRadius.controllo,
                            ),
                            child: Image.memory(
                              schermata,
                              height: 220,
                              fit: BoxFit.contain,
                              semanticLabel: 'La schermata dove eri',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _conSchermata,
                        onChanged: _invio
                            ? null
                            : (v) => setState(() => _conSchermata = v),
                        title: const Text('Allega la schermata'),
                        subtitle: const Text(
                          'Può mostrare nomi e dati degli atleti: toglila se '
                          'non serve.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.spazioGruppiForm),
            const TitoloSezione('Si allegano anche'),
            for (final riga in allegati)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                child: Text(
                  riga,
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.s24),
            if (_errore != null) ...[
              ErrorBanner(
                messaggio: 'La segnalazione non è partita.',
                suggerimento:
                    'Controlla la rete e riprova: il testo resta qui.',
                dettaglioTecnico: messaggioErrore(_errore!),
              ),
              const SizedBox(height: AppSpacing.s16),
            ],
            PrimaryButton(
              label: 'Invia',
              icon: Icons.send_outlined,
              isLoading: _invio,
              onPressed: _invio ? null : _invia,
            ),
            const SizedBox(height: AppSpacing.s40),
            const _LeMieSegnalazioni(),
          ],
        ),
      ),
    );
  }
}

/// Le segnalazioni già mandate, con lo stato e la risposta.
class _LeMieSegnalazioni extends ConsumerWidget {
  const _LeMieSegnalazioni();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mie = ref.watch(mieSegnalazioniProvider);
    final elenco = mie.value ?? const <Segnalazione>[];
    if (mie.hasError) {
      return const RiquadroVuoto(
        'Le tue segnalazioni si vedono quando c\'è rete.',
        icona: Icons.cloud_off_outlined,
      );
    }
    if (elenco.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitoloSezione('Le tue segnalazioni', conteggio: elenco.length),
        for (final s in elenco) ...[
          RigaSegnalazione(segnalazione: s, conRisposta: true),
          const SizedBox(height: AppSpacing.spazioPannelli),
        ],
      ],
    );
  }
}

/// Una segnalazione in un elenco: quando, lo stato, il testo e, per chi
/// l'ha scritta, la risposta.
class RigaSegnalazione extends StatelessWidget {
  const RigaSegnalazione({
    required this.segnalazione,
    this.intestazione,
    this.conRisposta = false,
    this.onTap,
    super.key,
  });

  final Segnalazione segnalazione;

  /// Al posto di "quando": per chi legge, anche chi l'ha scritta.
  final String? intestazione;
  final bool conRisposta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final s = segnalazione;
    final risposta = s.risposta;
    final quando = quandoFa(s.creataIl.toLocal());
    return Material(
      color: colori.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        side: BorderSide(color: colori.linea),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.paddingPannello),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      intestazione == null ? quando : '$intestazione · $quando',
                      style: AppTypography.etichetta.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  PastigliaStato(risolta: s.risolta),
                ],
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                s.testo,
                maxLines: conRisposta ? null : 3,
                overflow: conRisposta ? null : TextOverflow.ellipsis,
                style: AppTypography.corpo.copyWith(color: colori.testo),
              ),
              if (conRisposta && risposta != null) ...[
                const SizedBox(height: AppSpacing.s12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colori.azioneTenue,
                    borderRadius: BorderRadius.circular(AppRadius.controllo),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Risposta',
                          style: AppTypography.etichetta.copyWith(
                            color: colori.azione,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          risposta,
                          style: AppTypography.corpo.copyWith(
                            color: colori.testo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// "Aperta" o "Risolta", in piccolo.
class PastigliaStato extends StatelessWidget {
  const PastigliaStato({required this.risolta, super.key});

  final bool risolta;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final colore = risolta ? colori.ok : colori.testoSecondario;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: risolta ? colori.okTenue : colori.superficieAlt,
        borderRadius: BorderRadius.circular(AppRadius.pillola),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s4,
        ),
        child: Text(
          risolta ? 'Risolta' : 'Aperta',
          style: AppTypography.etichetta.copyWith(color: colore),
        ),
      ),
    );
  }
}
