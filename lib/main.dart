import 'package:flutter/material.dart';

import 'core/services/supabase_service.dart';
import 'features/polar/polar_heart_rate_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();

  runApp(const PotsApp());
}

class PotsApp extends StatelessWidget {
  const PotsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pots Polar Monitor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PolarHeartRatePage(),
    );
  }
}
