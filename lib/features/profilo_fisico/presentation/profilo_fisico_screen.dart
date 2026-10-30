import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../atleti/domain/atleta.dart';
import '../data/profilo_fisico_repository.dart';
import '../domain/misura_fisica.dart';

/// Altezza e peso dell'atleta, con lo storico per vedere la crescita
/// (profilo fisico, passo A). L'atleta li scrive solo se vuole; lo staff
/// li legge e, per chi ha meno di 18 anni, segna il consenso del
/// genitore che apre la sezione.
class ProfiloFisicoScreen extends ConsumerWidget {
  const ProfiloFisicoScreen({
    required this.atleta,
    this.vistaAllenatore = false,
    this.oggi,
    super.key,
  });

  final Atleta atleta;
  final bool vistaAllenatore;

  /// Solo per le prove.
  final DateTime? oggi;

  void _avviso(BuildContext context, String testo) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(testo)));

  Future<void> _apriMisura(
    BuildContext context,
    WidgetRef ref, {
    MisuraFisica? misura,
  }) async {
    final esito = await showDialog<_EsitoMisura>(
      context: context,
      builder: (_) => _DialogoMisura(
        atleta: atleta,
        misura: misura,
        oggi: oggi ?? DateTime.now(),
      ),
    );
    if (esito == null || !context.mounted) return;
    final repo = ref.read(profiloFisicoRepositoryProvider);
    try {
      switch (esito) {
        case _Salva(:final nuova):
          await repo.salva(nuova);
          // Spostata a un altro giorno: quella di prima non resta.
          if (misura != null && !DateUtils.isSameDay(misura.data, nuova.data)) {
            await repo.elimina(misura);
          }
        case _Togli():
          if (misura != null) await repo.elimina(misura);
      }
    } catch (e) {
      if (context.mounted) _avviso(context, messaggioErrore(e));
    }
    ref.invalidate(misureFisicheProvider(atleta.id));
  }

  Future<void> _segnaConsenso(BuildContext context, WidgetRef ref) async {
    final si = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Consenso del genitore'),
        content: Text(
          'Hai il consenso firmato di un genitore di ${atleta.nome}? '
          'Con il consenso ${atleta.nome} può scrivere altezza e peso, e '
          'li vedete solo voi dello staff.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          PrimaryButton(
            label: 'Sì, l\'ho ricevuto',
            expanded: false,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (si != true || !context.mounted) return;
    try {
      await ref
          .read(profiloFisicoRepositoryProvider)
          .segnaConsenso(atletaId: atleta.id, clubId: atleta.clubId);
    } catch (e) {
      if (context.mounted) _avviso(context, messaggioErrore(e));
    }
    ref.invalidate(consensoProfiloFisicoProvider(atleta.id));
  }

  Future<void> _togliConsenso(BuildContext context, WidgetRef ref) async {
    final si = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Togliere il consenso?'),
        content: Text(
          'Le misure di ${atleta.nome} si cancellano e la sezione si '
          'chiude finché non segni di nuovo il consenso.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          DangerButton(
            label: 'Togli il consenso',
            expanded: false,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (si != true || !context.mounted) return;
    try {
      await ref
          .read(profiloFisicoRepositoryProvider)
          .togliConsenso(atletaId: atleta.id, minorenne: true);
    } catch (e) {
      if (context.mounted) _avviso(context, messaggioErrore(e));
    }
    ref
      ..invalidate(consensoProfiloFisicoProvider(atleta.id))
      ..invalidate(misureFisicheProvider(atleta.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    final adesso = oggi ?? DateTime.now();
    final minorenne = !maggiorenne(atleta.dataNascita, adesso);
    final consensoAsync = minorenne
        ? ref.watch(consensoProfiloFisicoProvider(atleta.id))
        : const AsyncData<DateTime?>(null);
    final misureAsync = ref.watch(misureFisicheProvider(atleta.id));
    final consenso = consensoAsync.value;
    final aperto = profiloFisicoAperto(
      dataNascita: atleta.dataNascita,
      conConsenso: consenso != null,
      oggi: adesso,
    );
    final puoScrivere = !vistaAllenatore && aperto;
    final misure = misureAsync.value ?? const <MisuraFisica>[];
    final altezza = ultimoValore(misure, (m) => m.altezzaCm);
    final peso = ultimoValore(misure, (m) => m.pesoKg);

    Widget testo(String t) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Text(
        t,
        style: AppTypography.corpo.copyWith(color: colori.testoSecondario),
      ),
    );

    return AppScaffold(
      appBar: AppBar(),
      larghezzaMassima: AppLayout.larghezzaMassimaCruscotto,
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s32),
        children: [
          TestataPagina(
            occhiello: atleta.nomeCompleto,
            titolo: 'Altezza e peso',
            numeri: [
              NumeroTestata(
                valore: altezza == null ? '—' : '${numeroMisura(altezza)} cm',
                etichetta: 'Altezza',
              ),
              NumeroTestata(
                valore: peso == null ? '—' : '${numeroMisura(peso)} kg',
                etichetta: 'Peso',
              ),
            ],
            azioni: [
              if (puoScrivere)
                AzioneTestata(
                  icona: Icons.add,
                  etichetta: 'Aggiungi le misure',
                  principale: true,
                  onTap: () => _apriMisura(context, ref),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s24),
          if (minorenne && consensoAsync.isLoading && consenso == null)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.s16),
              child: LoadingSkeletonList(righe: 2),
            )
          else ...[
            if (minorenne && vistaAllenatore) ...[
              const TitoloSezione('Consenso del genitore'),
              if (consenso == null) ...[
                testo(
                  '${atleta.nome} ha meno di 18 anni: per scrivere altezza e '
                  'peso, e per «Chi mi può aiutare?» con gli specialisti del '
                  'club, serve il consenso firmato di un genitore. Quando '
                  'l\'hai ricevuto, segnalo qui.',
                ),
                const SizedBox(height: AppSpacing.s12),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16,
                  ),
                  child: PrimaryButton(
                    label: 'Segna il consenso ricevuto',
                    icon: Icons.task_alt,
                    onPressed: () => _segnaConsenso(context, ref),
                  ),
                ),
              ] else ...[
                testo('Ricevuto il ${dataLunga(consenso)}.'),
                const SizedBox(height: AppSpacing.s12),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16,
                  ),
                  child: SecondaryButton(
                    label: 'Togli il consenso',
                    onPressed: () => _togliConsenso(context, ref),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.s24),
            ],
            if (!aperto && !vistaAllenatore) ...[
              testo(
                'Hai meno di 18 anni: per scrivere altezza e peso serve il '
                'consenso di un genitore. Chiedi il modulo al tuo '
                'allenatore: quando lo riporti firmato, questa pagina si '
                'apre.',
              ),
              const SizedBox(height: AppSpacing.s24),
            ],
            if (aperto || misure.isNotEmpty)
              ..._storico(context, ref, misureAsync, puoScrivere),
          ],
          const SizedBox(height: AppSpacing.s16),
          testo(
            vistaAllenatore
                ? 'Le misure le scrive l\'atleta, se vuole. Le vedete solo '
                      'voi dello staff e lui; l\'assistente non le legge.'
                : 'Le scrivi solo se vuoi. Le vedete solo tu e i tuoi '
                      'allenatori; l\'assistente non le legge.',
          ),
        ],
      ),
    );
  }

  List<Widget> _storico(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<MisuraFisica>> misureAsync,
    bool puoScrivere,
  ) {
    final colori = context.colori;
    return misureAsync.when(
      data: (misure) {
        final oggiOra = oggi ?? DateTime.now();
        final crescite = [
          if (crescita(misure, (m) => m.altezzaCm, 'cm', oggi: oggiOra)
              case final c?)
            (etichetta: 'Altezza', testo: c),
          if (crescita(misure, (m) => m.pesoKg, 'kg', oggi: oggiOra)
              case final c?)
            (etichetta: 'Peso', testo: c),
        ];
        return [
          if (crescite.isNotEmpty) ...[
            const TitoloSezione('La crescita'),
            AppListPanel(
              righe: [
                for (final c in crescite)
                  AppListRow(titolo: c.etichetta, sottotitolo: c.testo),
              ],
            ),
            const SizedBox(height: AppSpacing.s24),
          ],
          TitoloSezione('Le misure', conteggio: misure.length),
          if (misure.isEmpty)
            puoScrivere
                ? AppListPanel(
                    righe: [
                      AppListRow(
                        leading: const Icon(Icons.add_circle_outline),
                        titolo: 'Aggiungi le prime misure',
                        onTap: () => _apriMisura(context, ref),
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16,
                    ),
                    child: Text(
                      'Non ha ancora scritto altezza e peso.',
                      style: AppTypography.corpo.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                  )
          else
            AppListPanel(
              righe: [
                for (final m in misure)
                  AppListRow(
                    titolo: dataEstesa(m.data),
                    sottotitolo: [
                      if (m.altezzaCm != null)
                        '${numeroMisura(m.altezzaCm!)} cm',
                      if (m.pesoKg != null) '${numeroMisura(m.pesoKg!)} kg',
                    ].join(' · '),
                    trailing: puoScrivere
                        ? Icon(Icons.edit_outlined, color: colori.azione)
                        : null,
                    onTap: puoScrivere
                        ? () => _apriMisura(context, ref, misura: m)
                        : null,
                  ),
              ],
            ),
        ];
      },
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
            messaggio: 'Non è stato possibile caricare altezza e peso.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(error),
          ),
        ),
      ],
    );
  }
}

