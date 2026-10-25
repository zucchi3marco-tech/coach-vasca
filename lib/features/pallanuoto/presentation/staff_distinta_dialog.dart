import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/scarica_file.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';
import '../../club/application/current_club_provider.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../gruppi/data/gruppi_repository.dart';
import '../application/pallanuoto_providers.dart';
import '../data/partite_repository.dart';
import '../domain/partita.dart';
import '../domain/staff_distinta.dart';
import '../excel/distinta_excel.dart';

const _mimeXlsx =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// Quanto aspettare un nome (del club, della squadra) prima di farne a
/// meno: serve solo a scrivere meglio il modulo, non deve bloccarlo.
const _attesaNomi = Duration(seconds: 3);

/// Cosa farne del file pronto: scaricarlo nel browser. Dietro un provider
/// perché nei test non c'è un browser, e perché così si può leggere cosa
/// sarebbe stato scaricato.
class AzioniDistinta {
  const AzioniDistinta();

  /// Il download è possibile solo dall'app aperta nel browser.
  bool get disponibile => scaricaFileDisponibile;

  void scarica(Uint8List bytes, String nomeFile) =>
      scaricaFile(bytes, nomeFile, mimeType: _mimeXlsx);
}

final azioniDistintaProvider = Provider<AzioniDistinta>(
  (ref) => const AzioniDistinta(),
);

// ---------------------------------------------------------------------------
// Lo staff da solo (schermata delle squadre)

/// Chiede lo staff del modulo: nome e tessera FIN per ognuno dei cinque
/// ruoli. Dà lo staff nuovo, o `null` se si annulla.
Future<StaffDistinta?> chiediStaffDistinta(
  BuildContext context, {
  required StaffDistinta iniziale,
  required String titolo,
  String? spiegazione,
}) {
  return showDialog<StaffDistinta>(
    context: context,
    builder: (context) => _StaffDialog(
      iniziale: iniziale,
      titolo: titolo,
      spiegazione: spiegazione,
    ),
  );
}

class _StaffDialog extends StatefulWidget {
  const _StaffDialog({
    required this.iniziale,
    required this.titolo,
    this.spiegazione,
  });

  final StaffDistinta iniziale;
  final String titolo;
  final String? spiegazione;

  @override
  State<_StaffDialog> createState() => _StaffDialogState();
}

class _StaffDialogState extends State<_StaffDialog> {
  late final _ControlliStaff _controlli = _ControlliStaff(widget.iniziale);

