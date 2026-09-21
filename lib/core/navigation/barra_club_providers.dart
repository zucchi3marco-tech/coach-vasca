import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Quante schermate, in questo momento, chiedono di nascondere la barra
/// fissa in alto (lavagna tattica, partita dal vivo, bordo vasca...): la
/// barra è visibile solo a 0. Un contatore e non un booleano perché due
/// schermate possono sovrapporsi (una sull'altra) durante una navigazione.
class BarraClubNascostaNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void incrementa() => state = state + 1;

  void decrementa() => state = state > 0 ? state - 1 : 0;
}

final barraClubNascostaProvider =
    NotifierProvider<BarraClubNascostaNotifier, int>(
      BarraClubNascostaNotifier.new,
    );

/// La tab selezionata nella home dell'allenatore: sta in un provider (non
/// nello stato di HomeScreen) perché il logo della barra fissa, che sta
/// fuori da HomeScreen, deve poter tornare alla prima tab.
class TabHomeNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void imposta(int indice) => state = indice;
}

final tabHomeProvider = NotifierProvider<TabHomeNotifier, int>(
  TabHomeNotifier.new,
);
