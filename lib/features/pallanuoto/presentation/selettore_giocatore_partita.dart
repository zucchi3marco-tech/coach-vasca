import '../../atleti/domain/atleta.dart';
import '../domain/distinta_giocatore.dart';

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
