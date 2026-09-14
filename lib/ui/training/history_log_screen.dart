// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/ui/training/history_log_screen.dart
// Camada   : Screen – Histórico de Sessões
// Descrição: Lista cronológica de todas as sessões de treino realizadas,
//            agrupadas por data, com acesso ao detalhe de cada registro.
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/training_model.dart';
import '../../data/models/user_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/training_viewmodel.dart';
import '../widgets/treinix_app_bar.dart';

class HistoryLogScreen extends StatefulWidget {
  const HistoryLogScreen({super.key});

  @override
  State<HistoryLogScreen> createState() => _HistoryLogScreenState();
}

class _HistoryLogScreenState extends State<HistoryLogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uid = context.read<AuthViewModel>().currentUser?.uid;
      if (uid != null) context.read<TrainingViewModel>().loadHistory(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrainingViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const TreinixAppBar(
        screenTitle: 'Histórico',
        showAppMenu: true,
      ),
      body: _buildBody(context, vm),
    );
  }

  Widget _buildBody(BuildContext context, TrainingViewModel vm) {
    if (vm.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('📓', style: TextStyle(fontSize: 56)),
              SizedBox(height: 16),
              Text('Nenhum registro ainda', style: AppTextStyles.heading3),
              SizedBox(height: 6),
              Text(
                'Os treinos concluídos nos seus planos\naparecerão aqui.',
                style: AppTextStyles.bodySm,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final grouped = vm.groupedByDate;
    final dates   = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final day      = dates[index];
        final sessions = grouped[day]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(day),
                style: AppTextStyles.label.copyWith(
                    color: AppColors.textTertiary, letterSpacing: .05),
              ),
            ),
            ...sessions.map((t) => _HistoryTile(
              training: t,
              onTap: () => context.push('/training-detail', extra: t),
            )),
          ],
        );
      },
    );
  }
}

// ─── Tile de registro ─────────────────────────────────────────────────────────

class _HistoryTile extends StatelessWidget {
  final TrainingModel training;
  final VoidCallback  onTap;
  const _HistoryTile({required this.training, required this.onTap});

  Color get _color => switch (training.modality) {
        Modality.corrida    => AppColors.corrida,
        Modality.natacao    => AppColors.natacao,
        Modality.ciclismo   => AppColors.ciclismo,
        Modality.musculacao => AppColors.musculacao,
      };

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: _color.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(training.modality.emoji,
              style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(training.title, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 2),
            Wrap(
              spacing: 6,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('${training.durationMinutes} min',
                    style: AppTextStyles.caption),
                Container(width: 3, height: 3,
                    decoration: const BoxDecoration(
                        color: AppColors.textTertiary,
                        shape: BoxShape.circle)),
                Text(
                  switch (training.intensity) {
                    IntensityLevel.leve     => 'Leve',
                    IntensityLevel.moderado => 'Moderado',
                    IntensityLevel.intenso  => 'Intenso',
                  },
                  style: AppTextStyles.caption,
                ),
                if (training.isAiGenerated)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.auto_awesome,
                        size: 12, color: AppColors.natacao),
                    const SizedBox(width: 2),
                    Text('IA', style: AppTextStyles.caption
                        .copyWith(color: AppColors.natacao)),
                  ]),
              ],
            ),
          ],
        )),
        const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
      ]),
    ),
  );
}
