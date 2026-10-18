import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/modalita_demo.dart';
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
import '../../../widgets/riquadri.dart';
import '../../../widgets/scheda_elenco.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../configurazione/presentation/configurazione_guidata_screen.dart';
import '../../export/presentation/scarica_dati_club_screen.dart';
import '../application/current_club_provider.dart';
import '../application/membri_club_providers.dart';
import '../data/membri_club_repository.dart';
import '../domain/club.dart';
import '../domain/ruolo_club.dart';
import 'invita_staff.dart';

enum _AzioneMembro { faiAllenatore, faiAssistente, togli, cambiaNome }

/// "Il mio club": chi allena con te, che ruolo ha e cosa può fare. Il
/// responsabile invita allenatori e assistenti con un codice, cambia i loro
/// ruoli e li toglie dal club.
class MioClubScreen extends ConsumerStatefulWidget {
  const MioClubScreen({
    required this.clubId,
    required this.clubNome,
    super.key,
  });

  final String clubId;
  final String clubNome;

  @override
  ConsumerState<MioClubScreen> createState() => _MioClubScreenState();
}

class _MioClubScreenState extends ConsumerState<MioClubScreen> {
  bool _occupato = false;

  MembriClubRepository get _repository =>
      ref.read(membriClubRepositoryProvider);

