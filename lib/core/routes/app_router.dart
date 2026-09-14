// =============================================================================
// Projeto    : Treinix – Treinador Digital para Atletas Amadores
// Arquivo    : lib/core/routes/app_router.dart
// Camada     : Roteamento – GoRouter
// Descrição  : Definição de todas as rotas da aplicação com ShellRoute para
//              manter a NavigationBar visível nas telas principais.
//  
//              Rotas que devem ser abertas sem a bottom nav mas que são
//              acessadas VIA context.push() de dentro do ShellRoute usam
//              parentNavigatorKey: _rootKey — padrão canônico do GoRouter
//              para "escapar" do navigator do shell mantendo o contexto certo.
// -----------------------------------------------------------------------------
// Autor      : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso      : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano        : 2026
// =============================================================================

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';
import '../../data/models/training_model.dart';
import '../../data/models/user_model.dart';
import '../../ui/auth/login_screen.dart';
import '../../ui/auth/register_screen.dart';
import '../../ui/auth/reset_password_screen.dart';
import '../../ui/home/main_navigation.dart';
import '../../ui/home/home_screen.dart';
import '../../ui/misc/about_screen.dart';
import '../../ui/misc/glossary_screen.dart';
import '../../ui/misc/pace_calculator_screen.dart';
import '../../ui/onboarding/onboarding_screen.dart';
import '../../ui/profile/privacy_screen.dart';
import '../../ui/profile/profile_screen.dart';
import '../../ui/settings/settings_screen.dart';
import '../../ui/stats/stats_screen.dart';
import '../../ui/suggestion/suggestion_screen.dart';
import '../../ui/training/history_log_screen.dart';
import '../../ui/training/log_training_screen.dart';
import '../../ui/training/plan_detail_screen.dart';
import '../../ui/training/training_history_screen.dart';
import '../../ui/training/training_detail_screen.dart';
import '../../ui/training/training_session_screen.dart';

/// Notifica o GoRouter toda vez que o estado de autenticação Firebase muda,
/// garantindo que o redirect seja reavaliado (ex: restauração de sessão).
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh() {
    _sub = FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }
  late final StreamSubscription<User?> _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class AppRouter {
  static final _rootKey    = GlobalKey<NavigatorState>();
  static final _authRefresh = _AuthRefresh();

  static final router = GoRouter(
    navigatorKey:      _rootKey,
    refreshListenable: _authRefresh,
    initialLocation: '/login',
    redirect: (context, state) {
      final auth     = context.read<AuthViewModel>();
      final loggedIn = auth.isLoggedIn;
      final loc      = state.matchedLocation;

      final onAuth   = loc == '/login' || loc == '/register' || loc == '/reset-password';
      final onPublic = loc == '/privacy';

      if (!loggedIn && !onAuth && !onPublic) return '/login';
      if (loggedIn && onAuth) return '/home';
      return null;
    },
    routes: [

      // ── Autenticação ──────────────────────────────────────────────────────
      GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/reset-password', builder: (_, __) => const ResetPasswordScreen()),

      // ── Onboarding ────────────────────────────────────────────────────────
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),

      // ── App principal com BottomNav (ShellRoute) ──────────────────────────
      ShellRoute(
        builder: (_, __, child) => MainNavigation(child: child),
        routes: [

          // Abas da NavigationBar inferior
          GoRoute(path: '/home',       builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/history',    builder: (_, __) => const TrainingHistoryScreen()),
          GoRoute(path: '/suggestion', builder: (_, __) => const SuggestionScreen()),
          GoRoute(
            path: '/log-training',
            builder: (_, state) => LogTrainingScreen(
              existingPlan: state.extra as TrainingPlanModel?,
            ),
          ),

          // Subrotas dentro do shell (mantêm bottom nav)
          GoRoute(
            path: '/training/:modality',
            builder: (_, state) {
              final m = Modality.values.firstWhere(
                (e) => e.name == state.pathParameters['modality'],
                orElse: () => Modality.corrida,
              );
              return TrainingSessionScreen(
                modality: m,
                plan:     state.extra as TrainingPlanModel?,
              );
            },
          ),
          GoRoute(
            path: '/plan-detail',
            builder: (_, state) {
              final plan = state.extra as TrainingPlanModel?;
              if (plan == null) return const TrainingHistoryScreen();
              return PlanDetailScreen(plan: plan);
            },
          ),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),

          // ── Rotas do menu ⋮ — dentro do shell (mesmo padrão do Perfil) ──────
          GoRoute(path: '/history-log',      builder: (_, __) => const HistoryLogScreen()),
          GoRoute(
            path: '/training-detail',
            builder: (_, state) {
              final training = state.extra as TrainingModel?;
              if (training == null) return const HistoryLogScreen();
              return TrainingDetailScreen(training: training);
            },
          ),
          GoRoute(path: '/stats',            builder: (_, __) => const StatsScreen()),
          GoRoute(path: '/settings',         builder: (_, __) => const SettingsScreen()),
          GoRoute(path: '/about',            builder: (_, __) => const AboutScreen()),
          GoRoute(path: '/privacy',          builder: (_, __) => const PrivacyScreen()),
          GoRoute(path: '/glossary',         builder: (_, __) => const GlossaryScreen()),
          GoRoute(path: '/pace-calculator',  builder: (_, __) => const PaceCalculatorScreen()),
        ],
      ),
    ],
  );
}
