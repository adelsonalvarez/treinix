// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/ui/training/training_detail_screen.dart
// Camada   : Screen – Detalhe do Treino
// Descrição: Exibe todos os dados de um treino do histórico: header colorido
//            por modalidade, metadados, exercícios executados e badge de IA.
//            Acessível via /training-detail (GoRouter) com TrainingModel como extra.
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/training_model.dart';
import '../../data/models/user_model.dart';
import '../widgets/treinix_app_bar.dart';

class TrainingDetailScreen extends StatelessWidget {
  final TrainingModel training;
  const TrainingDetailScreen({super.key, required this.training});

  Color get _color => switch (training.modality) {
        Modality.corrida    => AppColors.corrida,
        Modality.natacao    => AppColors.natacao,
        Modality.ciclismo   => AppColors.ciclismo,
        Modality.musculacao => AppColors.musculacao,
      };

  String get _intensityLabel => switch (training.intensity) {
        IntensityLevel.leve     => 'Leve',
        IntensityLevel.moderado => 'Moderado',
        IntensityLevel.intenso  => 'Intenso',
      };

  bool get _isMusc => training.modality == Modality.musculacao;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat("EEEE, d 'de' MMMM 'de' y", 'pt_BR')
        .format(training.date);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TreinixAppBar(
        screenTitle: training.modality.label,
        showBack:    true,
        showAppMenu: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header colorido por modalidade ───────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_color, _color.withAlpha(204)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(training.modality.emoji,
                          style: const TextStyle(fontSize: 36)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          training.title,
                          style: const TextStyle(
                            color:      Colors.white,
                            fontSize:   20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dateStr,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  if (training.isAiGenerated) ...[
                    const SizedBox(height: 8),
                    const Row(children: [
                      Icon(Icons.auto_awesome,
                          size: 13, color: Colors.white70),
                      SizedBox(width: 4),
                      Text('Gerado por IA',
                          style: TextStyle(
                            color:    Colors.white70,
                            fontSize: 12,
                          )),
                    ]),
                  ],
                ],
              ),
            ),

            // ── Conteúdo ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Chips de metadados
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    _InfoChip(
                      icon:  Icons.timer_outlined,
                      label: '${training.durationMinutes} min',
                      color: _color,
                    ),
                    _InfoChip(
                      icon:  Icons.bolt_outlined,
                      label: _intensityLabel,
                      color: _color,
                    ),
                    _InfoChip(
                      icon:  Icons.fitness_center,
                      label: training.modality.label,
                      color: _color,
                    ),
                  ]),

                  // Banner de conclusão
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color:        AppColors.success.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.success.withAlpha(77)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.check_circle_outline,
                          color: AppColors.success, size: 20),
                      SizedBox(width: 10),
                      Text('Treino realizado com sucesso!',
                          style: TextStyle(
                            color:      AppColors.success,
                            fontWeight: FontWeight.w600,
                          )),
                    ]),
                  ),

                  // Descrição
                  if (training.description.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Sobre o treino', style: AppTextStyles.heading3),
                    const SizedBox(height: 8),
                    Text(training.description, style: AppTextStyles.body),
                  ],

                  // Lista de exercícios
                  if (training.exercises.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text(
                      _isMusc ? 'Exercícios' : 'Blocos',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 12),
                    ..._buildExerciseList(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildExerciseList() {
    final items = <Widget>[];
    String? lastGroup;

    for (var i = 0; i < training.exercises.length; i++) {
      final ex = training.exercises[i];

      if (_isMusc && ex.group != null && ex.group != lastGroup) {
        lastGroup = ex.group;
        items.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(ex.group!,
              style: AppTextStyles.caption.copyWith(
                color:         _color,
                fontWeight:    FontWeight.w700,
                letterSpacing: .5,
              )),
        ));
      }

      items.add(_ExerciseRow(
        index:  i,
        ex:     ex,
        isMusc: _isMusc,
        color:  _color,
      ));
    }
    return items;
  }
}

// ─── Linha de exercício ───────────────────────────────────────────────────────

class _ExerciseRow extends StatelessWidget {
  final int          index;
  final ExerciseItem ex;
  final bool         isMusc;
  final Color        color;

  const _ExerciseRow({
    required this.index,
    required this.ex,
    required this.isMusc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color:        AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border:       Border.all(color: color.withAlpha(40)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26, height: 26,
          margin: const EdgeInsets.only(right: 12, top: 1),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Center(child: Text(
            '${index + 1}',
            style: TextStyle(
              color:      color,
              fontSize:   12,
              fontWeight: FontWeight.w700,
            ),
          )),
        ),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ex.name, style: AppTextStyles.bodyMedium),
            if (ex.displayLine.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(ex.displayLine,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
            ],
            if (ex.notes != null) ...[
              const SizedBox(height: 4),
              Text(ex.notes!,
                  style: AppTextStyles.bodySm.copyWith(
                    fontStyle: FontStyle.italic,
                    color:     AppColors.textTertiary,
                  )),
            ],
          ],
        )),
      ],
    ),
  );
}

// ─── Chip de metadado ─────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color:        color.withAlpha(20),
      borderRadius: BorderRadius.circular(8),
      border:       Border.all(color: color.withAlpha(64)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 6),
      Text(label,
          style: AppTextStyles.bodySm.copyWith(
              color: color, fontWeight: FontWeight.w500)),
    ]),
  );
}