  void _avviso(String testo) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(testo)));
  }

  /// Esegue [azione] e poi rilegge l'elenco; un errore diventa un avviso.
  Future<void> _esegui(Future<void> Function() azione, String errore) async {
    if (_occupato) return;
    setState(() => _occupato = true);
    try {
      await azione();
      ref.invalidate(membriClubProvider(widget.clubId));
      // Togliere o cambiare un allenatore può togliergli anche il ruolo di
      // capo di una squadra.
      ref.invalidate(squadreConCapoProvider(widget.clubId));
    } catch (e) {
      if (mounted) _avviso('$errore ${messaggioErrore(e)}');
    } finally {
      if (mounted) setState(() => _occupato = false);
    }
  }

  Future<void> _scriviNome({String? nomeAttuale}) async {
    final nome = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoNome(nomeIniziale: nomeAttuale),
    );
    if (nome == null || !mounted) return;
    await _esegui(
      () => _repository.scriviMioNome(widget.clubId, nome),
      'Il nome non è stato salvato.',
    );
  }

  Future<void> _cambiaRuolo(MembroClub membro, RuoloClub ruolo) {
    return _esegui(
      () => _repository.cambiaRuolo(widget.clubId, membro.userId, ruolo),
      'Il ruolo non è stato cambiato.',
    );
  }

  /// Il foglio "Capo di {squadra}": un allenatore o il responsabile, oppure
  /// nessuno.
  Future<void> _scegliCapo(
    SquadraConCapo squadra,
    List<MembroClub> membri,
  ) async {
    final scelta = await showModalBottomSheet<({String? userId})>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _ScegliCapo(squadra: squadra, membri: membri),
    );
    if (scelta == null || !mounted) return;
    await _esegui(
      () => _repository.scegliCapo(squadra.id, scelta.userId),
      'Il capo non è stato cambiato.',
    );
  }

  Future<void> _togli(MembroClub membro) async {
    final conferma =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('Togliere ${_nomeMembro(membro)} dal club?'),
            content: const Text(
              'Non vedrà più gli allenamenti e i dati del club. Potrai '
              'invitarlo di nuovo con un codice.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Annulla'),
              ),
              PrimaryButton(
                label: 'Togli',
                expanded: false,
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
            ],
          ),
        ) ==
        true;
    if (!conferma || !mounted) return;
    await _esegui(
      () => _repository.togliMembro(widget.clubId, membro.userId),
      'La persona non è stata tolta.',
    );
  }

  Future<void> _invita() async {
    if (_occupato) return;
    await invitaStaff(
      context,
      ref,
      clubId: widget.clubId,
      clubNome: widget.clubNome,
      onOccupato: (occupato) {
        if (mounted) setState(() => _occupato = occupato);
      },
    );
  }

  /// "Configurazione guidata": solo il responsabile ci arriva. Parte dalle
  /// squadre e, alla fine, si chiude tornando qui.
  void _apriConfigurazioneGuidata() {
    final club =
        ref.read(currentClubProvider).value ??
        Club(id: widget.clubId, nome: widget.clubNome);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (paginaContext) => ConfigurazioneGuidataScreen(
          club: club,
          comePagina: true,
          onFine: () => Navigator.of(paginaContext).pop(),
        ),
      ),
    );
  }

  /// "Scarica i dati del club": solo il responsabile ci arriva. Il nome
  /// scritto nel file è il suo, con l'email.
  void _scaricaDati(MembroClub io) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ScaricaDatiClubScreen(
          clubId: widget.clubId,
          clubNome: widget.clubNome,
          scaricatoDa: _scaricatoDa(io),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inDemo = dotenv.isInitialized && modalitaDemo;
    if (inDemo) {
      return AppScaffold(
        appBar: AppBar(),
        body: EmptyState(
          icona: Icons.groups_2_outlined,
          titolo: 'Nella demo il club è solo tuo',
          descrizione:
              'Con l\'app vera qui inviti allenatori e assistenti e decidi '
              'cosa possono fare.',
          azionePrincipale: 'Torna indietro',
          onAzionePrincipale: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    final membriAsync = ref.watch(membriClubProvider(widget.clubId));
    final squadreAsync = ref.watch(squadreConCapoProvider(widget.clubId));

    return AppScaffold(
      // La testata porta il titolo: la barra in alto resta vuota.
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s32),
        children: [
          TestataPagina(
            occhiello: widget.clubNome,
            titolo: 'Il mio club',
            sottotitolo: 'Chi allena con te e cosa può fare.',
          ),
          const SizedBox(height: AppSpacing.s28),
          membriAsync.when(
            loading: () => const LoadingSkeletonList(righe: 4),
            error: (error, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ErrorBanner(
                  messaggio: 'Non è stato possibile leggere chi c\'è nel club.',
                  suggerimento: 'Controlla la connessione e riprova.',
                  dettaglioTecnico: messaggioErrore(error),
                ),
                const SizedBox(height: AppSpacing.s12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () =>
                        ref.invalidate(membriClubProvider(widget.clubId)),
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('Riprova'),
                  ),
                ),
              ],
            ),
            data: (membri) => _Contenuto(
              membri: membri,
              // Finché non arrivano (o se non si leggono) la sezione dei
              // capi non c'è: il resto della pagina non aspetta.
              squadre: squadreAsync.value ?? const [],
              onScegliCapo: (squadra) => _scegliCapo(squadra, membri),
              occupato: _occupato,
              onScriviNome: _scriviNome,
              onCambiaRuolo: _cambiaRuolo,
              onTogli: _togli,
              onInvita: _invita,
              onScaricaDati: _scaricaDati,
              onConfigurazioneGuidata: _apriConfigurazioneGuidata,
            ),
          ),
        ],
      ),
    );
  }
}

/// Come si chiama una persona in elenco: il nome, o l'email (la vede solo il
/// responsabile) per chi non l'ha ancora scritto.
String _nomeMembro(MembroClub membro) =>
    membro.nome ?? membro.email ?? 'Senza nome';

/// Come chi scarica i dati si firma nel file: "Marco Rossi
/// (marco@example.com)", o solo quello che c'è.
String _scaricatoDa(MembroClub io) {
  final nome = io.nome;
  final email = io.email;
  if (nome != null && email != null) return '$nome ($email)';
  return nome ?? email ?? 'Responsabile del club';
}

class _Contenuto extends StatelessWidget {
  const _Contenuto({
    required this.membri,
    required this.squadre,
    required this.onScegliCapo,
    required this.occupato,
    required this.onScriviNome,
    required this.onCambiaRuolo,
    required this.onTogli,
    required this.onInvita,
    required this.onScaricaDati,
    required this.onConfigurazioneGuidata,
  });

