// =============================================================================
// Projeto    : Treinix – Treinador Digital para Atletas Amadores
// Arquivo    : lib/main.dart
// Camada     : Entry point da aplicação
// Descrição  : Inicialização do Firebase, locale pt_BR e injeção de dependências
// -----------------------------------------------------------------------------
// Autor      : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso      : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano        : 2026
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/user_viewmodel.dart';
import 'viewmodels/training_viewmodel.dart';
import 'viewmodels/suggestion_viewmodel.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Mantém a splash nativa visível enquanto o app inicializa.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Captura erros de widgets e os exibe no console (evita tela branca silenciosa).
  FlutterError.onError = FlutterError.presentError;

  // Captura erros assíncronos fora do widget tree.
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[Treinix] Erro não tratado: $error\n$stack');
    return true;
  };

  String? firebaseError;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e, st) {
    firebaseError = e.toString();
    debugPrint('[Treinix] Falha ao inicializar Firebase: $e\n$st');
  }

  await initializeDateFormatting('pt_BR', null);

  // Remove a splash nativa — o Flutter engine já está pronto.
  FlutterNativeSplash.remove();

  if (firebaseError != null) {
    runApp(_FirebaseErrorApp(firebaseError));
    return;
  }

  runApp(const TreinixApp());
}

class TreinixApp extends StatelessWidget {
  const TreinixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => UserViewModel()),
        ChangeNotifierProvider(create: (_) => TrainingViewModel()),
        ChangeNotifierProvider(create: (_) => SuggestionViewModel()),
      ],
      child: MaterialApp.router(
        title: 'Treinix',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [
          Locale('pt', 'BR'),
          Locale('en'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: AppRouter.router,
      ),
    );
  }
}

/// Tela de erro mostrada quando o Firebase falha ao inicializar.
/// Exibe a mensagem completa para facilitar o diagnóstico.
class _FirebaseErrorApp extends StatelessWidget {
  final String message;
  const _FirebaseErrorApp(this.message);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Falha ao inicializar Firebase',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                SelectableText(message,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}