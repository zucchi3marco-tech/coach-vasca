import 'package:flutter/material.dart';

import '../../../core/dettatura/dettatura_vocale.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../domain/durata_serie.dart';
import '../domain/riordino_serie.dart';
import '../domain/testo_allenamento.dart';
import 'grafico_intensita.dart';
import 'riepilogo_volumi.dart';
import 'serie_labels.dart';

/// Metri, minuti e serie dell'allenamento che si sta scrivendo, fissi
/// sotto il titolo (come la testata dell'editor di Swimtraxx): crescono a
/// ogni riga e restano in vista anche con la tastiera aperta.
class BarraTotali extends StatelessWidget implements PreferredSizeWidget {
  const BarraTotali({
    required this.scritto,
    required this.riferimento,
    super.key,
  });

  final AllenamentoScritto scritto;
  final PassoRiferimento? riferimento;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final serie = scritto.serie;
    final numero = AppTypography.numerica(AppTypography.corpoForte)
        .copyWith(color: colori.testo);
    final etichetta = AppTypography.piccolo.copyWith(
      color: colori.testoSecondario,
    );
    // Su un telefono stretto, con numeri lunghi, ogni voce si rimpicciolisce
    // invece di uscire dalla barra.
    Widget voce(IconData icona, String valore, String testo) => Flexible(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icona, size: 18, color: colori.testoSecondario),
            const SizedBox(width: AppSpacing.s4),
            Text(valore, style: numero),
            Text(testo, style: etichetta),
          ],
        ),
      ),
    );
    final minuti = minutiStimati(serie, riferimento: riferimento);
    return Semantics(
      liveRegion: true,
      label:
          'Allenamento: ${formattaMetri(scritto.metri)} metri, circa '
          '$minuti minuti, ${raggruppaPerPiramide(serie).length} serie',
      child: ExcludeSemantics(
        child: Container(
          height: preferredSize.height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colori.linea)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              voce(Icons.straighten, formattaMetri(scritto.metri), ' m'),
              voce(Icons.timer_outlined, '$minuti', "' circa"),
              voce(
                Icons.format_list_numbered,
                '${raggruppaPerPiramide(serie).length}',
                ' serie',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lo scrivere a testo di Swimtraxx, uguale in "Nuovo allenamento" e in
/// "Scrivi l'allenamento": in cima la forma della seduta (grafico
/// dell'intensità), poi il testo — una serie per riga, capita mentre la
/// si scrive, senza AI — con sotto la riga del cursore spiegata e il
/// microfono, e accanto (o sotto, su telefono) come è stata capita
/// ognuna. I totali stanno in [BarraTotali], fissa in alto.
///
/// La dettatura è quella del browser (gratuita, Chrome/Edge): quello che
/// si dice va in fondo al testo, spezzato in righe a ogni virgola, punto
/// o "poi" ([righeDaDettato]), e lo legge l'app come quello scritto.
class EditorTestoAllenamento extends StatefulWidget {
  const EditorTestoAllenamento({
    required this.controller,
    required this.scritto,
    required this.riferimento,
    this.sottoIlTesto = const [],
    super.key,
  });

  final TextEditingController controller;

  /// [controller] già interpretato da chi usa l'editor (che lo rilegge a
  /// ogni modifica per [BarraTotali]).
  final AllenamentoScritto scritto;
  final PassoRiferimento? riferimento;

  /// Sotto il testo e il microfono: errori, il pulsante che salva.
  final List<Widget> sottoIlTesto;

  @override
  State<EditorTestoAllenamento> createState() => EditorTestoAllenamentoState();
}

class EditorTestoAllenamentoState extends State<EditorTestoAllenamento> {
  DettatoreVocale? _dettatore;
  bool _inAscolto = false;
  String? _erroreMicrofono;

  /// Il testo prima di premere il microfono: il dettato si aggiunge sotto.
  String _prefisso = '';

  @override
  void dispose() {
    _dettatore?.dispose();
    super.dispose();
  }

  /// Da chiamare prima di salvare: la dettatura non deve cambiare il testo
  /// mentre si salva.
  void ferma() => _dettatore?.ferma();

  void _alternaAscolto() {
    if (_inAscolto) {
      _dettatore?.ferma();
      return;
    }
    setState(() => _erroreMicrofono = null);
    _prefisso = widget.controller.text.trimRight();
    _dettatore = DettatoreVocale(
      onTrascrizione: (sessione) {
        if (!mounted) return;
        final testo = [
          _prefisso,
          righeDaDettato(sessione),
        ].where((t) => t.isNotEmpty).join('\n');
        widget.controller.value = TextEditingValue(
          text: testo,
          selection: TextSelection.collapsed(offset: testo.length),
        );
      },
      onErrore: (messaggio) {
        if (!mounted) return;
        setState(() => _erroreMicrofono = messaggio);
      },
      onFine: () {
        if (!mounted) return;
        setState(() => _inAscolto = false);
      },
    );
    setState(() => _inAscolto = true);
    _dettatore!.avvia();
  }

  /// La riga dove sta il cursore, per dire subito come è stata capita.
  RigaScritta? _rigaCorrente() {
    final controller = widget.controller;
    final selezione = controller.selection;
    if (!selezione.isValid) return null;
    final fine = selezione.baseOffset.clamp(0, controller.text.length);
    final indice = '\n'.allMatches(controller.text.substring(0, fine)).length;
    final righe = widget.scritto.righe;
    return indice < righe.length ? righe[indice] : null;
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final scritto = widget.scritto;
    final corrente = _rigaCorrente();
    final microfono = DettatoreVocale.disponibile;

    final editor = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (scritto.serie.isNotEmpty) ...[
          _Andamento(scritto: scritto, riferimento: widget.riferimento),
          const SizedBox(height: AppSpacing.s16),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                'Una serie per riga',
                style: AppTypography.etichetta.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => mostraAiutoScrittura(context),
              icon: const Icon(Icons.help_outline, size: 18),
              label: const Text('Come si scrive'),
            ),
          ],
        ),
        TextField(
          key: const Key('testo-allenamento'),
          controller: widget.controller,
          keyboardType: TextInputType.multiline,
          minLines: 10,
          maxLines: null,
          autocorrect: false,
          enableSuggestions: false,
          style: AppTypography.numerica(AppTypography.corpo)
              .copyWith(color: colori.testo),
          decoration: const InputDecoration(
            hintText:
                'Riscaldamento\n400 mix A1\n\nPrincipale\n2x\n'
                '4x100 sl B1 @1:40\n4x50 do r15\n\n200 sl sciolto',
            hintMaxLines: 9,
          ),
        ),
        if (corrente != null && corrente.tipo != TipoRiga.vuota)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s8),
            child: Text(
              _comeCapita(corrente),
              style: AppTypography.piccolo.copyWith(
                color: corrente.tipo == TipoRiga.errore
                    ? colori.rosso
                    : colori.testoSecondario,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.s12),
        if (microfono)
          Row(
            children: [
              IconButton.filled(
                iconSize: 28,
                style: IconButton.styleFrom(
                  backgroundColor: _inAscolto ? colori.rosso : colori.azione,
                ),
                icon: Icon(
                  _inAscolto ? Icons.stop : Icons.mic,
                  color: colori.azioneInk,
                ),
                tooltip: _inAscolto ? 'Ferma la dettatura' : 'Detta a voce',
                onPressed: _alternaAscolto,
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Text(
                  _erroreMicrofono ??
                      (_inAscolto
                          ? 'Sto ascoltando: una serie dopo l\'altra, con '
                                'una pausa (o "poi") fra una e l\'altra.'
                          : 'Detta a voce, es. "riscaldamento 400 misti, '
                                'poi 8 da 100 stile libero recupero 20".'),
                  style: AppTypography.piccolo.copyWith(
                    color: _erroreMicrofono != null
                        ? colori.rosso
                        : colori.testoSecondario,
                  ),
                ),
              ),
            ],
          )
        else
          Text(
            'Per dettare a voce serve Chrome o Edge: qui si scrive.',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
        ...widget.sottoIlTesto,
      ],
    );
    final anteprima = _Anteprima(scritto: scritto);

    return LayoutBuilder(
      builder: (context, vincoli) {
        if (vincoli.maxWidth < 840) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              editor,
              const SizedBox(height: AppSpacing.s24),
              anteprima,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: editor),
            const SizedBox(width: AppSpacing.s24),
            Expanded(child: anteprima),
          ],
        );
      },
    );
  }
}