  final List<MembroClub> membri;
  final List<SquadraConCapo> squadre;
  final Future<void> Function(SquadraConCapo squadra) onScegliCapo;
  final bool occupato;
  final Future<void> Function({String? nomeAttuale}) onScriviNome;
  final Future<void> Function(MembroClub membro, RuoloClub ruolo) onCambiaRuolo;
  final Future<void> Function(MembroClub membro) onTogli;
  final Future<void> Function() onInvita;
  final void Function(MembroClub io) onScaricaDati;
  final VoidCallback onConfigurazioneGuidata;

  @override
  Widget build(BuildContext context) {
    final io = membri.where((m) => m.sonoIo).firstOrNull;
    final sonoResponsabile = io?.ruolo.puoGestireStaff ?? false;
    final colori = context.colori;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (io != null && io.nome == null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.paddingPannello),
            decoration: BoxDecoration(
              color: colori.azioneTenue,
              borderRadius: BorderRadius.circular(AppRadius.pannello),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Scrivi il tuo nome',
                  style: AppTypography.corpoForte.copyWith(color: colori.testo),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  'Lo vedono gli altri allenatori, per esempio quando '
                  'modifichi un allenamento.',
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: PrimaryButton(
                    label: 'Scrivi il nome',
                    expanded: false,
                    onPressed: occupato ? null : () => onScriviNome(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
        ],
        TitoloSezione('Allenatori e assistenti', conteggio: membri.length),
        Container(
          decoration: BoxDecoration(
            color: colori.superficie,
            borderRadius: BorderRadius.circular(AppRadius.pannello),
            border: Border.all(color: colori.linea),
          ),
          child: Column(
            children: [
              for (var i = 0; i < membri.length; i++) ...[
                _RigaMembro(
                  membro: membri[i],
                  capoDi: [
                    for (final s in squadre)
                      if (s.capoUserId == membri[i].userId) s.nome,
                  ],
                  sonoResponsabile: sonoResponsabile,
                  occupato: occupato,
                  onScriviNome: onScriviNome,
                  onCambiaRuolo: onCambiaRuolo,
                  onTogli: onTogli,
                ),
                if (i != membri.length - 1)
                  Divider(height: 1, color: colori.linea),
              ],
            ],
          ),
        ),
        if (squadre.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s24),
          const TitoloSezione('Capi allenatori'),
          Padding(
            padding: const EdgeInsets.only(
              left: 4,
              right: 4,
              bottom: AppSpacing.s12,
            ),
            child: Text(
              'Il capo riceve un avviso quando un altro cambia un '
              'allenamento della sua squadra, e vede cosa è cambiato.',
              style: AppTypography.piccolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: colori.superficie,
              borderRadius: BorderRadius.circular(AppRadius.pannello),
              border: Border.all(color: colori.linea),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < squadre.length; i++) ...[
                  _RigaCapo(
                    squadra: squadre[i],
                    capo: membri
                        .where((m) => m.userId == squadre[i].capoUserId)
                        .firstOrNull,
                    modificabile: sonoResponsabile && !occupato,
                    onTap: () => onScegliCapo(squadre[i]),
                  ),
                  if (i != squadre.length - 1)
                    Divider(height: 1, color: colori.linea),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.s24),
        const TitoloSezione('Cosa può fare chi'),
        Container(
          padding: const EdgeInsets.all(AppSpacing.paddingPannello),
          decoration: BoxDecoration(
            color: colori.superficie,
            borderRadius: BorderRadius.circular(AppRadius.pannello),
            border: Border.all(color: colori.linea),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final ruolo in RuoloClub.values) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Pastiglia(ruolo.etichetta),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  ruolo.descrizione,
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
                if (ruolo != RuoloClub.values.last)
                  const SizedBox(height: AppSpacing.s12),
              ],
            ],
          ),
        ),
        if (sonoResponsabile) ...[
          const SizedBox(height: AppSpacing.s24),
          PrimaryButton(
            label: 'Invita un allenatore',
            onPressed: occupato ? null : onInvita,
          ),
        ],
        // Dopo "Invita un allenatore", che chiude il blocco di chi lavora
        // nel club: la configurazione guidata e i dati sono un altro
        // discorso, e solo del responsabile.
        if (sonoResponsabile && io != null) ...[
          const SizedBox(height: AppSpacing.s32),
          const TitoloSezione('Per cominciare'),
          SchedaElenco(
            leading: const IconaRiquadro(Icons.checklist_outlined),
            titolo: 'Configurazione guidata',
            sottotitolo:
                'Squadre, allenatori, atleti e codici, un passo alla volta',
            onTap: onConfigurazioneGuidata,
          ),
          const SizedBox(height: AppSpacing.s32),
          const TitoloSezione('I dati del club'),
          SchedaElenco(
            leading: const IconaRiquadro(Icons.download_outlined),
            titolo: 'Scarica i dati del club',
            // Nel sottotitolo (massimo due righe) la frase si taglierebbe
            // su un telefono: sotto il titolo va a capo quanto serve.
            sotto: Text(
              'Un file Excel con atleti, allenamenti, presenze, partite e il '
              'resto.',
              style: AppTypography.piccolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            onTap: () => onScaricaDati(io),
          ),
        ],
      ],
    );
  }
}

