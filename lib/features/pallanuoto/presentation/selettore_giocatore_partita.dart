import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/cap_badge.dart';
import '../../atleti/domain/atleta.dart';
import '../domain/distinta_giocatore.dart';
import '../domain/partita.dart';

/// Identità di un giocatore ai fini della griglia e delle squalifiche: un
/// nostro convocato (via `atletaId`, ha una rubrica) o un avversario (via
/// numero di calottina, l'unico dato che abbiamo di lui — niente nome).
sealed class GiocatorePartitaId {
  const GiocatorePartitaId();
}

class NostroGiocatoreId extends GiocatorePartitaId {
  const NostroGiocatoreId(this.atletaId);

  final String atletaId;

  @override
  bool operator ==(Object other) =>
      other is NostroGiocatoreId && other.atletaId == atletaId;

  @override
  int get hashCode => Object.hash(NostroGiocatoreId, atletaId);
}

class AvversarioGiocatoreId extends GiocatorePartitaId {
  const AvversarioGiocatoreId(this.numeroCalottina);

  final int numeroCalottina;

  @override
  bool operator ==(Object other) =>
      other is AvversarioGiocatoreId &&
      other.numeroCalottina == numeroCalottina;

  @override
  int get hashCode => Object.hash(AvversarioGiocatoreId, numeroCalottina);
}

typedef ConvocatoConAtleta = ({DistintaGiocatore giocatore, Atleta atleta});

/// Griglia di bersagli grandi (≥64px, DESIGN.md sezione 9) per scegliere
/// un giocatore, al posto del menu a tendina: squadra di casa a sinistra,
/// squadra fuori casa a destra, indipendentemente da quale delle due
/// siamo noi. Il nostro lato mostra i convocati veri (numero + nome);
/// l'altro, quando abilitato, mostra solo i numeri (non abbiamo la
/// rubrica avversaria).
class SelettoreGiocatorePartita extends StatelessWidget {
  const SelettoreGiocatorePartita({
    required this.partita,
    required this.convocati,
    required this.onSelezionatoNostro,
    this.mostraAvversari = false,
    this.onSelezionatoAvversario,
    this.disqualificati = const {},
    super.key,
  }) : assert(
         !mostraAvversari || onSelezionatoAvversario != null,
         'onSelezionatoAvversario è obbligatorio quando mostraAvversari è '
         'true',
       );

  final Partita partita;
  final List<ConvocatoConAtleta> convocati;
  final ValueChanged<String> onSelezionatoNostro;
  final bool mostraAvversari;
  final ValueChanged<int>? onSelezionatoAvversario;
  final Set<GiocatorePartitaId> disqualificati;

  @override
  Widget build(BuildContext context) {
    final nostraCasa = partita.nostraSquadra == 'casa';
    final convocatiOrdinati = [...convocati]..sort(
      (a, b) =>
          a.giocatore.numeroCalottina.compareTo(b.giocatore.numeroCalottina),
    );

    final colonnaNostra = _ColonnaNostra(
      etichetta: nostraCasa ? partita.squadraCasa : partita.squadraTrasferta,
      convocati: convocatiOrdinati,
      disqualificati: disqualificati,
      onSelezionato: onSelezionatoNostro,
    );

    if (!mostraAvversari) return colonnaNostra;

    final colonnaAvversaria = _ColonnaAvversaria(
      etichetta: nostraCasa ? partita.squadraTrasferta : partita.squadraCasa,
      numeroMax: partita.numeroMaxConvocati,
      disqualificati: disqualificati,
      onSelezionato: onSelezionatoAvversario!,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: nostraCasa ? colonnaNostra : colonnaAvversaria),
        const SizedBox(width: AppSpacing.s16),
        Expanded(child: nostraCasa ? colonnaAvversaria : colonnaNostra),
      ],
    );
  }
}

class _ColonnaNostra extends StatelessWidget {
  const _ColonnaNostra({
    required this.etichetta,
    required this.convocati,
    required this.disqualificati,
    required this.onSelezionato,
  });

  final String etichetta;
  final List<ConvocatoConAtleta> convocati;
  final Set<GiocatorePartitaId> disqualificati;
  final ValueChanged<String> onSelezionato;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          etichetta,
          style: AppTypography.sezione,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s12),
        for (final c in convocati) ...[
          _BersaglioGiocatore(
            squalificato: disqualificati.contains(
              NostroGiocatoreId(c.atleta.id),
            ),
            onTap: () => onSelezionato(c.atleta.id),
            child: Row(
              children: [
                CapBadge(numero: c.giocatore.numeroCalottina),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Text(
                    c.atleta.nomeCompleto,
                    style: AppTypography.corpoForte,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spazioBersagli),
        ],
      ],
    );
  }
}

class _ColonnaAvversaria extends StatelessWidget {
  const _ColonnaAvversaria({
    required this.etichetta,
    required this.numeroMax,
    required this.disqualificati,
    required this.onSelezionato,
  });

  final String etichetta;
  final int numeroMax;
  final Set<GiocatorePartitaId> disqualificati;
  final ValueChanged<int> onSelezionato;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          etichetta,
          style: AppTypography.sezione,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.spazioBersagli,
          runSpacing: AppSpacing.spazioBersagli,
          children: [
            for (var n = 1; n <= numeroMax; n++)
              _BersaglioNumero(
                numero: n,
                squalificato: disqualificati.contains(
                  AvversarioGiocatoreId(n),
                ),
                onTap: () => onSelezionato(n),
              ),
          ],
        ),
      ],
    );
  }
}

class _BersaglioGiocatore extends StatelessWidget {
  const _BersaglioGiocatore({
    required this.child,
    required this.squalificato,
    required this.onTap,
  });

  final Widget child;
  final bool squalificato;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.altezzaMinimaBersaglioVasca,
      child: Material(
        color: squalificato ? AppColors.testo : AppColors.superficie,
        borderRadius: BorderRadius.circular(AppSpacing.raggioPannello),
        child: InkWell(
          onTap: squalificato ? null : onTap,
          borderRadius: BorderRadius.circular(AppSpacing.raggioPannello),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.raggioPannello),
              border: Border.all(color: AppColors.linea),
            ),
            alignment: Alignment.centerLeft,
            child: squalificato
                ? Text(
                    'Squalificato',
                    style: AppTypography.corpoForte.copyWith(
                      color: Colors.white,
                    ),
                  )
                : child,
          ),
        ),
      ),
    );
  }
}

class _BersaglioNumero extends StatelessWidget {
  const _BersaglioNumero({
    required this.numero,
    required this.squalificato,
    required this.onTap,
  });

  final int numero;
  final bool squalificato;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSpacing.altezzaMinimaBersaglioVasca,
      height: AppSpacing.altezzaMinimaBersaglioVasca,
      child: Material(
        color: squalificato ? AppColors.testo : AppColors.superficie,
        borderRadius: BorderRadius.circular(AppSpacing.raggioControllo),
        child: InkWell(
          onTap: squalificato ? null : onTap,
          borderRadius: BorderRadius.circular(AppSpacing.raggioControllo),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.raggioControllo),
              border: Border.all(color: AppColors.linea),
            ),
            alignment: Alignment.center,
            child: Text(
              '$numero',
              style: AppTypography.titolo.copyWith(
                color: squalificato ? Colors.white : AppColors.testo,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
