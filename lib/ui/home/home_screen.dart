// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/ui/home/home_screen.dart
// Camada   : Screen – Home / Dashboard
// Descrição: Tela inicial com streak semanal, próximos treinos por modalidade
//            e últimos treinos registrados.
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
import '../../data/models/training_model.dart';
import '../../data/models/user_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/training_viewmodel.dart';
import '../widgets/treinix_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Chave que combina uid + nº de modalidades; muda apenas quando o perfil muda.
  String? _lastLoadKey;

  // didChangeDependencies é chamado após initState e sempre que um Provider
  // assistido por este widget muda — garante carga mesmo quando o auth
  // termina de inicializar depois do primeiro build.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthViewModel>().currentUser;
    if (user == null || user.modalities.isEmpty) return;

    final key = '${user.uid}:${user.modalities.length}';
    if (key == _lastLoadKey) return;
    _lastLoadKey = key;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TrainingViewModel>().loadHistory(user.uid);
      context.read<HomeViewModel>().load(user.uid, user.modalities);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth       = context.watch<AuthViewModel>();
    final homeVm     = context.watch<HomeViewModel>();
    final trainingVm = context.watch<TrainingViewModel>();
    final user       = auth.currentUser;
    final name       = user?.name.split(' ').first ?? 'Atleta';
    final streak     = trainingVm.weekStreak;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const TreinixAppBar(showAppMenu: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ────────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Olá, $name 👋', style: AppTextStyles.heading3),
                        const Text('Pronto para treinar hoje?',
                            style: AppTextStyles.bodySm),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Streak card ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Treinos esta semana',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('$streak dias',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                            )),
                        const SizedBox(height: 4),
                        Text(
                          streak == 0
                              ? 'Comece hoje!'
                              : streak < 3
                                  ? 'Bom começo! Continue assim.'
                                  : 'Excelente consistência! 🔥',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Text('🏆', style: TextStyle(fontSize: 52)),
                ]),
              ),

              const SizedBox(height: 28),

              // ── Próximos treinos por modalidade ───────────────────────────
              if (user != null && user.modalities.isNotEmpty) ...[
                const Text('Próximos treinos', style: AppTextStyles.heading3),
                const SizedBox(height: 12),

                if (homeVm.loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  ...user.modalities.map((m) => _NextTrainingCard(
                    modality: m,
                    goal:     user.goal,
                    plan:     homeVm.plans[m],
                    onTap: () => context.go(
                      '/training/${m.name}',
                      extra: homeVm.plans[m],
                    ),
                    onGenerate: () => context.go('/suggestion'),
                  )),

                const SizedBox(height: 8),
              ],

              // ── Ações rápidas ─────────────────────────────────────────────
              const Text('Ações rápidas', style: AppTextStyles.heading3),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(
                  child: _ActionCard(
                    icon:  Icons.auto_awesome,
                    color: AppColors.natacao,
                    label: 'Sugestão da IA',
                    sub:   'Treino personalizado',
                    onTap: () => context.go('/suggestion'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon:  Icons.add_circle_outline,
                    color: AppColors.success,
                    label: 'Registrar treino',
                    sub:   'Anotar atividade',
                    onTap: () => context.push('/log-training'),
                  ),
                ),
              ]),

              const SizedBox(height: 24),

              // ── Últimos treinos ───────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Últimos treinos', style: AppTextStyles.heading3),
                  TextButton(
                    onPressed: () => context.go('/history'),
                    child: const Text('Ver todos'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (trainingVm.loading)
                const Center(child: CircularProgressIndicator())
              else if (trainingVm.history.isEmpty)
                _EmptyState()
              else
                ...trainingVm.history.take(3).map((t) => _TrainingTile(
                      emoji: t.modality.emoji,
                      title: t.title,
                      sub:   '${t.durationMinutes} min · ${t.intensity.name}',
                      date:  t.date,
                    )),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Card de próximo treino por modalidade ────────────────────────────────────

class _NextTrainingCard extends StatelessWidget {
  final Modality          modality;
  final Goal              goal;
  final TrainingPlanModel? plan;
  final VoidCallback       onTap;
  final VoidCallback       onGenerate;

  const _NextTrainingCard({
    required this.modality,
    required this.goal,
    required this.plan,
    required this.onTap,
    required this.onGenerate,
  });

  Color get _color => switch (modality) {
        Modality.corrida    => AppColors.corrida,
        Modality.natacao    => AppColors.natacao,
        Modality.ciclismo   => AppColors.ciclismo,
        Modality.musculacao => AppColors.musculacao,
      };

  String _badge(TrainingPlanModel p) {
    final idx = p.nextSessionIndex % p.sessions.length;
    return '${idx + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final hasActivePlan = plan != null &&
        plan!.isActive &&
        !plan!.isPlanCompleted &&
        plan!.sessions.isNotEmpty;

    return GestureDetector(
      onTap: hasActivePlan ? onTap : onGenerate,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasActivePlan ? _color.withAlpha(80) : AppColors.border,
            width: hasActivePlan ? 1.5 : 0.8,
          ),
        ),
        child: hasActivePlan
            ? _ActiveContent(
                modality: modality,
                goal:     goal,
                plan:     plan!,
                badge:    _badge(plan!),
                color:    _color,
              )
            : _EmptyPlanContent(modality: modality, color: _color),
      ),
    );
  }
}

