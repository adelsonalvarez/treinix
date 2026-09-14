// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/ui/home/main_navigation.dart
// Camada   : Navegação – Shell Principal
// Descrição: NavigationBar inferior com 4 destinos. Mantém a barra visível
//            em todas as rotas do ShellRoute via GoRouter.
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shell de navegação principal.
///
/// Usa [GoRouterState.of(context).uri.path] — que retorna o caminho COMPLETO
/// da rota atual (diferente de matchedLocation, que no ShellRoute sem path
/// explícito retorna string vazia) — garantindo que o índice correto seja
/// selecionado em todos os destinos da barra inferior.
///
/// Barra inferior — 4 destinos:
///   0 Início   → /home
///   1 Treinos  → /history
///   2 Registro → /log-training
///   3 IA       → /suggestion
class MainNavigation extends StatelessWidget {
  final Widget child;
  const MainNavigation({super.key, required this.child});

  static int _computeIndex(String path) {
    // Correspondência exata ou subrota direta de /history (nunca /history-log).
    if (path == '/history' || path.startsWith('/history/')) return 1;
    if (path.startsWith('/plan-detail'))  return 1;
    if (path.startsWith('/log-training')) return 2;
    if (path.startsWith('/suggestion'))   return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _computeIndex(loc),
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/home');
            case 1: context.go('/history');
            case 2: context.go('/log-training');
            case 3: context.go('/suggestion');
          }
        },
        destinations: const [
          NavigationDestination(
            icon:         Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label:        'Início',
          ),
          NavigationDestination(
            icon:         Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label:        'Treinos',
          ),
          NavigationDestination(
            icon:         Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label:        'Registro',
          ),
          NavigationDestination(
            icon:         Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label:        'IA',
          ),
        ],
      ),
    );
  }
}