sealed class _EsitoMisura {
  const _EsitoMisura();
}

class _Salva extends _EsitoMisura {
  const _Salva(this.nuova);
  final MisuraFisica nuova;
}

class _Togli extends _EsitoMisura {
  const _Togli();
}

/// Il giorno, l'altezza e il peso (uno dei due basta).
class _DialogoMisura extends StatefulWidget {
  const _DialogoMisura({required this.atleta, required this.oggi, this.misura});

  final Atleta atleta;
  final DateTime oggi;
  final MisuraFisica? misura;

  @override
  State<_DialogoMisura> createState() => _DialogoMisuraState();
}

class _DialogoMisuraState extends State<_DialogoMisura> {
  late DateTime _data;
  late final TextEditingController _altezza;
  late final TextEditingController _peso;
  String? _erroreAltezza;
  String? _errorePeso;
  String? _errore;

  @override
  void initState() {
    super.initState();
    final m = widget.misura;
    _data = m?.data ?? DateUtils.dateOnly(widget.oggi);
    _altezza = TextEditingController(
      text: m?.altezzaCm == null ? '' : numeroMisura(m!.altezzaCm!),
    );
    _peso = TextEditingController(
      text: m?.pesoKg == null ? '' : numeroMisura(m!.pesoKg!),
    );
  }

