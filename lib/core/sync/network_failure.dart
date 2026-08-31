import 'package:http/http.dart' show ClientException;

/// Vero se l'errore indica un problema di rete (offline, richiesta mai
/// arrivata al server) piuttosto che un rifiuto vero del server (RLS,
/// vincoli, dati non validi...). Solo il primo caso va messo in coda per
/// un ritentativo automatico: il secondo va mostrato subito in UI, perche'
/// ritentare non lo risolverebbe.
///
/// `package:http` incapsula in `ClientException` i fallimenti di rete sia
/// su web (fetch) sia sulle piattaforme native, quindi basta questo tipo
/// per coprire tutte le piattaforme senza import condizionali.
bool isNetworkFailure(Object error) => error is ClientException;