/// La forma della seduta che si sta scrivendo, e su cosa sono stimati i
/// minuti.
class _Andamento extends StatelessWidget {
  const _Andamento({required this.scritto, required this.riferimento});

  final AllenamentoScritto scritto;
  final PassoRiferimento? riferimento;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: colori.superficie,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        border: Border.all(color: colori.linea),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GraficoIntensita(serie: scritto.serie, riferimento: riferimento),
          const SizedBox(height: AppSpacing.s8),
          Text(
            riferimento == null
                ? "Minuti stimati su un passo medio di 1'50'' ogni 100 m: "
                      'nel gruppo mancano i primati sui 100 stile libero.'
                : 'Minuti stimati sui primati del gruppo (la corsia più '
                      'lenta), zona per zona.',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
        ],
      ),
    );
  }
}

/// "8×100m Libero · B1 · rip 1:30" per la riga sotto il cursore.
String _comeCapita(RigaScritta riga) => switch (riga.tipo) {
  TipoRiga.vuota => '',
  TipoRiga.titolo => 'Inizia il blocco ${labelBlocco(riga.blocco!)}',
  TipoRiga.giri =>
    'Ripete ${riga.giri} volte le righe sotto, fino alla prima riga vuota',
  TipoRiga.errore => riga.problema!,
  TipoRiga.serie => [
    if (riga.serie.length > 1)
      titoloGruppo(riga.serie)
    else
      titoloSerie(riga.serie.single),
    ...dettagliSerie(riga.serie.first),
  ].join(' · '),
};

