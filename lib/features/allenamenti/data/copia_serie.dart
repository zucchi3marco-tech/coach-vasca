import '../domain/serie.dart';
import 'serie_repository.dart';

extension CopiaSerie on SerieRepository {
  /// Copia [s] con tutti i suoi dati (blocco, ripetute, distanza o durata,
  /// stile, esecuzione, zona, passo, recuperi, ripartenza, attrezzatura,
  /// note, per chi è) nell'allenamento [allenamentoId], in posizione
  /// [ordine]. Mai l'esito (fatta/saltata): una copia non è ancora fatta.
  ///
  /// L'id del gruppo ([piramideId]) e quello del momento in parallelo
  /// ([momentoId]) li sceglie chi copia: le righe di uno stesso gruppo ne
  /// devono avere uno nuovo e uguale. Senza [destinatari] la copia resta
  /// per chi era l'originale.
  ///
  /// Un campo nuovo di `Serie` si aggiunge qui e basta: è l'unico punto
  /// in cui si copia una serie, e `test/numeri/copie_complete_test.dart`
  /// fallisce se una colonna nuova non è stata decisa.
  Future<Serie> copiaSerie(
    Serie s, {
    required String allenamentoId,
    required int ordine,
    required String? piramideId,
    required String? momentoId,
    Destinatari? destinatari,
  }) {
    return createSerie(
      allenamentoId: allenamentoId,
      ordine: ordine,
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
      piramideId: piramideId,
      recuperoDopoS: s.recuperoDopoS,
      destinatari: destinatari ?? s.destinatari,
      momentoId: momentoId,
    );
  }
}
