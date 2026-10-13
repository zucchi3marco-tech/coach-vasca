import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/date_format.dart';
import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../allenamenti/data/allenamenti_repository.dart';
import '../../allenamenti/data/serie_repository.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../allenamenti/domain/piano_salvataggio_testo.dart';
import '../../allenamenti/domain/prossimo_allenamento.dart';
import '../../allenamenti/presentation/allenamento_detail_screen.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/abbina_atleta.dart';
import '../../atleti/domain/atleta.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../pallanuoto/data/distinta_repository.dart';
import '../application/fonte_dati_riverpod.dart';
import '../data/assistente_repository.dart';
import '../domain/motore_assistente.dart';
import '../domain/pseudonimi.dart';
import '../domain/strumenti_assistente.dart';

/// L'assistente dell'allenatore (proposta 9 del piano): una chat che
/// risponde con i dati del club e propone azioni da confermare. I dati li
/// legge e li conta il telefono; all'AI arrivano solo codici al posto dei
/// nomi e numeri già calcolati, mai benessere e dolori (decisione del 13
/// ottobre 2026). La conversazione non si salva: uscendo, sparisce.
class AssistenteScreen extends ConsumerStatefulWidget {
  const AssistenteScreen({
    required this.clubId,
    required this.sport,
    this.gruppoId,
    this.oggi,
    super.key,
  });

  final String clubId;
  final String sport;
  final String? gruppoId;

  /// Per i test; di solito adesso.
  final DateTime? oggi;

  @override
  ConsumerState<AssistenteScreen> createState() => _AssistenteScreenState();
}

/// Cosa è successo a una proposta.
enum _Esito { daDecidere, inCorso, fatta, scartata }

class _AssistenteScreenState extends ConsumerState<AssistenteScreen> {
  final _domanda = TextEditingController();
  final _scorrimento = ScrollController();
  final _voci = <VoceChat>[];
  final _esiti = <SchedaAssistente, _Esito>{};
  final _sedutaCreata = <PropostaSeduta, Allenamento>{};
  MotoreAssistente? _motore;
  bool _pensa = false;
  String? _strumento;

  DateTime get _oggi => widget.oggi ?? DateTime.now();

  @override
  void dispose() {
    _domanda.dispose();
    _scorrimento.dispose();
    super.dispose();
  }

  /// Il motore nasce alla prima domanda, con i codici degli atleti di
  /// adesso.
  Future<MotoreAssistente> _preparaMotore() async {
    if (_motore case final m?) return m;
    final fonte = FonteDatiRiverpod(
      ref,
      clubId: widget.clubId,
      gruppoId: widget.gruppoId,
    );
    final pseudonimi = Pseudonimi(await fonte.atleti());
    String? squadra;
    for (final g
        in ref.read(gruppiListProvider(widget.clubId)).value ?? const []) {
      if (g.id == widget.gruppoId) squadra = g.nome;
    }
    final repository = ref.read(assistenteRepositoryProvider);
    final contesto = <String, Object?>{
      'oggi': formatDateOnly(_oggi),
      'giorno': nomeGiorno(_oggi),
      'sport': widget.sport,
      'squadra': squadra ?? 'tutto il club',
    };
    return _motore = MotoreAssistente(
      pseudonimi: pseudonimi,
      strumenti: StrumentiAssistente(
        fonte: fonte,
        pseudonimi: pseudonimi,
        oggi: _oggi,
      ),
      chiama: (messaggi) => repository.prossimoMessaggio(
        clubId: widget.clubId,
        contesto: contesto,
        messaggi: messaggi,
      ),
    );
  }

