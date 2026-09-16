import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';

/// Schema di redirect per il login Google su Android/iOS (registrato nei
/// manifest nativi — vedi `android/app/.../AndroidManifest.xml` e
/// `ios/Runner/Info.plist`) e come "Redirect URL" aggiuntivo nel
/// dashboard Supabase. Sul web non serve: Supabase reindirizza da solo
/// all'origine del sito configurata li'.
const _redirectOAuthNativo = 'io.supabase.coachvasca://login-callback/';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Apre il login Google (browser di sistema su Android/iOS, redirect
  /// diretto sul web). Vale solo per il coach (FASE 15): login e
  /// creazione account sono la stessa azione, Supabase crea l'utente al
  /// primo accesso se non esiste ancora. La sessione arriva più tardi
  /// tramite `authStateChangesProvider`, non dal Future qui: questo
  /// ritorna solo se il browser si è aperto correttamente.
  Future<void> signInWithGoogle() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : _redirectOAuthNativo,
    );
  }

  /// Se la conferma email e' richiesta dal progetto Supabase, la sessione
  /// restituita e' null finche' l'utente non clicca il link ricevuto via
  /// email: la UI deve gestire entrambi i casi.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> sendPasswordReset(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});
