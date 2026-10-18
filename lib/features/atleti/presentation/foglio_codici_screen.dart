import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/scarica_file.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';
import '../../../widgets/tonal_chip.dart';
import '../../club/application/current_club_provider.dart';
import '../../club/domain/club.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../gruppi/domain/gruppo.dart';
import '../application/atleti_providers.dart';
import '../application/biglietti_codici_pdf.dart';
import '../data/inviti_atleta_repository.dart';
import '../domain/atleta.dart';

/// Fare il PDF e cosa farne una volta pronto: stamparlo o scaricarlo.
/// Dietro un provider perché nei test non c'è né una stampante né un
/// browser (e i font del PDF non si caricano con il tempo finto).
class AzioniFoglio {
  const AzioniFoglio();

  Future<Uint8List> creaPdf({
    required String nomeClub,
    required List<BigliettoCodice> biglietti,
    String? indirizzoApp,
  }) => generaBigliettiCodici(
    nomeClub: nomeClub,
    biglietti: biglietti,
    indirizzoApp: indirizzoApp,
  );

  Future<void> stampa(Uint8List bytes, String nome) =>
      Printing.layoutPdf(onLayout: (_) => bytes, name: nome);

  Future<void> scarica(Uint8List bytes, String nomeFile) async {
    if (scaricaFileDisponibile) {
      scaricaFile(bytes, nomeFile, mimeType: 'application/pdf');
    } else {
      await Printing.sharePdf(bytes: bytes, filename: nomeFile);
    }
  }
}

final azioniFoglioProvider = Provider<AzioniFoglio>(
  (ref) => const AzioniFoglio(),
);

enum _Fase { scelta, creazione, pronto }

/// Il foglio dei codici: un biglietto da stampare per ogni atleta senza
/// account, con il suo codice personale (30 giorni, una volta sola).
///
/// [gruppoId]: la squadra proposta all'apertura (null = tutto il club).
/// [soloAtletaIds]: solo questi atleti (es. quelli appena aggiunti da un
/// foglio Excel); se c'è, la scelta della squadra non serve.
class FoglioCodiciScreen extends ConsumerStatefulWidget {
  const FoglioCodiciScreen({super.key, this.gruppoId, this.soloAtletaIds});

  final String? gruppoId;
  final List<String>? soloAtletaIds;

  @override
  ConsumerState<FoglioCodiciScreen> createState() => _FoglioCodiciScreenState();
}

class _FoglioCodiciScreenState extends ConsumerState<FoglioCodiciScreen> {
  _Fase _fase = _Fase.scelta;
  String? _gruppoScelto;
  final Set<String> _esclusi = {};
  String? _errore;

  // Il foglio pronto: gli stessi byte per stampare e scaricare, così i
  // codici si creano una volta sola.
  Uint8List? _bytes;
  String _nomeFile = 'codici.pdf';
  int _numeroBiglietti = 0;
  int _mancanti = 0;
  DateTime? _scadenza;

  @override
  void initState() {
    super.initState();
    _gruppoScelto = widget.gruppoId;
  }

  /// Gli atleti tra cui scegliere: quelli del club, della squadra scelta o
  /// solo quelli passati da fuori.
  List<Atleta> _candidati(List<Atleta> tutti) {
    final solo = widget.soloAtletaIds;
    final scelti = solo != null
        ? tutti.where((a) => solo.contains(a.id))
        : tutti.where(
            (a) => _gruppoScelto == null || a.gruppoId == _gruppoScelto,
          );
    return scelti.toList()..sort(
      (a, b) =>
          a.nomeCompleto.toLowerCase().compareTo(b.nomeCompleto.toLowerCase()),
    );
  }

  String _etichettaScelta(Club club, List<Gruppo> gruppi) {
    if (widget.soloAtletaIds != null || _gruppoScelto == null) return club.nome;
    return gruppi
            .where((g) => g.id == _gruppoScelto)
            .map((g) => g.nome)
            .firstOrNull ??
        club.nome;
  }