  void _scendi() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!_scorrimento.hasClients) return;
    _scorrimento.animateTo(
      _scorrimento.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  });

  Future<void> _chiedi([String? testo]) async {
    final domanda = (testo ?? _domanda.text).trim();
    if (domanda.isEmpty || _pensa) return;
    _domanda.clear();
    setState(() {
      _voci.add(DomandaAllenatore(domanda));
      _pensa = true;
      _strumento = null;
    });
    _scendi();
    try {
      final motore = await _preparaMotore();
      final risposta = await motore.chiedi(
        domanda,
        suStrumento: (s) {
          if (mounted) setState(() => _strumento = etichetteStrumenti[s]);
        },
      );
      if (!mounted) return;
      setState(() {
        _voci.addAll(risposta);
        for (final v in risposta) {
          if (v is VoceScheda && v.scheda is! SchedaSalute) {
            _esiti[v.scheda] = _Esito.daDecidere;
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => _voci.add(
            ErroreAssistente(
              messaggioErrore(e).replaceFirst('Exception: ', ''),
              domanda: domanda,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _pensa = false);
      _scendi();
    }
  }

  void _riprova(ErroreAssistente errore) {
    setState(() {
      _voci.remove(errore);
      // La domanda è già in vista: si rifà senza ripeterla.
      final i = _voci.lastIndexWhere(
        (v) => v is DomandaAllenatore && v.testo == errore.domanda,
      );
      if (i >= 0) _voci.removeAt(i);
    });
    _chiedi(errore.domanda);
  }

  void _ricomincia() => setState(() {
    _voci.clear();
    _esiti.clear();
    _sedutaCreata.clear();
    _motore = null;
  });

  Future<void> _convoca(PropostaConvocazione p) async {
    setState(() => _esiti[p] = _Esito.inCorso);
    final repository = ref.read(distintaRepositoryProvider);
    try {
      for (final n in p.nuovi) {
        await repository.aggiungiConvocato(
          partitaId: p.partita.id,
          atletaId: n.atleta.id,
          numeroCalottina: n.numero,
          portiere: n.atleta.portiere,
        );
      }
      _motore?.annota(
        'Convocazione salvata: ${p.nuovi.length} atleti aggiunti alla '
        'distinta della partita ${p.partita.id}.',
      );
      if (mounted) setState(() => _esiti[p] = _Esito.fatta);
    } catch (e) {
      if (!mounted) return;
      setState(() => _esiti[p] = _Esito.daDecidere);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Convocazione non salvata: ${messaggioErrore(e)}'),
        ),
      );
    }
  }

  /// Come "Scrivi o detta": l'allenamento nella data proposta, per la
  /// squadra scelta, con le serie nell'ordine scritto.
  Future<void> _creaSeduta(PropostaSeduta p) async {
    setState(() => _esiti[p] = _Esito.inCorso);
    try {
      final allenamento = await ref
          .read(allenamentiRepositoryProvider)
          .createAllenamento(
            clubId: widget.clubId,
            data: p.data,
            titolo: p.titolo,
            gruppoId: widget.gruppoId,
          );
      final piano = pianoSalvataggio(
        vecchie: const [],
        nuove: p.scritto.serie,
        nuovoId: () => const Uuid().v4(),
      );
      final serie = ref.read(serieRepositoryProvider);
      for (final c in piano.crea) {
        final s = c.nuova;
        await serie.createSerie(
          allenamentoId: allenamento.id,
          ordine: c.ordine,
          blocco: s.blocco,
          ripetute: s.ripetute,
          distanzaM: s.distanzaM,
          durataS: s.durataS,
          stile: s.stile,
          esecuzione: s.esecuzione,
          zona: s.zona,
          passoObiettivoS: s.passoObiettivoS,
          recuperoS: s.recuperoS,
          ripartenzaS: s.ripartenzaS,
          attrezzatura: s.attrezzatura,
          note: s.note,
          piramideId: c.piramideId,
          recuperoDopoS: s.recuperoDopoS,
          destinatari: s.destinatari,
        );
      }
      _motore?.annota(
        'Seduta creata il ${formatDateOnly(p.data)} con '
        '${p.scritto.serie.length} serie.',
      );
      if (mounted) {
        setState(() {
          _esiti[p] = _Esito.fatta;
          _sedutaCreata[p] = allenamento;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _esiti[p] = _Esito.daDecidere);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seduta non creata: ${messaggioErrore(e)}')),
      );
    }
  }

  void _scarta(SchedaAssistente p) {
    _motore?.annota('L\'allenatore ha scartato la proposta.');
    setState(() => _esiti[p] = _Esito.scartata);
  }

  List<String> get _esempi => widget.sport == 'nuoto'
      ? const [
          'Chi è stato più presente nell\'ultimo mese?',
          'Come sta andando il carico della squadra?',
          'Chi ha segnato dolori questa settimana?',
          'Prepara la seduta di domani: 3 km aerobici',
        ]
      : const [
          'Com\'è andata la superiorità nelle ultime 5 partite?',
          'Convoca per la prossima partita, escludendo chi ha male alla '
              'spalla',
          'Chi ha segnato dolori questa settimana?',
          'Prepara la seduta di giovedì, con lavoro per i portieri',
        ];

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    // I nomi per la scheda della salute e le proposte arrivano già qui.
    final atleti =
        ref
            .watch(
              atletiListProvider((
                clubId: widget.clubId,
                includeInactive: false,
              )),
            )
            .value ??
        const [];

    return AppScaffold(
      larghezzaMassima: 820,
      appBar: AppBar(
        title: const Text('Assistente'),
        actions: [
          if (_voci.isNotEmpty)
            IconButton(
              tooltip: 'Ricomincia',
              onPressed: _pensa ? null : _ricomincia,
              icon: const Icon(Icons.restart_alt),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              controller: _scorrimento,
              padding: const EdgeInsets.only(bottom: AppSpacing.s16),
              children: [
                const _Riservatezza(),
                const SizedBox(height: AppSpacing.s16),
                if (_voci.isEmpty) _Inizio(esempi: _esempi, onEsempio: _chiedi),
                for (final v in _voci)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                    child: switch (v) {
                      DomandaAllenatore(:final testo) => _Domanda(testo),
                      RispostaAssistente() => _Risposta(v),
                      ErroreAssistente() => _Errore(
                        v,
                        onRiprova: _pensa ? null : () => _riprova(v),
                      ),
                      VoceScheda(:final scheda) => switch (scheda) {
                        SchedaSalute() => _CartaSalute(scheda, atleti: atleti),
                        PropostaConvocazione() => _CartaConvocazione(
                          scheda,
                          atleti: atleti,
                          esito: _esiti[scheda] ?? _Esito.daDecidere,
                          onConferma: () => _convoca(scheda),
                          onScarta: () => _scarta(scheda),
                        ),
                        PropostaSeduta() => _CartaSeduta(
                          scheda,
                          esito: _esiti[scheda] ?? _Esito.daDecidere,
                          creata: _sedutaCreata[scheda],
                          onConferma: () => _creaSeduta(scheda),
                          onScarta: () => _scarta(scheda),
                        ),
                      },
                    },
                  ),
                if (_pensa) _InAttesa(strumento: _strumento),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('domanda-assistente'),
                  controller: _domanda,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _chiedi(),
                  decoration: const InputDecoration(
                    hintText: 'Chiedi sui dati della squadra',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              IconButton.filled(
                tooltip: 'Chiedi',
                onPressed: _pensa ? null : _chiedi,
                icon: const Icon(Icons.arrow_upward),
                style: IconButton.styleFrom(
                  minimumSize: const Size(
                    AppSpacing.altezzaMinimaBersaglio,
                    AppSpacing.altezzaMinimaBersaglio,
                  ),
                  backgroundColor: colori.azione,
                  foregroundColor: colori.azioneInk,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// La riga in alto che dice cosa esce dal telefono.
class _Riservatezza extends StatelessWidget {
  const _Riservatezza();

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline, size: 16, color: colori.testoSecondario),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Text(
            'Nomi e dati sulla salute restano sul telefono: all\'AI arrivano '
            'codici al posto dei nomi e numeri già calcolati.',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
        ),
      ],
    );
  }
}

class _Inizio extends StatelessWidget {
  const _Inizio({required this.esempi, required this.onEsempio});

  final List<String> esempi;
  final ValueChanged<String> onEsempio;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.s16),
        Icon(Icons.forum_outlined, size: 48, color: colori.testoTenue),
        const SizedBox(height: AppSpacing.s12),
        Text(
          'Chiedi all\'assistente',
          style: AppTypography.sezione.copyWith(color: colori.testo),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Risponde con i dati del club e propone convocazioni e sedute: '
          'ogni proposta la controlli e la confermi tu.',
          style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
        ),
        const SizedBox(height: AppSpacing.s16),
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: [
            for (final e in esempi)
              ActionChip(label: Text(e), onPressed: () => onEsempio(e)),
          ],
        ),
      ],
    );
  }
}

class _Domanda extends StatelessWidget {
  const _Domanda(this.testo);

  final String testo;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s12,
          ),
          decoration: BoxDecoration(
            color: colori.azioneTenue,
            borderRadius: BorderRadius.circular(AppRadius.pannello),
          ),
          child: Text(
            testo,
            style: AppTypography.corpo.copyWith(color: colori.testo),
          ),
        ),
      ),
    );
  }
}

