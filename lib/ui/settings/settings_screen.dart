// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/ui/settings/settings_screen.dart
// Camada   : Screen – Configurações do App
// Descrição: Preferências do usuário: notificações, gestão de conta
//            (exportar dados, sair, excluir conta) e links de suporte.
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/services/export_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../widgets/treinix_app_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const TreinixAppBar(
        screenTitle: 'Configurações',
        showAppMenu: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [

          // ── Conta ─────────────────────────────────────────────────────────
          const _SectionHeader(label: 'Conta'),
          _SettingsTile(
            icon:     Icons.person_outline,
            title:    'Perfil',
            subtitle: 'Editar nome, modalidades e objetivos',
            onTap:    () => context.push('/profile'),
          ),
          _SettingsTile(
            icon:      Icons.logout,
            title:     'Sair',
            subtitle:  'Encerrar sessão neste dispositivo',
            iconColor: AppColors.warning,
            onTap:     () => _confirmSignOut(context),
          ),
          _SettingsTile(
            icon:      Icons.download_outlined,
            title:     'Exportar meus dados',
            subtitle:  'Baixa um JSON com todo o seu histórico (LGPD Art. 18, V)',
            onTap:     user != null ? () => _exportData(context, auth) : null,
          ),
          _SettingsTile(
            icon:       Icons.delete_outline,
            title:      'Excluir conta',
            subtitle:   'Remove permanentemente todos os seus dados',
            iconColor:  AppColors.error,
            titleColor: AppColors.error,
            onTap:      user != null ? () => _deleteAccount(context, auth) : null,
          ),
        ],
      ),
    );
  }

  // ── Sair ────────────────────────────────────────────────────────────────────

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do app?'),
        content: const Text('Você precisará fazer login novamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthViewModel>().signOut();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Sair',
                style: TextStyle(color: AppColors.warning)),
          ),
        ],
      ),
    );
  }

  // ── Exportar dados ──────────────────────────────────────────────────────────

  Future<void> _exportData(BuildContext context, AuthViewModel auth) async {
    final user = auth.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Text('📦', style: TextStyle(fontSize: 36)),
        title: const Text('Exportar meus dados',
            textAlign: TextAlign.center),
        content: const Text(
          'Será feito o download de um arquivo JSON com todos os seus dados:\n\n'
          '• Perfil (nome, e-mail, modalidades, nível, objetivo)\n'
          '• Histórico de treinos realizados\n'
          '• Planos de treino criados\n\n'
          'Conforme a LGPD (Art. 18, V), você tem o direito de receber seus '
          'dados em formato legível e interoperável a qualquer momento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exportar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ExportService.exportUserData(user);
    } on UnsupportedError catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text(e.message ?? 'Recurso não disponível nesta plataforma.'),
          backgroundColor: AppColors.warning,
          duration:        const Duration(seconds: 5),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text('Erro ao exportar dados: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  // ── Excluir conta (2 passos) ────────────────────────────────────────────────

  Future<void> _deleteAccount(BuildContext context, AuthViewModel auth) async {
    // Passo 1 — aviso sobre irreversibilidade
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Text('⚠️', style: TextStyle(fontSize: 36)),
        title: const Text('Excluir conta?', textAlign: TextAlign.center),
        content: const Text(
          'Esta ação é permanente e não pode ser desfeita.\n\n'
          'Todos os seus dados serão apagados:\n'
          '• Perfil e informações pessoais\n'
          '• Histórico de treinos\n'
          '• Planos de treino\n'
          '• Sugestões geradas pela IA\n\n'
          'Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (proceed != true || !context.mounted) return;

    // Passo 2 — confirmação com senha (re-autenticação Firebase)
    final passCtrl = TextEditingController();
    bool  obscure  = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Confirmar com senha'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Por segurança, confirme sua senha para apagar a conta:'),
              const SizedBox(height: 16),
              TextField(
                controller:  passCtrl,
                obscureText: obscure,
                autofocus:   true,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  border:    const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir tudo'),
            ),
          ],
        ),
      ),
    );

    final password = passCtrl.text.trim();
    passCtrl.dispose();

    if (confirmed != true || !context.mounted) return;
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha não pode estar vazia.')));
      return;
    }

    // Loading enquanto apaga
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Apagando seus dados…'),
          ]),
        ),
      );
    }

    final success = await auth.deleteAccount(password: password);

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // fecha loader

    if (success) {
      context.go('/login');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:         Text('Conta excluída com sucesso.'),
        backgroundColor: AppColors.success,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:         Text(auth.errorMessage ?? 'Erro ao excluir conta.'),
        backgroundColor: AppColors.error,
      ));
    }
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 10, fontWeight: FontWeight.w700,
        color: AppColors.textTertiary, letterSpacing: 1.2,
      ),
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData      icon;
  final String        title;
  final String        subtitle;
  final VoidCallback? onTap;
  final Color         iconColor;
  final Color?        titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.iconColor  = AppColors.primary,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: iconColor.withAlpha(20),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: AppTextStyles.bodyMedium.copyWith(color: titleColor)),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTextStyles.caption),
          ],
        )),
        if (onTap != null)
          const Icon(Icons.chevron_right,
              color: AppColors.textTertiary, size: 18),
      ]),
    ),
  );
}
