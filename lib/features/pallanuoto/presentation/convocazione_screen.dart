import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/condivisione/condividi_testo.dart';
import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';
import '../../../widgets/section_header.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../application/pallanuoto_providers.dart';
import '../data/partite_repository.dart';
import '../domain/convocazione.dart';
import '../domain/partita.dart';

/// La convocazione di una partita, nata dalla distinta: ora e piscina,
/// ritrovo, rientro, cosa portare e una nota. Accanto, il messaggio per il
/// gruppo WhatsApp dei genitori (da condividere o copiare) e "Invia ai
/// convocati", che manda l'avviso agli atleti con l'account (lo spedisce
/// il database, vedi la migrazione delle convocazioni). Quello che si
/// scrive si salva anche uscendo, senza inviare.
class ConvocazioneScreen extends ConsumerStatefulWidget {
  const ConvocazioneScreen({required this.partita, super.key});

  final Partita partita;

  @override
  ConsumerState<ConvocazioneScreen> createState() => _ConvocazioneScreenState();
}

class _ConvocazioneScreenState extends ConsumerState<ConvocazioneScreen> {
  late final TextEditingController _ora;
  late final TextEditingController _luogo;
  late final TextEditingController _ritrovoOra;
  late final TextEditingController _ritrovoLuogo;
  late final TextEditingController _rientroOra;
  late final TextEditingController _daPortare;
  late final TextEditingController _note;
  late final PartiteRepository _repository;
  ScaffoldMessengerState? _messenger;

  bool _modificato = false;
  bool _invio = false;
  String? _errore;

