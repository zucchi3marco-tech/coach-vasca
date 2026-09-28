import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/pwa/aggiornamento_pwa.dart';
import 'core/pwa/installabilita_pwa.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  avviaOsservazioneInstallabilitaPwa();
  avviaOsservazioneAggiornamentoPwa();
  await dotenv.load();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const ProviderScope(child: CoachVascaApp()));
}
