import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/cap_badge.dart';
import '../../atleti/domain/atleta.dart';
import '../data/distinta_repository.dart';
import '../domain/distinta_giocatore.dart';
import '../domain/partita.dart';

/// Il colore della calottina di un convocato: rossa per il portiere, poi
/// quella della squadra (blu o bianca).
CapColore coloreCalottinaDi(Partita partita, DistintaGiocatore giocatore) {
  if (giocatore.portiere) return CapColore.rossaPortiere;
  return partita.coloreCalottina == 'blu' ? CapColore.blu : CapColore.bianca;
}

/// Il nome di un convocato come si legge in distinta.
String nomeConvocato(DistintaGiocatore giocatore, Map<String, Atleta> atleti) =>
    atleti[giocatore.atletaId]?.nomeCompleto ?? 'Atleta rimosso';

/// Il segno della fascia al braccio: un cerchio piccolo con la C del
/// capitano o la V del vice, da mettere accanto alla calottina.
class SegnoFascia extends StatelessWidget {
  const SegnoFascia.capitano({super.key}) : _lettera = 'C', _nome = 'Capitano';

  const SegnoFascia.vice({super.key}) : _lettera = 'V', _nome = 'Vice capitano';

  final String _lettera;
  final String _nome;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    // Cresce con la dimensione del testo, così la lettera sta sempre dentro.
    final lato = MediaQuery.textScalerOf(context).scale(18);
    return Semantics(
      label: _nome,
      excludeSemantics: true,
      child: Container(
        width: lato,
        height: lato,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colori.azioneTenue,
          shape: BoxShape.circle,
          border: Border.all(color: colori.azione),
        ),
        child: Text(
          _lettera,
          style: AppTypography.etichetta.copyWith(
            color: colori.azione,
            fontWeight: FontWeight.w600,
            height: 1,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

enum _Ruolo { capitano, vice }

/// La risposta del foglio: l'id della riga scelta, o null per "Nessuno".
/// (Chiudere il foglio senza scegliere non dà nessuna risposta.)
class _Scelta {
  const _Scelta(this.id);

  final String? id;
}

/// Capitano e vice della partita: due righe da toccare, ognuna apre
/// l'elenco dei convocati. Cambia i due ruoli insieme, così scegliere un
/// capitano nuovo toglie il vecchio senza errori.
class CapitaniDistinta extends ConsumerWidget {
  const CapitaniDistinta({
    required this.partita,
    required this.convocati,
    required this.atletiPerId,
    super.key,
  });

  final Partita partita;
  final List<DistintaGiocatore> convocati;
  final Map<String, Atleta> atletiPerId;

  DistintaGiocatore? get _capitano =>
      convocati.where((g) => g.capitano).firstOrNull;

  DistintaGiocatore? get _vice =>
      convocati.where((g) => g.viceCapitano).firstOrNull;

  Future<void> _scegli(
    BuildContext context,
    WidgetRef ref,
    _Ruolo ruolo,
  ) async {
    final repository = ref.read(distintaRepositoryProvider);
    final capitano = _capitano;
    final vice = _vice;
    final inOrdine = [...convocati]
      ..sort((a, b) => a.numeroCalottina.compareTo(b.numeroCalottina));

    final scelta = await showModalBottomSheet<_Scelta>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _FoglioScelta(
        titolo: ruolo == _Ruolo.capitano
            ? 'Chi è il capitano?'
            : 'Chi è il vice?',
        partita: partita,
        convocati: inOrdine,
        atletiPerId: atletiPerId,
        idAttuale: (ruolo == _Ruolo.capitano ? capitano : vice)?.id,
        idAltroRuolo: (ruolo == _Ruolo.capitano ? vice : capitano)?.id,
        nomeAltroRuolo: ruolo == _Ruolo.capitano ? 'vice' : 'capitano',
      ),
    );
    if (scelta == null) return;

    // L'altro ruolo resta com'è, a meno che sia la stessa persona: una
    // persona sola non può essere capitano e vice.
    final nuovo = scelta.id;
    final String? nuovoCapitano;
    final String? nuovoVice;
    if (ruolo == _Ruolo.capitano) {
      nuovoCapitano = nuovo;
      nuovoVice = vice?.id == nuovo ? null : vice?.id;
    } else {
      nuovoVice = nuovo;
      nuovoCapitano = capitano?.id == nuovo ? null : capitano?.id;
    }
    if (nuovoCapitano == capitano?.id && nuovoVice == vice?.id) return;

    try {
      await repository.scegliCapitani(
        partita.id,
        capitanoId: nuovoCapitano,
        viceId: nuovoVice,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (convocati.isEmpty) return const SizedBox.shrink();
    final capitano = _capitano;
    final vice = _vice;
    return AppListPanel(
      righe: [
        _RigaFascia(
          segno: const SegnoFascia.capitano(),
          etichetta: 'Capitano',
          nome: capitano == null ? null : nomeConvocato(capitano, atletiPerId),
          onTap: () => _scegli(context, ref, _Ruolo.capitano),
        ),
        _RigaFascia(
          segno: const SegnoFascia.vice(),
          etichetta: 'Vice capitano',
          nome: vice == null ? null : nomeConvocato(vice, atletiPerId),
          onTap: () => _scegli(context, ref, _Ruolo.vice),
        ),
      ],
    );
  }
}

class _RigaFascia extends StatelessWidget {
  const _RigaFascia({
    required this.segno,
    required this.etichetta,
    required this.nome,
    required this.onTap,
  });

  final Widget segno;
  final String etichetta;

  /// Null se il ruolo non è assegnato.
  final String? nome;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.altezzaMinimaRiga,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s8,
          ),
          child: Row(
            children: [
              ExcludeSemantics(child: segno),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      etichetta,
                      style: AppTypography.piccolo.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                    Text(
                      nome ?? 'Scegli',
                      style: AppTypography.corpoForte.copyWith(
                        color: nome == null ? colori.azione : colori.testo,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Icon(Icons.chevron_right, color: colori.testoTenue),
            ],
          ),
        ),
      ),
    );
  }
}

/// L'elenco dei convocati in ordine di numero, con "Nessuno" in cima.
class _FoglioScelta extends StatelessWidget {
  const _FoglioScelta({
    required this.titolo,
    required this.partita,
    required this.convocati,
    required this.atletiPerId,
    required this.idAttuale,
    required this.idAltroRuolo,
    required this.nomeAltroRuolo,
  });

  final String titolo;
  final Partita partita;
  final List<DistintaGiocatore> convocati;
  final Map<String, Atleta> atletiPerId;

  /// La riga che ha oggi questo ruolo, e quella che ha l'altro.
  final String? idAttuale;
  final String? idAltroRuolo;
  final String nomeAltroRuolo;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s24,
            0,
            AppSpacing.s24,
            AppSpacing.s8,
          ),
          child: Text(
            titolo,
            style: AppTypography.sezione.copyWith(color: colori.testo),
          ),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: AppSpacing.s16),
            children: [
              _VoceFoglio(
                scelta: idAttuale == null,
                guida: ExcludeSemantics(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.person_off_outlined,
                      color: colori.testoSecondario,
                    ),
                  ),
                ),
                nome: 'Nessuno',
                onTap: () => Navigator.of(context).pop(const _Scelta(null)),
              ),
              for (final g in convocati)
                _VoceFoglio(
                  scelta: g.id == idAttuale,
                  guida: CapBadge(
                    numero: g.numeroCalottina,
                    colore: coloreCalottinaDi(partita, g),
                  ),
                  nome: nomeConvocato(g, atletiPerId),
                  nota: g.id == idAltroRuolo
                      ? 'Ora è il $nomeAltroRuolo'
                      : null,
                  onTap: () => Navigator.of(context).pop(_Scelta(g.id)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VoceFoglio extends StatelessWidget {
  const _VoceFoglio({
    required this.scelta,
    required this.guida,
    required this.nome,
    required this.onTap,
    this.nota,
  });

  final bool scelta;
  final Widget guida;
  final String nome;
  final String? nota;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Semantics(
      selected: scelta,
      child: Material(
        color: scelta ? colori.azioneTenue : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.altezzaMinimaRiga,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s24,
                vertical: AppSpacing.s8,
              ),
              child: Row(
                children: [
                  guida,
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome,
                          style: AppTypography.corpoForte.copyWith(
                            color: colori.testo,
                          ),
                        ),
                        if (nota != null)
                          Text(
                            nota!,
                            style: AppTypography.piccolo.copyWith(
                              color: colori.testoSecondario,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (scelta) ...[
                    const SizedBox(width: AppSpacing.s8),
                    Icon(Icons.check, color: colori.azione),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
