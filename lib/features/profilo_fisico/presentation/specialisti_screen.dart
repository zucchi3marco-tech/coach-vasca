import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_select.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../data/specialisti_repository.dart';
import '../domain/specialista.dart';
import 'contatti_specialisti_screen.dart';

/// «Specialisti convenzionati», da «Il mio club» (profilo fisico, passo
/// B): nutrizionista sportivo, fisioterapista, osteopata e
/// massoterapista del club. Il responsabile li aggiunge, li cambia e li
/// toglie; gli altri dello staff li leggono.
class SpecialistiScreen extends ConsumerWidget {
  const SpecialistiScreen({
    required this.clubId,
    required this.modificabile,
    super.key,
  });

  final String clubId;
  final bool modificabile;

  Future<void> _apri(
    BuildContext context,
    WidgetRef ref, {
    Specialista? specialista,
  }) async {
    final cambiato = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            SpecialistaFormScreen(clubId: clubId, specialista: specialista),
      ),
    );
    if (cambiato == true) ref.invalidate(specialistiProvider(clubId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    final elencoAsync = ref.watch(specialistiProvider(clubId));
    final elenco = elencoAsync.value ?? const <Specialista>[];

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
            occhiello: 'Il mio club',
            titolo: 'Specialisti convenzionati',
            numeri: [
              NumeroTestata(
                valore: elencoAsync.hasValue ? '${elenco.length}' : '—',
                etichetta: 'Specialisti',
              ),
            ],
            azioni: [
              if (modificabile)
                AzioneTestata(
                  icona: Icons.add,
                  etichetta: 'Aggiungi uno specialista',
                  principale: true,
                  onTap: () => _apri(context, ref),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s24),
          testo(
            'Nutrizionista sportivo, fisioterapista, osteopata e '
            'massoterapista, con il sito o il numero WhatsApp. Gli atleti li '
            'trovano nella loro home, in «Chi mi può aiutare?», in base a '
            'cosa sentono (sotto i 18 anni con il consenso del genitore). È '
            'solo un indirizzo, mai una diagnosi.',
          ),
          const SizedBox(height: AppSpacing.s24),
          // La traccia dei contatti, per la royalty: solo il responsabile.
          if (modificabile) ...[
            AppListPanel(
              righe: [
                AppListRow(
                  leading: const Icon(Icons.forum_outlined),
                  titolo: 'Chi li ha contattati',
                  sottotitolo:
                      'I contatti degli atleti mese per mese, con il codice',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ContattiSpecialistiScreen(clubId: clubId),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s24),
          ],
          ...elencoAsync.when(
            data: (elenco) => [
              if (elenco.isEmpty)
                modificabile
                    ? AppListPanel(
                        righe: [
                          AppListRow(
                            leading: const Icon(Icons.add_circle_outline),
                            titolo: 'Aggiungi il primo specialista',
                            onTap: () => _apri(context, ref),
                          ),
                        ],
                      )
                    : testo(
                        'Non ce ne sono ancora: li aggiunge il responsabile '
                        'del club.',
                      )
              else
                for (final tipo in TipoSpecialista.values)
                  if (elenco.where((s) => s.tipo == tipo).toList()
                      case final delTipo when delTipo.isNotEmpty) ...[
                    TitoloSezione(tipo.plurale, conteggio: delTipo.length),
                    AppListPanel(
                      righe: [
                        for (final s in delTipo)
                          AppListRow(
                            titolo: s.nome,
                            sottotitolo: [
                              if (s.descrizione case final d? when d.isNotEmpty)
                                d,
                              s.contatti,
                            ].join('\n'),
                            trailing: modificabile
                                ? Icon(
                                    Icons.edit_outlined,
                                    color: colori.azione,
                                  )
                                : null,
                            onTap: modificabile
                                ? () => _apri(context, ref, specialista: s)
                                : null,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s24),
                  ],
            ],
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
                  messaggio: 'Non è stato possibile caricare gli specialisti.',
                  suggerimento:
                      'Riprova. Se l\'errore continua, chiudi e riapri '
                      'l\'app.',
                  dettaglioTecnico: messaggioErrore(error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Il modulo di uno specialista: tipo, nome, due righe facoltative e
/// almeno un contatto fra WhatsApp e sito.
class SpecialistaFormScreen extends ConsumerStatefulWidget {
  const SpecialistaFormScreen({
    required this.clubId,
    this.specialista,
    super.key,
  });

  final String clubId;
  final Specialista? specialista;

  @override
  ConsumerState<SpecialistaFormScreen> createState() =>
      _SpecialistaFormScreenState();
}

class _SpecialistaFormScreenState extends ConsumerState<SpecialistaFormScreen> {
  final _form = GlobalKey<FormState>();
  late TipoSpecialista? _tipo = widget.specialista?.tipo;
  late final _nome = TextEditingController(text: widget.specialista?.nome);
  late final _descrizione = TextEditingController(
    text: widget.specialista?.descrizione,
  );
  late final _whatsapp = TextEditingController(
    text: widget.specialista?.whatsapp == null
        ? ''
        : mostraWhatsapp(widget.specialista!.whatsapp!),
  );
  late final _sito = TextEditingController(
    text: widget.specialista?.sito == null
        ? ''
        : mostraSito(widget.specialista!.sito!),
  );
  bool _occupato = false;
  String? _errore;

  @override
  void dispose() {
    _nome.dispose();
    _descrizione.dispose();
    _whatsapp.dispose();
    _sito.dispose();
    super.dispose();
  }

  String? _controlla(String? Function(String) leggi, String? testo) {
    try {
      leggi(testo ?? '');
      return null;
    } on FormatException catch (e) {
      return e.message;
    }
  }

  Future<void> _salva() async {
    if (_occupato) return;
    setState(() => _errore = null);
    if (!(_form.currentState?.validate() ?? false)) return;
    final whatsapp = leggiWhatsapp(_whatsapp.text);
    final sito = leggiSito(_sito.text);
    if (whatsapp == null && sito == null) {
      setState(
        () => _errore = 'Scrivi il numero WhatsApp, il sito o tutti e due.',
      );
      return;
    }
    final descrizione = _descrizione.text.trim();
    setState(() => _occupato = true);
    try {
      await ref
          .read(specialistiRepositoryProvider)
          .salva(
            Specialista(
              id: widget.specialista?.id,
              clubId: widget.clubId,
              tipo: _tipo!,
              nome: _nome.text.trim(),
              descrizione: descrizione.isEmpty ? null : descrizione,
              whatsapp: whatsapp,
              sito: sito,
            ),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _occupato = false;
          _errore = messaggioErrore(e);
        });
      }
    }
  }

  Future<void> _togli() async {
    final s = widget.specialista;
    if (s == null || _occupato) return;
    final si = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Togliere lo specialista?'),
        content: Text('${s.nome} non sarà più fra gli specialisti del club.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          DangerButton(
            label: 'Togli',
            expanded: false,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (si != true || !mounted) return;
    setState(() => _occupato = true);
    try {
      await ref.read(specialistiRepositoryProvider).elimina(s);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _occupato = false;
          _errore = messaggioErrore(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final nuovo = widget.specialista == null;
    return AppScaffold(
      appBar: AppBar(
        title: Text(nuovo ? 'Nuovo specialista' : 'Specialista'),
        actions: [
          if (!nuovo)
            IconButton(
              tooltip: 'Togli lo specialista',
              icon: const Icon(Icons.delete_outline),
              onPressed: _occupato ? null : _togli,
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.s16),
          children: [
            AppSelect<TipoSpecialista>(
              etichetta: 'Che specialista è',
              value: _tipo,
              hint: 'Scegli',
              items: [
                for (final t in TipoSpecialista.values)
                  DropdownMenuItem(value: t, child: Text(t.etichetta)),
              ],
              onChanged: (t) => setState(() => _tipo = t),
            ),
            if (_tipo == null && _errore == _sceltaTipo) ...[
              const SizedBox(height: AppSpacing.s4),
              Text(
                _sceltaTipo,
                style: AppTypography.piccolo.copyWith(color: colori.rosso),
              ),
            ],
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              etichetta: 'Nome',
              controller: _nome,
              aiuto: 'Come lo trovano gli atleti, per esempio «Studio Rossi»',
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return 'Scrivi il nome';
                if (t.length > 80) return 'Al massimo 80 caratteri';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              etichetta: 'Due righe (facoltative)',
              controller: _descrizione,
              maxLines: 3,
              aiuto: 'Dove riceve, per chi è, se fa uno sconto agli atleti',
              validator: (v) => (v ?? '').trim().length > 300
                  ? 'Al massimo 300 caratteri'
                  : null,
            ),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              etichetta: 'Numero WhatsApp',
              controller: _whatsapp,
              keyboardType: TextInputType.phone,
              aiuto: 'Senza prefisso vale +39',
              validator: (v) => _controlla(leggiWhatsapp, v),
            ),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              etichetta: 'Sito',
              controller: _sito,
              keyboardType: TextInputType.url,
              aiuto: 'Per esempio studiorossi.it',
              validator: (v) => _controlla(leggiSito, v),
            ),
            if (_errore != null && _errore != _sceltaTipo) ...[
              const SizedBox(height: AppSpacing.s16),
              Text(
                _errore!,
                style: AppTypography.corpo.copyWith(color: colori.rosso),
              ),
            ],
            const SizedBox(height: AppSpacing.s24),
            PrimaryButton(
              label: 'Salva',
              isLoading: _occupato,
              onPressed: _occupato
                  ? null
                  : () {
                      if (_tipo == null) {
                        setState(() => _errore = _sceltaTipo);
                        _form.currentState?.validate();
                        return;
                      }
                      _salva();
                    },
            ),
          ],
        ),
      ),
    );
  }
}

const _sceltaTipo = 'Scegli che specialista è';
