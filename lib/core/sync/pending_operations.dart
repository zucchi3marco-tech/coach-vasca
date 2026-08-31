import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// Accoda una scrittura non riuscita per un problema di rete, da ritentare
/// quando torna la connessione. Usato dai repository come fallback quando
/// la chiamata a Supabase fallisce con [isNetworkFailure].
Future<void> enqueueOperation(
  AppDatabase db, {
  required String tabella,
  required String operazione,
  required String rigaId,
  Object? payload,
}) {
  return db
      .into(db.pendingOperationsTable)
      .insert(
        PendingOperationsTableCompanion.insert(
          tabella: tabella,
          operazione: operazione,
          rigaId: rigaId,
          payloadJson: Value(payload == null ? null : jsonEncode(payload)),
        ),
      );
}