class _Risposta extends StatelessWidget {
  const _Risposta(this.risposta);

  final RispostaAssistente risposta;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.paddingPannello),
          decoration: BoxDecoration(
            color: colori.superficie,
            borderRadius: BorderRadius.circular(AppRadius.pannello),
            border: Border.all(color: colori.linea),
          ),
          child: SelectableText(
            risposta.testo.isEmpty ? '…' : risposta.testo,
            style: AppTypography.corpo.copyWith(color: colori.testo),
          ),
        ),
        if (risposta.datiLetti.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Ha letto: ${risposta.datiLetti.join(', ')}',
            style: AppTypography.piccolo.copyWith(color: colori.testoTenue),
          ),
        ],
      ],
    );
  }
}

class _Errore extends StatelessWidget {
  const _Errore(this.errore, {required this.onRiprova});

  final ErroreAssistente errore;
  final VoidCallback? onRiprova;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ErrorBanner(
        messaggio: 'L\'assistente non ha risposto.',
        suggerimento: errore.messaggio,
      ),
      TextButton(onPressed: onRiprova, child: const Text('Riprova')),
    ],
  );
}

class _InAttesa extends StatelessWidget {
  const _InAttesa({required this.strumento});

  final String? strumento;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LoadingSkeleton(width: 240, height: AppSpacing.s20),
        const SizedBox(height: AppSpacing.s8),
        Text(
          strumento == null ? 'Ci sto pensando' : 'Sto leggendo: $strumento',
          style: AppTypography.piccolo.copyWith(color: colori.testoTenue),
        ),
      ],
    );
  }
}

