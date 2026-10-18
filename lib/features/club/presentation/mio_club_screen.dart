import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/condivisione/condividi_testo.dart';
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
import '../../../widgets/secondary_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../application/membri_club_providers.dart';
import '../data/membri_club_repository.dart';
import '../domain/ruolo_club.dart';

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
    final ruolo = await showModalBottomSheet<RuoloClub>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _ScegliRuoloInvito(),
    );
    if (ruolo == null || !mounted) return;
    if (_occupato) return;
    setState(() => _occupato = true);
    String? codice;
    try {
      codice = await _repository.generaInvito(widget.clubId, ruolo);
    } catch (e) {
      if (mounted) {
        _avviso('Il codice non è stato creato. ${messaggioErrore(e)}');
      }
    } finally {
      if (mounted) setState(() => _occupato = false);
    }
    if (codice == null || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _DialogoCodiceInvito(
        codice: codice!,
        ruolo: ruolo,
        clubNome: widget.clubNome,
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
              occupato: _occupato,
              onScriviNome: _scriviNome,
              onCambiaRuolo: _cambiaRuolo,
              onTogli: _togli,
              onInvita: _invita,
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

class _Contenuto extends StatelessWidget {
  const _Contenuto({
    required this.membri,
    required this.occupato,
    required this.onScriviNome,
    required this.onCambiaRuolo,
    required this.onTogli,
    required this.onInvita,
  });

  final List<MembroClub> membri;
  final bool occupato;
  final Future<void> Function({String? nomeAttuale}) onScriviNome;
  final Future<void> Function(MembroClub membro, RuoloClub ruolo) onCambiaRuolo;
  final Future<void> Function(MembroClub membro) onTogli;
  final Future<void> Function() onInvita;

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
      ],
    );
  }
}

class _RigaMembro extends StatelessWidget {
  const _RigaMembro({
    required this.membro,
    required this.sonoResponsabile,
    required this.occupato,
    required this.onScriviNome,
    required this.onCambiaRuolo,
    required this.onTogli,
  });

  final MembroClub membro;
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

/// Il foglio "Chi inviti?": allenatore o assistente.
class _ScegliRuoloInvito extends StatelessWidget {
  const _ScegliRuoloInvito();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
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
              'Chi inviti?',
              style: AppTypography.sezione.copyWith(
                color: context.colori.testo,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            for (final ruolo in const [
              RuoloClub.allenatore,
              RuoloClub.assistente,
            ])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(ruolo.etichetta),
                subtitle: Text(ruolo.descrizione),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pop(ruolo),
              ),
          ],
        ),
      ),
    );
  }
}

/// Il codice appena creato, da copiare o mandare.
class _DialogoCodiceInvito extends StatelessWidget {
  const _DialogoCodiceInvito({
    required this.codice,
    required this.ruolo,
    required this.clubNome,
  });

  final String codice;
  final RuoloClub ruolo;
  final String clubNome;

  String get _testoInvito =>
      'Ti invito in $clubNome su WaterTactics come '
      '${ruolo.etichetta.toLowerCase()}. Registrati come allenatore e '
      'scegli «Ho un codice da allenatore»: $codice';

  Future<void> _copia(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: codice));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Codice copiato')));
  }

  Future<void> _condividi(BuildContext context) async {
    final condiviso = await condividiTesto(_testoInvito);
    if (condiviso || !context.mounted) return;
    // Senza il foglio "Condividi" si copia il messaggio intero.
    await Clipboard.setData(ClipboardData(text: _testoInvito));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Messaggio copiato')));
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return AlertDialog(
      title: Text('Codice per ${ruolo.etichetta.toLowerCase()}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.s16,
              horizontal: AppSpacing.s12,
            ),
            decoration: BoxDecoration(
              color: colori.superficieAlt,
              borderRadius: BorderRadius.circular(AppRadius.controllo),
              border: Border.all(color: colori.linea),
            ),
            child: SelectableText(
              codice,
              textAlign: TextAlign.center,
              style: AppTypography.numeroMedio.copyWith(
                color: colori.testo,
                fontFamily: 'monospace',
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            'Vale 7 giorni, una volta sola.',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          PrimaryButton(
            label: 'Condividi',
            icon: Icons.ios_share,
            onPressed: () => _condividi(context),
          ),
          const SizedBox(height: AppSpacing.s8),
          SecondaryButton(
            label: 'Copia',
            icon: Icons.copy_outlined,
            onPressed: () => _copia(context),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Chiudi'),
        ),
      ],
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
