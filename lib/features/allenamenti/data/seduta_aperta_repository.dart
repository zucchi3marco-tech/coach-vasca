import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';

/// Chi ha aperta una seduta adesso.
typedef ApertaDa = ({String nome, DateTime dal});

/// Come sta una seduta sul server (funzione `seduta_aperta`): la sua
/// versione, chi l'ha cambiata per ultimo e chi altro la sta guardando.
class StatoSeduta {
  const StatoSeduta({
    required this.versione,
    this.cambiataNome,
    this.cambiataAt,
    this.cambiataDaMe = false,
    this.altri = const [],
  });

  factory StatoSeduta.fromMap(Map<String, dynamic> m) => StatoSeduta(
    versione: (m['versione'] as num? ?? 0).toInt(),
    cambiataNome: m['cambiata_nome'] as String?,
    cambiataAt: m['cambiata_at'] == null
        ? null
        : DateTime.parse(m['cambiata_at'] as String).toLocal(),
    cambiataDaMe: m['cambiata_da_me'] as bool? ?? false,
    altri: [
      for (final a in (m['altri'] as List? ?? const []))
        if (a is Map)
          (
            nome: (a['nome'] as String?) ?? 'Un allenatore',
            dal: DateTime.parse(a['dal'] as String).toLocal(),
          ),
    ],
  );

  final int versione;
  final String? cambiataNome;
  final DateTime? cambiataAt;
  final bool cambiataDaMe;
  final List<ApertaDa> altri;

  /// Rispetto alla versione che il telefono ha letto ([letta]), qualcun
  /// altro l'ha cambiata. Una modifica mia (anche da un altro telefono)
  /// non conta; senza una versione letta non si sa: no.
  bool cambiataDaUnAltro(int? letta) =>
      letta != null && versione != letta && !cambiataDaMe;
}

/// La seduta aperta da un collega (problema 6 del «Piano di
/// WaterTactics»). Solo con la rete e mai bloccante: se il server non
/// risponde, l'app fa come prima (null).
class SedutaApertaRepository {
  SedutaApertaRepository(this._client);

  final SupabaseClient? _client;

  /// «Ho aperta questa seduta»; da chiamare all'apertura e poi ogni
  /// minuto.
  Future<StatoSeduta?> apri(String allenamentoId) async {
    final client = _client;
    if (client == null) return null;
    try {
      final risposta = await client
          .rpc('seduta_aperta', params: {'p_allenamento_id': allenamentoId})
          .timeout(const Duration(seconds: 8));
      return risposta is Map
          ? StatoSeduta.fromMap(Map<String, dynamic>.from(risposta))
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> chiudi(String allenamentoId) async {
    final client = _client;
    if (client == null) return;
    try {
      await client
          .rpc('seduta_chiusa', params: {'p_allenamento_id': allenamentoId})
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }
}

final sedutaApertaRepositoryProvider = Provider<SedutaApertaRepository>((ref) {
  SupabaseClient? client;
  try {
    client = ref.watch(supabaseClientProvider);
  } catch (_) {
    // Senza Supabase (le prove, la demo): nessun avviso.
  }
  return SedutaApertaRepository(client);
});

/// La versione di ogni seduta che il telefono ha letto dal server l'ultima
/// volta (chiave: id della seduta): è quella su cui si sta lavorando.
final versioniLetteProvider = Provider<Map<String, int>>((ref) => {});