  @override
  void dispose() {
    _altezza.dispose();
    _peso.dispose();
    super.dispose();
  }

  Future<void> _scegliGiorno() async {
    final scelto = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2000),
      lastDate: DateUtils.dateOnly(widget.oggi),
    );
    if (scelto != null && mounted) setState(() => _data = scelto);
  }

  void _salva() {
    double? altezza;
    double? peso;
    String? erroreAltezza;
    String? errorePeso;
    try {
      altezza = leggiAltezza(_altezza.text);
    } on FormatException catch (e) {
      erroreAltezza = e.message;
    }
    try {
      peso = leggiPeso(_peso.text);
    } on FormatException catch (e) {
      errorePeso = e.message;
    }
    final vuota =
        erroreAltezza == null &&
        errorePeso == null &&
        altezza == null &&
        peso == null;
    setState(() {
      _erroreAltezza = erroreAltezza;
      _errorePeso = errorePeso;
      _errore = vuota ? 'Scrivi l\'altezza, il peso o tutti e due.' : null;
    });
    if (erroreAltezza != null || errorePeso != null || vuota) return;
    Navigator.of(context).pop(
      _Salva(
        MisuraFisica(
          atletaId: widget.atleta.id,
          clubId: widget.atleta.clubId,
          data: _data,
          altezzaCm: altezza,
          pesoKg: peso,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return AlertDialog(
      title: Text(widget.misura == null ? 'Le misure' : 'Cambia le misure'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              key: const Key('misura-giorno'),
              onPressed: _scegliGiorno,
              icon: const Icon(Icons.event_outlined),
              label: Text(dataEstesa(_data)),
            ),
            const SizedBox(height: AppSpacing.s16),
            TextField(
              key: const Key('misura-altezza'),
              controller: _altezza,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Altezza',
                suffixText: 'cm',
                hintText: 'Per esempio 172',
                errorText: _erroreAltezza,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            TextField(
              key: const Key('misura-peso'),
              controller: _peso,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Peso',
                suffixText: 'kg',
                hintText: 'Per esempio 61,5',
                errorText: _errorePeso,
              ),
              onSubmitted: (_) => _salva(),
            ),
            if (_errore != null) ...[
              const SizedBox(height: AppSpacing.s12),
              Text(
                _errore!,
                style: AppTypography.corpo.copyWith(color: colori.rosso),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (widget.misura != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(const _Togli()),
            child: const Text('Togli'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        PrimaryButton(label: 'Salva', expanded: false, onPressed: _salva),
      ],
    );
  }
}