  @override
  void initState() {
    super.initState();
    final p = widget.partita;
    _ora = TextEditingController(text: p.ora ?? '');
    _luogo = TextEditingController(text: p.luogo ?? '');
    // Mai scritta: il ritrovo proposto un'ora prima della partita.
    final mai = p.ritrovoOra == null && !p.convocazioneInviata;
    _ritrovoOra = TextEditingController(
      text: p.ritrovoOra ?? (mai ? oraMeno(p.ora, 60) ?? '' : ''),
    );
    _ritrovoLuogo = TextEditingController(text: p.ritrovoLuogo ?? '');
    _rientroOra = TextEditingController(text: p.rientroOra ?? '');
    _daPortare = TextEditingController(text: p.daPortare ?? '');
    _note = TextEditingController(text: p.noteConvocazione ?? '');
    _repository = ref.read(partiteRepositoryProvider);
    // Di solito l'elenco "da portare" è sempre lo stesso: quello
    // dell'ultima convocazione.
    if (p.daPortare == null) {
      _repository.ultimoDaPortare(p.clubId).then((testo) {
        if (mounted && testo != null && _daPortare.text.isEmpty) {
          // Una proposta, non una modifica: uscendo senza toccare niente
          // non si salva.
          final prima = _modificato;
          _daPortare.text = testo;
          setState(() => _modificato = prima);
        }
      });
    }
    for (final c in _campi) {
      c.addListener(_suModifica);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
  }

  List<TextEditingController> get _campi => [
    _ora,
    _luogo,
    _ritrovoOra,
    _ritrovoLuogo,
    _rientroOra,
    _daPortare,
    _note,
  ];

  void _suModifica() {
    if (!mounted) return;
    setState(() => _modificato = true);
  }

  @override
  void dispose() {
    for (final c in _campi) {
      c.dispose();
    }
    super.dispose();
  }

  /// La partita com'è adesso (dopo un salvataggio arriva dal database
  /// locale), con la convocazione che si sta scrivendo.
  Partita _bozza(Partita salvata) => salvata.conConvocazione(
    ora: _ora.text,
    luogo: _luogo.text,
    ritrovoOra: _ritrovoOra.text,
    ritrovoLuogo: _ritrovoLuogo.text,
    rientroOra: _rientroOra.text,
    daPortare: _daPortare.text,
    noteConvocazione: _note.text,
  );

  Future<void> _salva({bool invia = false}) async {
    await _repository.salvaConvocazione(
      id: widget.partita.id,
      ora: _ora.text,
      luogo: _luogo.text,
      ritrovoOra: _ritrovoOra.text,
      ritrovoLuogo: _ritrovoLuogo.text,
      rientroOra: _rientroOra.text,
      daPortare: _daPortare.text,
      note: _note.text,
      invia: invia,
    );
    if (mounted) setState(() => _modificato = false);
  }

  void _avviso(String testo) {
    _messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(testo)));
  }

  /// Uscendo, quello che si è scritto resta (senza inviare niente).
  void _salvaUscendo() {
    if (!_modificato) return;
    _repository
        .salvaConvocazione(
          id: widget.partita.id,
          ora: _ora.text,
          luogo: _luogo.text,
          ritrovoOra: _ritrovoOra.text,
          ritrovoLuogo: _ritrovoLuogo.text,
          rientroOra: _rientroOra.text,
          daPortare: _daPortare.text,
          note: _note.text,
        )
        .catchError((Object e) {
          _avviso('Convocazione non salvata: ${messaggioErrore(e)}');
          return widget.partita;
        });
  }

  Future<void> _condividi(String testo) async {
    if (_modificato) _salvaSenzaAttendere();
    if (await condividiTesto(testo)) return;
    await _copia(testo);
  }

  Future<void> _copia(String testo) async {
    if (_modificato) _salvaSenzaAttendere();
    await Clipboard.setData(ClipboardData(text: testo));
    _avviso('Messaggio copiato: incollalo nel gruppo WhatsApp');
  }

  void _salvaSenzaAttendere() {
    _salva().catchError((Object e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    });
  }

  Future<void> _invia({required int conAccount, required bool dinuovo}) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          dinuovo
              ? 'Inviare di nuovo la convocazione?'
              : conAccount == 0
              ? 'Inviare la convocazione?'
              : conAccount == 1
              ? 'Inviare la convocazione a 1 convocato?'
              : 'Inviare la convocazione a $conAccount convocati?',
        ),
        content: Text(
          conAccount == 0
              ? 'Nessun convocato ha ancora l\'account: l\'avviso non '
                    'arriva a nessuno. Chi aggiungi dopo in distinta, con '
                    'l\'account, lo riceve subito.'
              : dinuovo
              ? 'I convocati con l\'account ricevono «Convocazione '
                    'aggiornata» con ritrovo e orari.'
              : 'Ricevono un avviso nell\'app e sul telefono con ritrovo '
                    'e orari.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          // Largo quanto la scritta: il tema allarga i pulsanti pieni a
          // tutta la riga, e nel dialog finiva sopra "Annulla".
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, AppSpacing.altezzaMinimaBersaglio),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Invia'),
          ),
        ],
      ),
    );
    if (conferma != true || !mounted) return;
    setState(() {
      _invio = true;
      _errore = null;
    });
    try {
      await _salva(invia: true);
      _avviso('Convocazione inviata');
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _invio = false);
    }
  }

  Future<void> _scegliOra(TextEditingController campo) async {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(campo.text);
    final scelta = await showTimePicker(
      context: context,
      initialTime: m == null
          ? const TimeOfDay(hour: 15, minute: 0)
          : TimeOfDay(hour: int.parse(m[1]!), minute: int.parse(m[2]!)),
    );
    if (scelta != null) {
      campo.text =
          '${scelta.hour.toString().padLeft(2, '0')}:'
          '${scelta.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _campoOra(String etichetta, TextEditingController campo) =>
      AppTextField(
        etichetta: etichetta,
        controller: campo,
        readOnly: true,
        onTap: () => _scegliOra(campo),
        suffixIcon: campo.text.isEmpty
            ? const Icon(Icons.access_time)
            : IconButton(
                tooltip: 'Togli l\'ora',
                icon: const Icon(Icons.close),
                onPressed: campo.clear,
              ),
      );

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final p = widget.partita;
    // La partita aggiornata dopo ogni salvataggio (l'ora dell'invio).
    final salvata =
        ref
            .watch(partiteListProvider(p.clubId))
            .value
            ?.where((x) => x.id == p.id)
            .firstOrNull ??
        p;
    final convocati = ref.watch(distintaListProvider(p.id)).value;
    final atleti =
        ref
            .watch(
              atletiListProvider((clubId: p.clubId, includeInactive: true)),
            )
            .value ??
        const [];
    final atletiPerId = {for (final a in atleti) a.id: a};
    String? squadra;
    for (final g in ref.watch(gruppiListProvider(p.clubId)).value ?? []) {
      if (g.id == p.gruppoId) squadra = g.nome;
    }

    final elenco = [
      for (final g in convocati ?? const [])
        if (atletiPerId[g.atletaId] case final a?) (atleta: a, giocatore: g),
    ];
    final testo = testoConvocazione(
      partita: _bozza(salvata),
      squadra: squadra,
      convocati: [
        for (final c in elenco)
          (
            numero: c.giocatore.numeroCalottina,
            cognome: c.atleta.cognome,
            nome: c.atleta.nome,
            portiere: c.giocatore.portiere,
          ),
      ],
    );
    final conAccount = elenco.where((c) => c.atleta.haAccountCollegato).length;
    final senzaAccount = elenco.length - conAccount;
    final inviataIl = salvata.convocazioneInviataIl;

    final calottina = p.coloreCalottina == 'blu' ? 'blu' : 'bianca';
    final modulo = <Widget>[
      FormGroup(
        titolo: 'La partita',
        campi: [
          _campoOra('Inizio partita (facoltativo)', _ora),
          AppTextField(
            etichetta: 'Piscina (facoltativo)',
            controller: _luogo,
            aiuto: 'Con l\'indirizzo, se le famiglie non la conoscono.',
          ),
          Text(
            'Calottina $calottina (${p.inCasa ? 'in casa' : 'in trasferta'})',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
        ],
      ),
      FormGroup(
        titolo: 'Ritrovo e rientro',
        campi: [
          _campoOra('Ora del ritrovo (facoltativo)', _ritrovoOra),
          AppTextField(
            etichetta: 'Dove ci si trova (facoltativo)',
            controller: _ritrovoLuogo,
            aiuto:
                'Per esempio «in piscina» o, in trasferta, «al club, si '
                'parte in pullman».',
          ),
          _campoOra('Rientro previsto (facoltativo)', _rientroOra),
        ],
      ),
      FormGroup(
        titolo: 'Per le famiglie',
        isUltimo: true,
        campi: [
          AppTextField(
            etichetta: 'Da portare (facoltativo)',
            controller: _daPortare,
            maxLines: 2,
            aiuto:
                'Per esempio: accappatoio, ciabatte, documento. La prossima '
                'convocazione lo propone uguale.',
          ),
          AppTextField(
            etichetta: 'Note (facoltativo)',
            controller: _note,
            maxLines: 3,
          ),
        ],
      ),
    ];

    final String statoInvio;
    if (elenco.isEmpty) {
      statoInvio =
          'Aggiungi i convocati nella distinta: la convocazione si invia a '
          'loro.';
    } else if (inviataIl != null) {
      statoInvio =
          'Inviata ${dataEstesa(inviataIl)} alle '
          '${inviataIl.hour.toString().padLeft(2, '0')}:'
          '${inviataIl.minute.toString().padLeft(2, '0')}. Chi aggiungi in '
          'distinta da ora la riceve subito; se cambi orari o ritrovo, '
          'inviala di nuovo.';
    } else if (conAccount == 0) {
      statoInvio =
          'Nessun convocato ha ancora l\'account: l\'avviso non arriva a '
          'nessuno. Usa il messaggio su WhatsApp.';
    } else {
      statoInvio = [
        conAccount == 1
            ? 'L\'avviso arriva nell\'app e sul telefono a 1 convocato con '
                  'l\'account.'
            : 'L\'avviso arriva nell\'app e sul telefono ai $conAccount '
                  'convocati con l\'account.',
        if (senzaAccount == 1)
          'L\'altro non ha l\'account: raggiungilo con il messaggio su '
              'WhatsApp.'
        else if (senzaAccount > 1)
          'Gli altri $senzaAccount non hanno l\'account: raggiungili con il '
              'messaggio su WhatsApp.',
      ].join(' ');
    }

    final messaggio = <Widget>[
      const TitoloSezione(
        'Il messaggio per le famiglie',
        spiegazione: 'Da incollare nel gruppo WhatsApp dei genitori.',
      ),
      Container(
        padding: const EdgeInsets.all(AppSpacing.paddingPannello),
        decoration: BoxDecoration(
          color: colori.superficie,
          borderRadius: BorderRadius.circular(AppRadius.pannello),
          border: Border.all(color: colori.linea),
        ),
        child: SelectableText(
          testo,
          style: AppTypography.corpo.copyWith(color: colori.testo),
        ),
      ),
      const SizedBox(height: AppSpacing.s12),
      Row(
        children: [
          Expanded(
            child: SecondaryButton(
              label: 'Condividi',
              icon: Icons.share_outlined,
              unaRiga: true,
              onPressed: () => _condividi(testo),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: SecondaryButton(
              label: 'Copia il messaggio',
              icon: Icons.copy_outlined,
              unaRiga: true,
              onPressed: () => _copia(testo),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.s28),
      const TitoloSezione('Ai convocati'),
      Text(
        statoInvio,
        style: AppTypography.corpo.copyWith(color: colori.testoSecondario),
      ),
      if (_errore != null) ...[
        const SizedBox(height: AppSpacing.s16),
        ErrorBanner(
          messaggio: 'Non è stato possibile salvare la convocazione.',
          suggerimento:
              'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
          dettaglioTecnico: _errore,
        ),
      ],
      const SizedBox(height: AppSpacing.s16),
      PrimaryButton(
        label: inviataIl == null
            ? 'Invia ai convocati'
            : 'Invia di nuovo ai convocati',
        icon: Icons.send_outlined,
        isLoading: _invio,
        onPressed: elenco.isEmpty || _invio
            ? null
            : () => _invia(conAccount: conAccount, dinuovo: inviataIl != null),
      ),
    ];

    return PopScope(
      onPopInvokedWithResult: (fatto, _) {
        if (fatto) _salvaUscendo();
      },
      child: AppScaffold(
        scrollabile: true,
        larghezzaMassima: 1100,
        appBar: AppBar(title: const Text('Convocazione')),
        body: LayoutBuilder(
          builder: (context, vincoli) {
            // Su schermo largo il messaggio accanto ai campi: si vede
            // cambiare mentre si scrive.
            if (vincoli.maxWidth >= 960) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: modulo,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: messaggio,
                    ),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...modulo,
                const SizedBox(height: AppSpacing.s28),
                ...messaggio,
              ],
            );
          },
        ),
      ),
    );
  }
}
