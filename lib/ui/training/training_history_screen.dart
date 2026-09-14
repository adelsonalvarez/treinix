// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/ui/training/training_history_screen.dart
// Camada   : Screen – Meus Planos
// Descrição: Lista todos os planos de treino (IA e manuais) com status e
//            progresso. Histórico de sessões acessível pelo menu ⋮.
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../widgets/treinix_app_bar.dart';
import '../../data/models/training_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/plan_repository.dart';

class TrainingHistoryScreen extends StatefulWidget {
  const TrainingHistoryScreen({super.key});
  @override
  State<TrainingHistoryScreen> createState() => _TrainingHistoryScreenState();
}

class _TrainingHistoryScreenState extends State<TrainingHistoryScreen> {
  List<TrainingPlanModel> _plans       = [];
  bool                    _loading     = true;
  String?                 _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { setState(() => _loading = false); return; }
    try {
      final plans = await PlanRepository().getAllForUser(uid);
      if (mounted) setState(() { _plans = plans; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const TreinixAppBar(
        screenTitle: 'Meus planos',
        showAppMenu: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('Erro ao carregar planos', style: AppTextStyles.heading3),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ));
    }

    final active = _plans
        .where((p) => p.isActive && !p.isPlanCompleted)
        .toList();

    if (active.isEmpty) return _EmptyPlans();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: active.length,
        itemBuilder: (context, i) => _PlanTile(
          plan:  active[i],
          onTap: () => context.go('/plan-detail', extra: active[i]),
        ),
      ),
    );
  }
}

// ─── Tile de plano ────────────────────────────────────────────────────────────

class _PlanTile extends StatelessWidget {
  final TrainingPlanModel plan;
  final VoidCallback      onTap;
  const _PlanTile({required this.plan, required this.onTap});

  Color get _color => switch (plan.modality) {
        Modality.corrida    => AppColors.corrida,
        Modality.natacao    => AppColors.natacao,
        Modality.ciclismo   => AppColors.ciclismo,
        Modality.musculacao => AppColors.musculacao,
      };

  ({String label, Color bg, Color fg}) get _status {
    if (plan.isPlanCompleted) {
      return (label: 'Concluído', bg: AppColors.success.withAlpha(30), fg: AppColors.success);
    }
    if (!plan.isActive) {
      return (label: 'Expirado', bg: AppColors.border, fg: AppColors.textTertiary);
    }
    return (label: 'Ativo', bg: _color.withAlpha(30), fg: _color);
  }

  @override
  Widget build(BuildContext context) {
    final s        = _status;
    final done     = plan.completedCount;
    final total    = plan.totalSlots;
    final progress = total > 0 ? done / total : 0.0;
    final dateStr  = DateFormat("d MMM yyyy", 'pt_BR').format(plan.generatedAt);
    final isActive = plan.isActive && !plan.isPlanCompleted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? _color.withAlpha(80) : AppColors.border,
            width: isActive ? 1.5 : 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(plan.modality.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(child: Text(plan.title, style: AppTextStyles.bodyMedium,
                  maxLines: 2, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(6)),
                child: Text(s.label, style: AppTextStyles.caption.copyWith(
                    color: s.fg, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(dateStr, style: AppTextStyles.caption),
              const SizedBox(width: 12),
              const Icon(Icons.list_alt_outlined, size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text('${plan.sessions.length} ${plan.sessions.length == 1 ? 'treino' : 'treinos'}',
                  style: AppTextStyles.caption),
            ]),
            if (total > 0) ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress, minHeight: 5,
                    backgroundColor: _color.withAlpha(30),
                    valueColor: AlwaysStoppedAnimation<Color>(_color),
                  ),
                )),
                const SizedBox(width: 10),
                Text('$done/$total', style: AppTextStyles.caption
                    .copyWith(fontWeight: FontWeight.w600)),
              ]),
            ],
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text('Ver plano', style: AppTextStyles.caption
                  .copyWith(color: _color, fontWeight: FontWeight.w600)),
              Icon(Icons.chevron_right, color: _color, size: 16),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyPlans extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📋', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('Nenhum plano cadastrado', style: AppTextStyles.heading3),
          const SizedBox(height: 6),
          const Text('Gere um plano com a IA ou crie\num plano manual.',
              style: AppTextStyles.bodySm, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton.icon(
              onPressed: () => context.go('/suggestion'),
              icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              label: const Text('Gerar com IA', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () => context.push('/log-training'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Criar manual'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),
        ],
      ),
    ),
  );
}
