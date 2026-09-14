// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/ui/widgets/modality_chip.dart
// Camada   : Widget – Chip de Modalidade
// Descrição: Chip animado para seleção de modalidade esportiva com cor por tipo
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/user_model.dart';

class ModalityChip extends StatelessWidget {
  final Modality modality;
  final bool selected;
  final VoidCallback onTap;

  const ModalityChip({
    super.key,
    required this.modality,
    required this.selected,
    required this.onTap,
  });

  Color get _modalityColor => switch (modality) {
        Modality.corrida => AppColors.corrida,
        Modality.natacao => AppColors.natacao,
        Modality.ciclismo => AppColors.ciclismo,
        Modality.musculacao => AppColors.musculacao,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _modalityColor : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _modalityColor : AppColors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: _modalityColor.withAlpha(51), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Text(
          modality.label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}