  @override
  void dispose() {
    _controlli.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      insetPadding: _margineDialog,
      title: Text(widget.titolo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.spiegazione != null) ...[
            _Spiegazione(widget.spiegazione!),
            const SizedBox(height: AppSpacing.s20),
          ],
          _CampiStaff(_controlli),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        PrimaryButton(
          label: 'Salva staff',
          expanded: false,
          onPressed: () => Navigator.of(context).pop(_controlli.valore()),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Il modulo della distinta (dalla distinta della partita)

/// Scarica il modulo della distinta in Excel. Prima chiede lo staff (quello
/// della partita, se l'hanno cambiato per lei, altrimenti quello della
/// squadra) e se tenerlo per tutte le partite della squadra; poi scrive il
/// file e lo scarica. Funziona dall'app aperta nel browser.
Future<void> esportaDistintaExcel(
  BuildContext context,
  WidgetRef ref, {
  required Partita partita,
  required List<ConvocatoModulo> convocati,
}) async {
  final azioni = ref.read(azioniDistintaProvider);
  final avvisi = ScaffoldMessenger.of(context);
  if (!azioni.disponibile) {
    avvisi.showSnackBar(
      const SnackBar(
        content: Text('Il file si scarica dall\'app aperta nel browser.'),
      ),
    );
    return;
  }

  final gruppiRepo = ref.read(gruppiRepositoryProvider);
  final partiteRepo = ref.read(partiteRepositoryProvider);
  final gruppoId = partita.gruppoId;

  final StaffDistinta dellaSquadra;
  final StaffDistinta? dellaPartita;
  try {
    dellaSquadra = gruppoId == null
        ? StaffDistinta.vuoto
        : await gruppiRepo.staffDellaSquadra(gruppoId);
    dellaPartita = await partiteRepo.staffDellaPartita(partita.id);
  } catch (e) {
    if (context.mounted) {
      avvisi.showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
    }
    return;
  }
  if (!context.mounted) return;

  final nomeSquadra = await _nomeSquadra(ref, partita);
  if (!context.mounted) return;

  final cambiatoPerLaPartita = dellaPartita != null;
  final iniziale = dellaPartita ?? dellaSquadra;
  // Se la squadra non ha ancora uno staff, o questa partita non ha il suo,
  // la cosa naturale è tenerlo per la squadra.
  final perTutteDiPartenza =
      gruppoId != null && (dellaSquadra.senzaNessuno || !cambiatoPerLaPartita);

  Future<void> conferma(StaffDistinta staff, bool perTutte) async {
    if (gruppoId != null && perTutte) {
      if (staff != dellaSquadra) {
        await gruppiRepo.aggiornaStaffDellaSquadra(gruppoId, staff);
      }
      if (cambiatoPerLaPartita) {
        await partiteRepo.aggiornaStaffDellaPartita(partita.id, null);
      }
    } else {
      final soloQuesta = staff == dellaSquadra ? null : staff;
      if (soloQuesta != dellaPartita) {
        await partiteRepo.aggiornaStaffDellaPartita(partita.id, soloQuesta);
      }
    }
    if (!context.mounted) return;
    ref.invalidate(
      staffDistintaProvider((partitaId: partita.id, gruppoId: gruppoId)),
    );

    final nomeClub = await _nomeClub(ref);
    final bytes = generaDistintaExcel(
      partita: partita,
      nomeClub: nomeClub,
      nomeSquadra: nomeSquadra,
      convocati: convocati,
      staff: staff,
    );
    final nomeFile = nomeFileDistinta(partita);
    azioni.scarica(bytes, nomeFile);
    avvisi.showSnackBar(
      SnackBar(content: Text('File Excel scaricato: $nomeFile')),
    );
  }

  await showDialog<void>(
    context: context,
    builder: (context) => _ModuloDialog(
      iniziale: iniziale,
      nomeSquadra: nomeSquadra,
      conInterruttore: gruppoId != null,
      perTutteDiPartenza: perTutteDiPartenza,
      conferma: conferma,
    ),
  );
}

/// Legge un dato tenendolo in ascolto fino a quando arriva: con Riverpod 3
/// un dato che nessuno ascolta resta in pausa. `null` se non arriva in
/// tempo o dà errore.
Future<T?> _leggi<T>(
  WidgetRef ref,
  ProviderListenable<Future<T>> futuro,
) async {
  final ascolto = ref.listenManual(futuro, (_, _) {});
  try {
    return await ascolto.read().timeout(_attesaNomi);
  } catch (_) {
    return null;
  } finally {
    ascolto.close();
  }
}

Future<String?> _nomeSquadra(WidgetRef ref, Partita partita) async {
  final gruppoId = partita.gruppoId;
  if (gruppoId == null) return null;
  final gruppi = await _leggi(ref, gruppiListProvider(partita.clubId).future);
  for (final g in gruppi ?? const []) {
    if (g.id == gruppoId) return g.nome;
  }
  return null;
}

Future<String> _nomeClub(WidgetRef ref) async {
  final club = await _leggi(ref, currentClubProvider.future);
  return club?.nome ?? '';
}

class _ModuloDialog extends StatefulWidget {
  const _ModuloDialog({
    required this.iniziale,
    required this.nomeSquadra,
    required this.conInterruttore,
    required this.perTutteDiPartenza,
    required this.conferma,
  });

  final StaffDistinta iniziale;
  final String? nomeSquadra;
  final bool conInterruttore;
  final bool perTutteDiPartenza;

  /// Salva lo staff e scarica il file; se dà errore il dialog lo mostra e
  /// resta aperto.
  final Future<void> Function(StaffDistinta staff, bool perTutte) conferma;

  @override
  State<_ModuloDialog> createState() => _ModuloDialogState();
}

class _ModuloDialogState extends State<_ModuloDialog> {
  late final _ControlliStaff _controlli = _ControlliStaff(widget.iniziale);
  late bool _perTutte = widget.perTutteDiPartenza;
  bool _occupato = false;
  Object? _errore;

  @override
  void dispose() {
    _controlli.dispose();
    super.dispose();
  }

  Future<void> _scarica() async {
    setState(() {
      _occupato = true;
      _errore = null;
    });
    try {
      await widget.conferma(_controlli.valore(), _perTutte);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _occupato = false;
          _errore = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final squadra = widget.nomeSquadra ?? 'questa squadra';
    return PopScope(
      canPop: !_occupato,
      child: AlertDialog(
        scrollable: true,
        insetPadding: _margineDialog,
        title: const Text('Il modulo della distinta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Spiegazione(
              'Lo staff e le tessere che finiscono nel modulo. I giocatori '
              'sono quelli della distinta.',
            ),
            const SizedBox(height: AppSpacing.s20),
            _CampiStaff(_controlli, abilitato: !_occupato),
            if (widget.conInterruttore) ...[
              const SizedBox(height: AppSpacing.s20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Usa per tutte le partite di $squadra',
                  style: AppTypography.corpoForte.copyWith(color: colori.testo),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s4),
                  child: Text(
                    _perTutte
                        ? 'Lo staff si salva per la squadra: alla prossima '
                              'partita lo trovi già scritto.'
                        : 'Vale solo per questa partita. Le altre restano '
                              'come sono.',
                    style: AppTypography.piccolo.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                ),
                value: _perTutte,
                onChanged: _occupato
                    ? null
                    : (valore) => setState(() => _perTutte = valore),
              ),
            ],
            if (_errore != null) ...[
              const SizedBox(height: AppSpacing.s16),
              ErrorBanner(messaggio: messaggioErrore(_errore!)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _occupato ? null : () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          PrimaryButton(
            label: 'Scarica il file Excel',
            expanded: false,
            isLoading: _occupato,
            onPressed: _occupato ? null : _scarica,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pezzi in comune

/// Il dialog sta largo quasi quanto un telefono stretto: con il testo
/// ingrandito i campi devono avere posto.
const _margineDialog = EdgeInsets.symmetric(
  horizontal: AppSpacing.s16,
  vertical: AppSpacing.s24,
);

class _Spiegazione extends StatelessWidget {
  const _Spiegazione(this.testo);

  final String testo;

  @override
  Widget build(BuildContext context) {
    return Text(
      testo,
      style: AppTypography.piccolo.copyWith(
        color: context.colori.testoSecondario,
      ),
    );
  }
}

/// I testi dei campi dello staff: nome e tessera per ogni ruolo.
class _ControlliStaff {
  _ControlliStaff(StaffDistinta iniziale)
    : nomi = {
        for (final r in RuoloStaff.values)
          r: TextEditingController(text: iniziale.di(r).nome),
      },
      tessere = {
        for (final r in RuoloStaff.values)
          r: TextEditingController(text: iniziale.di(r).tessera),
      };

  final Map<RuoloStaff, TextEditingController> nomi;
  final Map<RuoloStaff, TextEditingController> tessere;

  /// Lo staff come è scritto adesso; le righe vuote non ci sono.
  StaffDistinta valore() {
    final persone = <RuoloStaff, PersonaStaff>{};
    for (final r in RuoloStaff.values) {
      final persona = PersonaStaff(
        nome: nomi[r]!.text.trim(),
        tessera: tessere[r]!.text.trim(),
      );
      if (!persona.vuota) persone[r] = persona;
    }
    return StaffDistinta(persone);
  }

  void dispose() {
    for (final c in [...nomi.values, ...tessere.values]) {
      c.dispose();
    }
  }
}

/// Un gruppo di due campi per ruolo, con il ruolo come intestazione.
class _CampiStaff extends StatelessWidget {
  const _CampiStaff(this.controlli, {this.abilitato = true});

  final _ControlliStaff controlli;
  final bool abilitato;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, ruolo) in RuoloStaff.values.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.s24),
          Semantics(
            container: true,
            label: ruolo.etichetta,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ruolo.etichetta,
                  style: AppTypography.sezione.copyWith(color: colori.testo),
                ),
                const SizedBox(height: AppSpacing.s12),
                AppTextField(
                  key: ValueKey('staff-${ruolo.chiave}-nome'),
                  etichetta: 'Nome e cognome',
                  controller: controlli.nomi[ruolo],
                  abilitato: abilitato,
                ),
                const SizedBox(height: AppSpacing.spazioCampiForm),
                AppTextField(
                  key: ValueKey('staff-${ruolo.chiave}-tessera'),
                  etichetta: 'Tessera FIN',
                  controller: controlli.tessere[ruolo],
                  keyboardType: TextInputType.number,
                  abilitato: abilitato,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