/// Una squadra e il suo capo allenatore. Il responsabile la tocca per
/// sceglierne un altro; per gli altri è solo da leggere.
class _RigaCapo extends StatelessWidget {
  const _RigaCapo({
    required this.squadra,
    required this.capo,
    required this.modificabile,
    required this.onTap,
  });

  final SquadraConCapo squadra;

  /// Null se la squadra non ha un capo (o non è più in elenco).
  final MembroClub? capo;
  final bool modificabile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final haCapo = squadra.capoUserId != null;
    final nomeCapo = haCapo
        ? (capo == null ? 'Senza nome' : _nomeMembro(capo!))
        : 'Nessun capo';
    final contenuto = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingPannello,
        vertical: AppSpacing.s12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  squadra.nome,
                  style: AppTypography.corpoForte.copyWith(color: colori.testo),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  nomeCapo,
                  style: AppTypography.piccolo.copyWith(
                    color: haCapo ? colori.testoSecondario : colori.testoTenue,
                  ),
                ),
              ],
            ),
          ),
          if (modificabile)
            Icon(Icons.chevron_right, color: colori.testoSecondario),
        ],
      ),
    );
    if (!modificabile) {
      return Semantics(label: '${squadra.nome}. $nomeCapo', child: contenuto);
    }
    return InkWell(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: 'Capo di ${squadra.nome}. $nomeCapo',
        excludeSemantics: true,
        child: contenuto,
      ),
    );
  }
}

/// Il foglio "Capo di {squadra}": chi può esserlo (il responsabile e gli
/// allenatori, non gli assistenti) e "Nessun capo". Torna `(userId: …)`;
/// chiuso senza scegliere torna null.
class _ScegliCapo extends StatelessWidget {
  const _ScegliCapo({required this.squadra, required this.membri});

