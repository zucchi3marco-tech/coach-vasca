import 'package:flutter/widgets.dart';

/// Chiave del Navigator dell'app. Serve alla barra fissa in alto, che sta
/// sopra il Navigator (nel `builder` di `MaterialApp`) e quindi non ha un
/// Navigator fra i suoi antenati: per chiudere le schermate aperte, aprirne
/// una o mostrare un menu/dialogo passa da qui.
final navigatorKeyApp = GlobalKey<NavigatorState>();

/// Un contesto che sta sotto il Navigator (quello dell'overlay), per
/// `showMenu`/`showDialog` lanciati dalla barra fissa. Null se il
/// Navigator non è ancora montato.
BuildContext? contestoNavigatorApp() =>
    navigatorKeyApp.currentState?.overlay?.context;
