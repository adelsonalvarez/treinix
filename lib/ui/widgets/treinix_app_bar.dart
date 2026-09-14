// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/ui/widgets/treinix_app_bar.dart
// Camada   : Widget – AppBar Padrão
// Descrição: AppBar reutilizável com brand "TREINIX", título da tela atual
//            e menu ⋮ com ações globais (perfil, privacidade, sair).
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// AppBar padrão do Treinix.
///
/// Layout:   [TREINIX]   [screenTitle?]   [action?]  [⋮?]
///
/// - [screenTitle]: título da tela atual (nulo = só o brand)
/// - [action]: widget opcional antes do menu (ex.: TextButton "Novo plano")
/// - [bottom]: TabBar opcional abaixo da toolbar
/// - [showAppMenu]: quando true exibe o botão ⋮ com o menu completo do app
class TreinixAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String?              screenTitle;
  final Widget?              action;
  final PreferredSizeWidget? bottom;
  final bool                 showAppMenu;
  /// Quando true substitui "TREINIX" por um BackButton —
  /// ideal para telas abertas via push (sem bottom nav).
  final bool                 showBack;

  const TreinixAppBar({
    super.key,
    this.screenTitle,
    this.action,
    this.bottom,
    this.showAppMenu = false,
    this.showBack    = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(
      kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth: showBack ? kToolbarHeight : 116,
      leading: showBack
          ? BackButton(onPressed: () => Navigator.of(context).pop())
          : const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'TREINIX',
                  style: TextStyle(
                    color:         AppColors.primary,
                    fontWeight:    FontWeight.w900,
                    fontSize:      16,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
            ),
      centerTitle: true,
      title: screenTitle != null
          ? Text(screenTitle!, style: AppTextStyles.heading3)
          : null,
      actions: [
        if (action != null) action!,
        if (showAppMenu) const _AppMenuButton(),
        const SizedBox(width: 4),
      ],
      bottom: bottom,
    );
  }
}

// ─── Botão ⋮ com menu completo ────────────────────────────────────────────────

class _AppMenuButton extends StatelessWidget {
  const _AppMenuButton();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Menu',
      onSelected: (route) => context.push(route),
      itemBuilder: _buildItems,
    );
  }

  // ── Construtores de entradas do menu ───────────────────────────────────────

  static PopupMenuItem<String> _item(
    String label,
    IconData icon,
    String route,
  ) =>
      PopupMenuItem<String>(
        value: route,
        child: Row(children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14)),
        ]),
      );

  static PopupMenuItem<String> _section(String label) => PopupMenuItem<String>(
        enabled: false,
        height:  28,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize:      10,
            fontWeight:    FontWeight.w700,
            color:         AppColors.textTertiary,
            letterSpacing: 1.2,
          ),
        ),
      );

  static List<PopupMenuEntry<String>> _buildItems(BuildContext context) => [
        _section('Treinos'),
        _item('Histórico',               Icons.history,                  '/history-log'),
        _item('Estatísticas',            Icons.bar_chart_outlined,       '/stats'),
        const PopupMenuDivider(),

        _section('Ferramentas'),
        _item('Calculadora de Pace',     Icons.timer_outlined,           '/pace-calculator'),
        _item('Glossário',               Icons.menu_book_outlined,       '/glossary'),
        const PopupMenuDivider(),

        _section('App'),
        _item('Configurações',           Icons.settings_outlined,        '/settings'),
        _item('Sobre o Treinix',         Icons.info_outline,             '/about'),
        _item('Política de privacidade', Icons.shield_outlined,          '/privacy'),
      ];
}
