// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/ui/training/training_session_screen.dart
// Camada   : Screen – Sessão de Treino
// Descrição: Tela de treino individual. Mostra a próxima sessão do plano ativo,
//            com opções "Visualizar" (default) e "Iniciar treino" → "Concluí".
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
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/repositories/plan_repository.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/training_viewmodel.dart';
import '../widgets/treinix_app_bar.dart';
import 'workout_execution_screen.dart';

class TrainingSessionScreen extends StatefulWidget {
  final Modality          modality;
  final TrainingPlanModel? plan;

  const TrainingSessionScreen({
    super.key,
    required this.modality,
    this.plan,
  });

  @override
  State<TrainingSessionScreen> createState() => _TrainingSessionScreenState();
}

class _TrainingSessionScreenState extends State<TrainingSessionScreen> {
  bool _completing = false;

  Color get _color => switch (widget.modality) {
        Modality.corrida    => AppColors.corrida,
        Modality.natacao    => AppColors.natacao,
        Modality.ciclismo   => AppColors.ciclismo,
        Modality.musculacao => AppColors.musculacao,
      };

  String _badge(int index, int total) {
    final i = total > 0 ? index % total : 0;
    return '${i + 1}';
  }

  // Extrai o nível de intensidade do campo focus ("Tipo · Leve/Moderado/Intenso").
  IntensityLevel _intensityFromFocus(String focus) {
    if (focus.contains('Leve'))   return IntensityLevel.leve;
    if (focus.contains('Intenso')) return IntensityLevel.intenso;
    return IntensityLevel.moderado;
  }

  Future<void> _complete() async {
    final plan = widget.plan;
    if (plan == null || plan.id.isEmpty || plan.sessions.isEmpty) return;
    setState(() => _completing = true);

    // Usa sempre o UID do usuário autenticado para evitar erros se plan.userId
    // estiver vazio (acontece em planos gerados pela IA sem o campo userId).
    final uid  = FirebaseAuth.instance.currentUser?.uid ?? plan.userId;
    final next = plan.nextSession!;
    final newCompleted = plan.completedCount + 1;
    final newIndex     = (plan.nextSessionIndex + 1) % plan.sessions.length;

    // 1. Atualiza progresso do plano no Firestore.
    try {
      await PlanRepository().updateProgress(
        uid, plan.id,
        completedCount:   newCompleted,
        nextSessionIndex: newIndex,
      );
    } catch (e) {
      debugPrint('[TrainingSession] updateProgress error: $e');
    }

    // 2. Grava registro de treino realizado (alimenta "Últimos treinos" e Histórico).
    try {
      if (mounted && uid.isNotEmpty) {
        await context.read<TrainingViewModel>().logTraining(
          uid:             uid,
          modality:        widget.modality,
          title:           '${next.label} — ${widget.modality.label}',
          description:     next.focus,
          durationMinutes: next.durationMinutes,
          intensity:       _intensityFromFocus(next.focus),
          isAiGenerated:   plan.overview.isNotEmpty,
          exercises:       next.steps,
        );
      }
    } catch (e) {
      debugPrint('[TrainingSession] logTraining error: $e');
    }

    final updated = plan.copyWith(
      completedCount:   newCompleted,
      nextSessionIndex: newIndex,
    );

    if (mounted) {
      context.read<HomeViewModel>().markSessionComplete(updated);
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;

    if (plan == null || plan.sessions.isEmpty || !plan.isActive) {
      return Scaffold(
        appBar: TreinixAppBar(screenTitle: 'Treino de ${widget.modality.label}', showAppMenu: true),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📋', style: TextStyle(fontSize: 48)),
              SizedBox(height: 12),
              Text('Nenhum plano ativo', style: AppTextStyles.heading3),
              SizedBox(height: 4),
              Text('Gere um plano na aba IA.', style: AppTextStyles.bodySm),
            ],
          ),
        ),
      );
    }

    final next     = plan.nextSession!;
    final sessions = plan.sessions;
    final idx      = plan.nextSessionIndex % sessions.length;
    final badge    = _badge(idx, sessions.length);
    final done     = plan.completedCount;
    final slots    = plan.totalSlots;
    final progress = slots > 0 ? done / slots : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TreinixAppBar(screenTitle: 'Treino de ${widget.modality.label}', showAppMenu: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Barra de progresso ──────────────────────────────────────────
            if (slots > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _color.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _color.withAlpha(60)),
                ),
                child: Row(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value:            progress,
                        minHeight:        7,
                        backgroundColor:  _color.withAlpha(40),
                        valueColor:       AlwaysStoppedAnimation<Color>(_color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$done/$slots',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color:      _color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('treinos', style: AppTextStyles.caption),
                ]),
              ),
              const SizedBox(height: 20),
            ],

            // ── Card da sessão ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _color.withAlpha(100), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Badge + label + duração
                  Row(children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: _color,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: Text(
                        badge,
                        style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   24,
                          fontWeight: FontWeight.w800,
                        ),
                      )),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(next.label, style: AppTextStyles.heading3),
                        Text(next.focus, style: AppTextStyles.bodySm),
                      ],
                    )),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${next.durationMinutes} min',
                        style: AppTextStyles.caption
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ]),

                  const Divider(height: 28),

                  // Descrição
                  Text(next.description, style: AppTextStyles.bodySm),
                  const SizedBox(height: 24),

                  // Exercícios
                  const Text('Exercícios', style: AppTextStyles.label),
                  const SizedBox(height: 12),

                  ...next.steps.asMap().entries.map((e) {
                    final ex = e.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28, height: 28,
                            margin: const EdgeInsets.only(right: 12, top: 1),
                            decoration: BoxDecoration(
                              color: _color.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: Center(child: Text(
                              '${e.key + 1}',
                              style: TextStyle(
                                color:      _color,
                                fontSize:   12,
                                fontWeight: FontWeight.w700,
                              ),
                            )),
                          ),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ex.name, style: AppTextStyles.body),
                              if (ex.displayLine.isNotEmpty)
                                Text(ex.displayLine,
                                    style: AppTextStyles.caption),
                              if (ex.group != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: _color.withAlpha(30),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(ex.group!,
                                      style: AppTextStyles.caption
                                          .copyWith(color: _color)),
                                ),
                            ],
                          )),
                        ],
                      ),
                    );
                  }),

                  // Dica do plano
                  if (plan.tip.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: AppColors.warning.withAlpha(60)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_outline,
                              color: AppColors.warning, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                              plan.tip, style: AppTextStyles.caption)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),

      // ── Botões fixos no rodapé ──────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: _completing
              ? ElevatedButton.icon(
                  onPressed: null,
                  icon: const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white)),
                  label: const Text(
                    'Salvando...',
                    style: TextStyle(
                      color:      Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize:   16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:         _color,
                    disabledBackgroundColor: _color.withAlpha(120),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final done = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => WorkoutExecutionScreen(
                              session:  next,
                              modality: widget.modality,
                            ),
                          ),
                        );
                        if (done == true && mounted) _complete();
                      },
                      icon: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white),
                      label: const Text(
                        'Iniciar treino',
                        style: TextStyle(
                          color:      Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize:   16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _color,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => context.go('/home'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                        side: BorderSide(color: _color.withAlpha(120)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        foregroundColor: _color,
                      ),
                      child: const Text('Voltar'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