/// Il contenitore delle schede dell'assistente: pannello con titolo.
class _Carta extends StatelessWidget {
  const _Carta({
    required this.icona,
    required this.titolo,
    required this.figli,
  });

  final IconData icona;
  final String titolo;
  final List<Widget> figli;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.paddingPannello),
      decoration: BoxDecoration(
        color: colori.superficie,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        border: Border.all(color: colori.lineaForte),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icona, size: 20, color: colori.azione),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  titolo,
                  style: AppTypography.corpoForte.copyWith(color: colori.testo),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          ...figli,
        ],
      ),
    );
  }
}

/// I pulsanti di una proposta, o com'è andata.
class _Decisione extends StatelessWidget {
  const _Decisione({
    required this.esito,
    required this.conferma,
    required this.fatto,
    required this.onConferma,
    required this.onScarta,
    this.dopo,
  });

  final _Esito esito;
  final String conferma;
  final String fatto;
  final VoidCallback? onConferma;
  final VoidCallback onScarta;

  /// Un'azione dopo averla fatta ("Apri la seduta").
  final Widget? dopo;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return switch (esito) {
      _Esito.fatta => Row(
        children: [
          Icon(Icons.check_circle, size: 20, color: colori.ok),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              fatto,
              style: AppTypography.corpoForte.copyWith(color: colori.testo),
            ),
          ),
          ?dopo,
        ],
      ),
      _Esito.scartata => Text(
        'Proposta scartata',
        style: AppTypography.piccolo.copyWith(color: colori.testoTenue),
      ),
      _ => Wrap(
        spacing: AppSpacing.s8,
        runSpacing: AppSpacing.s8,
        children: [
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, AppSpacing.altezzaMinimaBersaglio),
            ),
            onPressed: esito == _Esito.inCorso ? null : onConferma,
            child: esito == _Esito.inCorso
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colori.azioneInk,
                    ),
                  )
                : Text(conferma),
          ),
          TextButton(
            onPressed: esito == _Esito.inCorso ? null : onScarta,
            child: const Text('Scarta'),
          ),
        ],
      ),
    };
  }
}

class _CartaConvocazione extends StatelessWidget {
  const _CartaConvocazione(
    this.proposta, {
    required this.atleti,
    required this.esito,
    required this.onConferma,
    required this.onScarta,
  });

  final PropostaConvocazione proposta;
  final List<Atleta> atleti;
  final _Esito esito;
  final VoidCallback onConferma;
  final VoidCallback onScarta;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final p = proposta.partita;
    return _Carta(
      icona: Icons.groups_outlined,
      titolo:
          'Distinta per ${dataEstesa(p.data)}, ${p.inCasa ? 'in casa' : 'in trasferta'} '
          'con ${p.avversario}',
      figli: [
        for (final n in proposta.nuovi)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s4),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '${n.numero}',
                    style: AppTypography.numerica(AppTypography.corpoForte)
                        .copyWith(color: colori.testoSecondario),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${atleti.isEmpty ? n.atleta.nomeCompleto : nomeBreve(n.atleta, atleti)}'
                    '${n.atleta.portiere ? ' (portiere)' : ''}',
                    style: AppTypography.corpo.copyWith(color: colori.testo),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          '${['${proposta.nuovi.length} da aggiungere', if (proposta.giaConvocati > 0) '${proposta.giaConvocati} già in distinta'].join(', ')} (al massimo ${p.numeroMaxConvocati})',
          style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
        ),
        if (proposta.oltreIlMassimo) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Sono ${proposta.totale}: oltre il massimo. Chiedi di toglierne '
            'qualcuno, o sistemala dalla distinta.',
            style: AppTypography.piccolo.copyWith(color: colori.attenzione),
          ),
        ],
        const SizedBox(height: AppSpacing.s12),
        _Decisione(
          esito: esito,
          conferma: 'Convoca',
          fatto: 'Convocati in distinta',
          onConferma: proposta.oltreIlMassimo ? null : onConferma,
          onScarta: onScarta,
        ),
      ],
    );
  }
}