// ── Conteúdo quando há plano ativo ────────────────────────────────────────────

class _ActiveContent extends StatelessWidget {
  final Modality          modality;
  final Goal              goal;
  final TrainingPlanModel plan;
  final String            badge;
  final Color             color;

  const _ActiveContent({
    required this.modality,
    required this.goal,
    required this.plan,
    required this.badge,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final next     = plan.nextSession!;
    final done     = plan.completedCount;
    final slots    = plan.totalSlots;
    final progress = slots > 0 ? done / slots : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Linha 1: emoji + modalidade + goal + badge
        Row(children: [
          Text(modality.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${modality.label} · ${goal.label}',
                style: AppTextStyles.bodyMedium,
              ),
              Text(next.focus, style: AppTextStyles.caption),
            ],
          )),
          // Badge (A / B / 1 / 2)
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(
              badge,
              style: const TextStyle(
                color:      Colors.white,
                fontSize:   20,
                fontWeight: FontWeight.w800,
              ),
            )),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ]),

        // Linha 2: label da sessão + duração
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                next.label,
                style: AppTextStyles.caption.copyWith(
                  color: color, fontWeight: FontWeight.w700),
              ),
            ),
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.timer_outlined,
                  size: 13, color: AppColors.textTertiary),
              const SizedBox(width: 3),
              Text('${next.durationMinutes} min', style: AppTextStyles.caption),
            ]),
          ],
        ),

        // Linha 3: barra de progresso
        if (slots > 0) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value:           progress,
                  minHeight:       5,
                  backgroundColor: color.withAlpha(35),
                  valueColor:      AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$done/$slots',
              style: AppTextStyles.caption
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ]),
        ],
      ],
    );
  }
}

// ── Conteúdo quando não há plano ─────────────────────────────────────────────

class _EmptyPlanContent extends StatelessWidget {
  final Modality modality;
  final Color    color;
  const _EmptyPlanContent({required this.modality, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(modality.emoji, style: const TextStyle(fontSize: 24)),
    const SizedBox(width: 10),
    Expanded(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(modality.label, style: AppTextStyles.bodyMedium),
        const Text('Sem plano ativo', style: AppTextStyles.caption),
      ],
    )),
    Text(
      'Gerar com IA →',
      style: AppTextStyles.caption.copyWith(
        color: color, fontWeight: FontWeight.w600),
    ),
  ]);
}

// ─── Ação rápida ──────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final String       label;
  final String       sub;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon, required this.color,
    required this.label, required this.sub, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(31),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(label, style: AppTextStyles.bodyMedium),
            Text(sub, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

// ─── Tile de treino recente ───────────────────────────────────────────────────

class _TrainingTile extends StatelessWidget {
  final String   emoji;
  final String   title;
  final String   sub;
  final DateTime date;
  const _TrainingTile({
    required this.emoji, required this.title,
    required this.sub, required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final day =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.bodyMedium),
            Text(sub, style: AppTextStyles.caption),
          ],
        )),
        Text(day, style: AppTextStyles.caption),
      ]),
    );
  }
}

// ─── Estado vazio ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Column(children: [
          Text('🏁', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('Nenhum treino registrado ainda',
              style: AppTextStyles.bodyMedium),
          Text('Comece pela sugestão da IA!', style: AppTextStyles.bodySm),
        ]),
      ),
    );
  }
}