  final SquadraConCapo squadra;
  final List<MembroClub> membri;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final candidati = [
      for (final m in membri)
        if (m.ruolo != RuoloClub.assistente) m,
    ];
    Widget segno(bool scelto) => scelto
        ? Icon(Icons.check, color: colori.azione)
        : const SizedBox(width: 24);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          0,
          AppSpacing.s16,
          AppSpacing.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Capo di ${squadra.nome}',
              style: AppTypography.sezione.copyWith(
                color: colori.testo,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            for (final m in candidati)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_nomeMembro(m)),
                subtitle: Text(m.ruolo.etichetta),
                trailing: segno(squadra.capoUserId == m.userId),
                onTap: () => Navigator.of(context).pop((userId: m.userId)),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Nessun capo'),
              trailing: segno(squadra.capoUserId == null),
              onTap: () => Navigator.of(context).pop((userId: null)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RigaMembro extends StatelessWidget {
  const _RigaMembro({
    required this.membro,
    required this.capoDi,
    required this.sonoResponsabile,
    required this.occupato,
    required this.onScriviNome,
    required this.onCambiaRuolo,
    required this.onTogli,
  });

  final MembroClub membro;

  /// I nomi delle squadre di cui è il capo allenatore.
  final List<String> capoDi;
  final bool sonoResponsabile;
  final bool occupato;
  final Future<void> Function({String? nomeAttuale}) onScriviNome;
  final Future<void> Function(MembroClub membro, RuoloClub ruolo) onCambiaRuolo;
  final Future<void> Function(MembroClub membro) onTogli;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final nome = _nomeMembro(membro);
    // Il responsabile non si cambia e non si toglie; gli altri sì, ma solo
    // dal responsabile.
    final gestibile =
        sonoResponsabile &&
        !membro.sonoIo &&
        membro.ruolo != RuoloClub.responsabile;

    final voci = <PopupMenuEntry<_AzioneMembro>>[
      if (membro.sonoIo)
        const PopupMenuItem(
          value: _AzioneMembro.cambiaNome,
          child: Text('Cambia il tuo nome'),
        ),
      if (gestibile) ...[
        if (membro.ruolo != RuoloClub.allenatore)
          const PopupMenuItem(
            value: _AzioneMembro.faiAllenatore,
            child: Text('Fai allenatore'),
          ),
        if (membro.ruolo != RuoloClub.assistente)
          const PopupMenuItem(
            value: _AzioneMembro.faiAssistente,
            child: Text('Fai assistente'),
          ),
        const PopupMenuItem(
          value: _AzioneMembro.togli,
          child: Text('Togli dal club'),
        ),
      ],
    ];

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.paddingPannello,
        top: AppSpacing.s8,
        bottom: AppSpacing.s8,
        right: AppSpacing.s4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: AppTypography.corpoForte.copyWith(
                    color: membro.nome == null
                        ? colori.testoSecondario
                        : colori.testo,
                  ),
                ),
                if (capoDi.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    'Capo di ${capoDi.join(', ')}',
                    style: AppTypography.piccolo.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.s4),
                Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s4,
                  children: [
                    Pastiglia(membro.ruolo.etichetta),
                    if (membro.sonoIo)
                      Pastiglia('Tu', colore: colori.testoSecondario),
                  ],
                ),
              ],
            ),
          ),
          if (voci.isEmpty)
            const SizedBox(width: AppSpacing.s12)
          else
            PopupMenuButton<_AzioneMembro>(
              tooltip: 'Azioni per $nome',
              enabled: !occupato,
              icon: const Icon(Icons.more_vert),
              itemBuilder: (_) => voci,
              onSelected: (azione) => switch (azione) {
                _AzioneMembro.cambiaNome => onScriviNome(
                  nomeAttuale: membro.nome,
                ),
                _AzioneMembro.faiAllenatore => onCambiaRuolo(
                  membro,
                  RuoloClub.allenatore,
                ),
                _AzioneMembro.faiAssistente => onCambiaRuolo(
                  membro,
                  RuoloClub.assistente,
                ),
                _AzioneMembro.togli => onTogli(membro),
              },
            ),
        ],
      ),
    );
  }
}

/// Dove si scrive il proprio nome. Torna il nome, o null se si annulla.
class _DialogoNome extends StatefulWidget {
  const _DialogoNome({this.nomeIniziale});

  final String? nomeIniziale;

  @override
  State<_DialogoNome> createState() => _DialogoNomeState();
}

class _DialogoNomeState extends State<_DialogoNome> {
  late final _controller = TextEditingController(text: widget.nomeIniziale);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _salva() {
    final nome = _controller.text.trim();
    if (nome.isEmpty) return;
    Navigator.of(context).pop(nome);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Il tuo nome'),
      content: AppTextField(
        etichetta: 'Nome e cognome',
        controller: _controller,
        onFieldSubmitted: (_) => _salva(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        PrimaryButton(label: 'Salva', expanded: false, onPressed: _salva),
      ],
    );
  }
}