class _CartaSeduta extends StatelessWidget {
  const _CartaSeduta(
    this.proposta, {
    required this.esito,
    required this.creata,
    required this.onConferma,
    required this.onScarta,
  });

  final PropostaSeduta proposta;
  final _Esito esito;
  final Allenamento? creata;
  final VoidCallback onConferma;
  final VoidCallback onScarta;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final s = proposta.scritto;
    final nonCapite = s.righeNonCapite;
    return _Carta(
      icona: Icons.pool,
      titolo: [
        'Seduta di ${dataEstesa(proposta.data)}',
        ?proposta.titolo,
      ].join(': '),
      figli: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.s12),
          decoration: BoxDecoration(
            color: colori.superficieAlt,
            borderRadius: BorderRadius.circular(AppRadius.controllo),
          ),
          child: SelectableText(
            proposta.testo.trim(),
            style: AppTypography.numerica(AppTypography.corpo)
                .copyWith(color: colori.testo),
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          [
            if (s.metri > 0) formattaMetri(s.metri),
            s.serie.length == 1 ? '1 serie' : '${s.serie.length} serie',
          ].join(' · '),
          style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
        ),
        if (nonCapite > 0) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(
            nonCapite == 1
                ? 'Una riga non è stata capita: non diventa una serie.'
                : '$nonCapite righe non sono state capite: non diventano '
                      'serie.',
            style: AppTypography.piccolo.copyWith(color: colori.attenzione),
          ),
        ],
        const SizedBox(height: AppSpacing.s12),
        _Decisione(
          esito: esito,
          conferma: 'Crea la seduta',
          fatto: 'Seduta creata',
          onConferma: onConferma,
          onScarta: onScarta,
          dopo: creata == null
              ? null
              : TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          AllenamentoDetailScreen(allenamento: creata!),
                    ),
                  ),
                  child: const Text('Apri'),
                ),
        ),
      ],
    );
  }
}

/// "dolore spalla 6/10, febbre": cosa ha segnato, in una voce sola.
String? _dettagli(RigaSalute r) {
  final voci = [
    if (r.scheda.dolori)
      'dolore ${r.scheda.zoneDolore.join(', ')}'
          '${r.scheda.intensitaDolore == null ? '' : ' ${r.scheda.intensitaDolore}/10'}',
    ...r.scheda.sintomi,
  ];
  return voci.isEmpty ? null : voci.join(', ');
}

/// Il benessere, calcolato e mostrato qui: all'AI non arriva.
class _CartaSalute extends StatelessWidget {
  const _CartaSalute(this.scheda, {required this.atleti});

  final SchedaSalute scheda;
  final List<Atleta> atleti;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    String nome(Atleta a) =>
        atleti.isEmpty ? a.nomeCompleto : nomeBreve(a, atleti);
    return _Carta(
      icona: Icons.favorite_border,
      titolo: scheda.titolo,
      figli: [
        if (scheda.righe.isEmpty)
          Text(
            'Nessuno, nelle schede compilate.',
            style: AppTypography.corpo.copyWith(color: colori.testoSecondario),
          ),
        for (final r in scheda.righe)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${nome(r.atleta)} · ${r.punteggio.etichetta} '
                  '${r.punteggio.valore}',
                  style: AppTypography.corpoForte.copyWith(color: colori.testo),
                ),
                Text(
                  [traQuanto(r.giorno), ?_dettagli(r)].join(' · '),
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
              ],
            ),
          ),
        if (scheda.senzaScheda.isNotEmpty)
          Text(
            'Senza scheda: ${scheda.senzaScheda.map(nome).join(', ')}',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
        const SizedBox(height: AppSpacing.s8),
        Row(
          children: [
            Icon(Icons.lock_outline, size: 14, color: colori.testoTenue),
            const SizedBox(width: AppSpacing.s4),
            Expanded(
              child: Text(
                'Calcolato sul telefono: all\'AI non arriva.',
                style: AppTypography.piccolo.copyWith(color: colori.testoTenue),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