/// Come è stato capito il testo, riga per riga: i titoli dei blocchi, i
/// "2x" con le serie che ripetono, le righe non capite in rosso.
class _Anteprima extends StatelessWidget {
  const _Anteprima({required this.scritto});

  final AllenamentoScritto scritto;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final righe = scritto.righe.where((r) => r.tipo != TipoRiga.vuota);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Come le ho capite',
          style: AppTypography.sezione.copyWith(color: colori.testo),
        ),
        const SizedBox(height: AppSpacing.s8),
        if (righe.isEmpty)
          Text(
            'Scrivi la prima serie, per esempio "400 sl A1": qui compare '
            'subito come la leggo.',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
        for (final riga in righe) _RigaAnteprima(riga: riga),
      ],
    );
  }
}

class _RigaAnteprima extends StatelessWidget {
  const _RigaAnteprima({required this.riga});

  final RigaScritta riga;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    switch (riga.tipo) {
      case TipoRiga.vuota:
        return const SizedBox.shrink();
      case TipoRiga.titolo:
        return Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.s12,
            bottom: AppSpacing.s4,
          ),
          child: Text(
            labelBlocco(riga.blocco!),
            style: AppTypography.corpoForte.copyWith(color: colori.testo),
          ),
        );
      case TipoRiga.giri:
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.s8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colori.azioneTenue,
                  borderRadius: BorderRadius.circular(AppRadius.pillola),
                ),
                child: Text(
                  '${riga.giri}×',
                  style: AppTypography.numerica(AppTypography.etichetta)
                      .copyWith(color: colori.testo),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                'si ripete ${riga.giri} volte',
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
            ],
          ),
        );
      case TipoRiga.errore:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, size: 20, color: colori.rosso),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      riga.testo.trim(),
                      style: AppTypography.corpo.copyWith(color: colori.testo),
                    ),
                    Text(
                      '${riga.problema}: non diventa una serie',
                      style: AppTypography.piccolo.copyWith(
                        color: colori.rosso,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case TipoRiga.serie:
        final prima = riga.serie.first;
        final titolo = riga.serie.length > 1
            ? titoloGruppo(riga.serie)
            : titoloSerie(prima);
        final dettagli = dettagliSerie(prima);
        final coloreZona = context.dominio.colorePerZona(
          prima.zona,
          rispetto: colori.linea,
        );
        final dentroGiro = riga.giri > 1;
        return Container(
          margin: EdgeInsets.only(
            left: dentroGiro ? AppSpacing.s12 : 0,
            top: AppSpacing.s4,
          ),
          padding: const EdgeInsets.only(left: AppSpacing.s12),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: coloreZona, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titolo,
                style: AppTypography.corpoForte.copyWith(color: colori.testo),
              ),
              if (dettagli.isNotEmpty)
                Text(
                  dettagli.join(' · '),
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
              if (prima.note case final nota?)
                Text(
                  riga.paroleIgnote.isEmpty
                      ? 'Nota: $nota'
                      : 'Nota (parole non riconosciute): $nota',
                  style: AppTypography.piccolo.copyWith(
                    color: riga.paroleIgnote.isEmpty
                        ? colori.testoSecondario
                        : colori.attenzione,
                  ),
                ),
            ],
          ),
        );
    }
  }
}