  Future<void> _crea({
    required Club club,
    required List<Atleta> scelti,
    required List<Gruppo> gruppi,
  }) async {
    if (scelti.isEmpty || _fase == _Fase.creazione) return;
    setState(() {
      _fase = _Fase.creazione;
      _errore = null;
    });
    try {
      final codici = await ref
          .read(invitiAtletaRepositoryProvider)
          .generaCodiciFoglio([for (final a in scelti) a.id]);
      final perId = {for (final a in scelti) a.id: a};
      final nomiSquadre = {for (final g in gruppi) g.id: g.nome};
      final biglietti = [
        for (final c in codici)
          if (perId[c.atletaId] case final a?)
            BigliettoCodice(
              cognome: a.cognome,
              nome: a.nome,
              squadra: nomiSquadre[a.gruppoId],
              codice: c.codice,
              scade: c.scade,
            ),
      ];
      if (biglietti.isEmpty) {
        if (mounted) {
          setState(() {
            _fase = _Fase.scelta;
            _errore =
                'Non è stato creato nessun codice: forse questi atleti hanno '
                'già l\'account. Controlla l\'elenco e riprova.';
          });
        }
        return;
      }
      final bytes = await ref
          .read(azioniFoglioProvider)
          .creaPdf(
            nomeClub: club.nome,
            biglietti: biglietti,
            indirizzoApp: kIsWeb ? Uri.base.origin : null,
          );
      final etichetta = _etichettaScelta(club, gruppi);
      if (mounted) {
        setState(() {
          _bytes = bytes;
          _nomeFile = 'codici_${_perNomeFile(etichetta)}.pdf';
          _numeroBiglietti = biglietti.length;
          _mancanti = scelti.length - biglietti.length;
          _scadenza = biglietti
              .map((b) => b.scade)
              .reduce((a, b) => a.isBefore(b) ? a : b);
          _fase = _Fase.pronto;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fase = _Fase.scelta;
          _errore = messaggioErrore(e);
        });
      }
    }
  }

  Future<void> _stampa() async {
    final bytes = _bytes;
    if (bytes == null) return;
    try {
      await ref.read(azioniFoglioProvider).stampa(bytes, _nomeFile);
    } catch (e) {
      _mostraErrore(e);
    }
  }

  Future<void> _scarica() async {
    final bytes = _bytes;
    if (bytes == null) return;
    try {
      await ref.read(azioniFoglioProvider).scarica(bytes, _nomeFile);
    } catch (e) {
      _mostraErrore(e);
    }
  }

  void _mostraErrore(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
  }

  void _altroFoglio() {
    setState(() {
      _fase = _Fase.scelta;
      _bytes = null;
      _errore = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final clubAsync = ref.watch(currentClubProvider);
    final club = clubAsync.value;
    Widget corpo;
    if (club == null) {
      corpo = Center(
        child: clubAsync.isLoading
            ? const CircularProgressIndicator()
            : Text(
                clubAsync.hasError
                    ? messaggioErrore(clubAsync.error!)
                    : 'Non fai ancora parte di nessun club.',
                textAlign: TextAlign.center,
                style: AppTypography.corpo.copyWith(
                  color: context.colori.testoSecondario,
                ),
              ),
      );
    } else if (_fase == _Fase.pronto) {
      corpo = _Pronto(
        numeroBiglietti: _numeroBiglietti,
        mancanti: _mancanti,
        scadenza: _scadenza!,
        onStampa: _stampa,
        onScarica: _scarica,
        onAltroFoglio: _altroFoglio,
      );
    } else {
      corpo = _costruisciScelta(club);
    }
    return AppScaffold(
      appBar: AppBar(title: const Text('Foglio dei codici')),
      body: corpo,
    );
  }

  Widget _costruisciScelta(Club club) {
    final colori = context.colori;
    final gruppi = ref.watch(gruppiListProvider(club.id)).value ?? const [];
    final atletiAsync = ref.watch(
      atletiListProvider((clubId: club.id, includeInactive: false)),
    );
    final atleti = atletiAsync.value;
    if (atleti == null) {
      return Center(
        child: atletiAsync.hasError
            ? Text(messaggioErrore(atletiAsync.error!))
            : const CircularProgressIndicator(),
      );
    }

    final candidati = _candidati(atleti);
    final senzaAccount = [
      for (final a in candidati)
        if (!a.haAccountCollegato) a,
    ];
    final conAccount = candidati.length - senzaAccount.length;
    final scelti = [
      for (final a in senzaAccount)
        if (!_esclusi.contains(a.id)) a,
    ];
    final nomiSquadre = {for (final g in gruppi) g.id: g.nome};
    final inCreazione = _fase == _Fase.creazione;
    final n = scelti.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
              if (widget.soloAtletaIds == null && gruppi.isNotEmpty) ...[
                Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s8,
                  children: [
                    TonalChip(
                      etichetta: 'Tutto il club',
                      selezionato: _gruppoScelto == null,
                      onSelezionato: inCreazione
                          ? null
                          : (_) => setState(() {
                              _gruppoScelto = null;
                              _esclusi.clear();
                            }),
                    ),
                    for (final g in gruppi)
                      TonalChip(
                        etichetta: g.nome,
                        selezionato: _gruppoScelto == g.id,
                        onSelezionato: inCreazione
                            ? null
                            : (_) => setState(() {
                                _gruppoScelto = g.id;
                                _esclusi.clear();
                              }),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s16),
              ],
              Text(
                'Ogni codice vale 30 giorni e si usa una volta sola. I codici '
                'dei fogli fatti prima per questi atleti non valgono più.',
                style: AppTypography.corpo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
              if (conAccount > 0) ...[
                const SizedBox(height: AppSpacing.s8),
                Text(
                  conAccount == 1
                      ? '1 ha già l\'account: non serve il codice.'
                      : '$conAccount hanno già l\'account: non serve il '
                            'codice.',
                  style: AppTypography.corpo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.s16),
              if (senzaAccount.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s24),
                  child: Text(
                    'Nessun atleta senza account qui: non c\'è niente da '
                    'stampare.',
                    textAlign: TextAlign.center,
                    style: AppTypography.corpo.copyWith(color: colori.testo),
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Senza account: ${senzaAccount.length}',
                        style: AppTypography.corpoForte.copyWith(
                          color: colori.testo,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: inCreazione
                          ? null
                          : () => setState(() => _esclusi.clear()),
                      child: const Text('Tutti'),
                    ),
                    TextButton(
                      onPressed: inCreazione
                          ? null
                          : () => setState(
                              () => _esclusi.addAll(
                                senzaAccount.map((a) => a.id),
                              ),
                            ),
                      child: const Text('Nessuno'),
                    ),
                  ],
                ),
                // Material e non un riquadro colorato: le righe sono
                // ListTile e dipingono il loro fondo sul Material sopra.
                Material(
                  color: colori.superficie,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pannello),
                    side: BorderSide(color: colori.linea),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < senzaAccount.length; i++) ...[
                        _rigaAtleta(
                          senzaAccount[i],
                          squadra: nomiSquadre[senzaAccount[i].gruppoId],
                          inCreazione: inCreazione,
                        ),
                        if (i != senzaAccount.length - 1)
                          Divider(color: colori.linea, height: 1),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.s16),
            ],
          ),
        ),
        if (_errore != null) ...[
          ErrorBanner(messaggio: _errore!),
          const SizedBox(height: AppSpacing.s8),
        ],
        const SizedBox(height: AppSpacing.s8),
        PrimaryButton(
          label: n == 1
              ? 'Crea il foglio (1 biglietto)'
              : 'Crea il foglio ($n biglietti)',
          isLoading: inCreazione,
          onPressed: (n == 0 || inCreazione)
              ? null
              : () => _crea(club: club, scelti: scelti, gruppi: gruppi),
        ),
      ],
    );
  }

  Widget _rigaAtleta(
    Atleta a, {
    required String? squadra,
    required bool inCreazione,
  }) {
    final colori = context.colori;
    return CheckboxListTile(
      value: !_esclusi.contains(a.id),
      onChanged: inCreazione
          ? null
          : (v) => setState(() {
              if (v ?? false) {
                _esclusi.remove(a.id);
              } else {
                _esclusi.add(a.id);
              }
            }),
      title: Text(
        a.nomeCompleto,
        style: AppTypography.corpo.copyWith(color: colori.testo),
      ),
      subtitle: squadra == null
          ? null
          : Text(
              squadra,
              style: AppTypography.piccolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
    );
  }
}