/// La guida "Come si scrive".
void mostraAiutoScrittura(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) {
      final colori = context.colori;
      final voci = <(String, String)>[
        ('400 sl', 'una distanza: 400 metri stile libero'),
        ('8x100', 'ripetute per distanza'),
        ("10'  3x5'  6x30''", 'serie a tempo'),
        ('50-100-200', 'piramide: una distanza dopo l\'altra'),
        ('2x(50-100) r15 r60', 'piramide a giri: recupero fra i giri'),
        ('2x  (da solo)', 'ripete le righe sotto fino alla riga vuota'),
        (
          'Riscaldamento',
          'titolo: apre il blocco (anche Principale, '
              'Defaticamento, Altro)',
        ),
        ('sl do ra df mix', 'stile'),
        ('gambe braccia pull tecnica remate test', 'esecuzione'),
        ('sciolto  lungo  progressione', 'come nuotarla: va nella nota'),
        (
          'palleggio tiri schemi gioco da schierati partita',
          'pallanuoto: lo stile non serve',
        ),
        (
          'uomo in +  uomo in -',
          'superiorità e inferiorità (anche "uomo in più", "uomo in meno")',
        ),
        ('tecnico-tattico  a-secco', 'altro lavoro senza stile'),
        ('A1 A2 B1 B2 C1 C2 C3 D', 'zona'),
        ('1:25', 'passo sui 100'),
        ('@1:30', 'ripartenza'),
        ('r15  r1:00', 'recupero'),
        ('pinne palette  [pinne corte]', 'attrezzi'),
        ('"testo"', 'nota; anche le parole che non conosco finiscono qui'),
      ];
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          0,
          AppSpacing.s16,
          AppSpacing.s24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Come si scrive',
              style: AppTypography.sezione.copyWith(color: colori.testo),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              "Una serie per riga, le parole in qualsiasi ordine. Mentre "
              "scrivi, sotto il testo leggi come ho capito la riga.",
              style: AppTypography.piccolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            for (final (esempio, significato) in voci)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 150,
                      child: Text(
                        esempio,
                        style: AppTypography.numerica(AppTypography.corpoForte)
                            .copyWith(color: colori.testo),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Text(
                        significato,
                        style: AppTypography.piccolo.copyWith(
                          color: colori.testoSecondario,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
}