/// "Under 14" → "under_14": un nome di file senza spazi né accenti.
String _perNomeFile(String testo) {
  const accentate = 'àáâäèéêëìíîïòóôöùúûü';
  const semplici = 'aaaaeeeeiiiioooouuuu';
  final buffer = StringBuffer();
  for (final c in testo.toLowerCase().split('')) {
    final i = accentate.indexOf(c);
    buffer.write(i >= 0 ? semplici[i] : c);
  }
  final pulito = buffer
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return pulito.isEmpty ? 'club' : pulito;
}

class _Pronto extends StatelessWidget {
  const _Pronto({
    required this.numeroBiglietti,
    required this.mancanti,
    required this.scadenza,
    required this.onStampa,
    required this.onScarica,
    required this.onAltroFoglio,
  });

  final int numeroBiglietti;
  final int mancanti;
  final DateTime scadenza;
  final VoidCallback onStampa;
  final VoidCallback onScarica;
  final VoidCallback onAltroFoglio;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final biglietti = numeroBiglietti == 1
        ? '1 biglietto'
        : '$numeroBiglietti biglietti';
    return ListView(
      children: [
        Icon(Icons.check_circle_outline, size: 48, color: colori.azione),
        const SizedBox(height: AppSpacing.s16),
        Text(
          'Foglio pronto: $biglietti, validi fino al ${dataNumerica(scadenza)}',
          textAlign: TextAlign.center,
          style: AppTypography.titolo.copyWith(color: colori.testo),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Stampalo e ritaglia i biglietti lungo le linee tratteggiate, '
          'oppure scaricalo e mandalo alle famiglie.',
          textAlign: TextAlign.center,
          style: AppTypography.corpo.copyWith(color: colori.testoSecondario),
        ),
        if (mancanti > 0) ...[
          const SizedBox(height: AppSpacing.s12),
          Text(
            mancanti == 1
                ? 'Per 1 atleta il codice non è stato creato: nel frattempo '
                      'ha collegato l\'account.'
                : 'Per $mancanti atleti il codice non è stato creato: nel '
                      'frattempo hanno collegato l\'account.',
            textAlign: TextAlign.center,
            style: AppTypography.corpo.copyWith(color: colori.testo),
          ),
        ],
        const SizedBox(height: AppSpacing.s24),
        PrimaryButton(label: 'Stampa', icon: Icons.print, onPressed: onStampa),
        const SizedBox(height: AppSpacing.s12),
        SecondaryButton(
          label: 'Scarica il PDF',
          icon: Icons.download,
          onPressed: onScarica,
        ),
        const SizedBox(height: AppSpacing.s24),
        Text(
          'Tienilo finché non l\'hai stampato o mandato: se esci da questa '
          'pagina, per averlo di nuovo serve un foglio nuovo.',
          textAlign: TextAlign.center,
          style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
        ),
        const SizedBox(height: AppSpacing.s12),
        Center(
          child: TextButton(
            onPressed: onAltroFoglio,
            child: const Text('Fai un altro foglio'),
          ),
        ),
        Text(
          'Un altro foglio con gli stessi atleti sostituisce questo: i '
          'codici di questo foglio non varranno più.',
          textAlign: TextAlign.center,
          style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
        ),
      ],
    );
  }
}
