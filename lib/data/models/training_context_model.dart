// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/data/models/training_context_model.dart
// Camada   : Model – Contexto de Treino
// Descrição: Dados coletados do usuário antes de gerar a sugestão da IA.
//            Combina chips rápidos com texto livre para enriquecer o prompt.
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'user_model.dart';

enum TrainingFocus { velocidade, resistencia, tecnica, regenerativo, forca }

extension TrainingFocusLabel on TrainingFocus {
  String get label => switch (this) {
        TrainingFocus.velocidade   => 'Velocidade',
        TrainingFocus.resistencia  => 'Resistência',
        TrainingFocus.tecnica      => 'Técnica',
        TrainingFocus.regenerativo => 'Regenerativo',
        TrainingFocus.forca        => 'Força',
      };
}

enum DesiredIntensity { leve, moderado, intenso }

extension DesiredIntensityLabel on DesiredIntensity {
  String get label => switch (this) {
        DesiredIntensity.leve     => 'Leve',
        DesiredIntensity.moderado => 'Moderado',
        DesiredIntensity.intenso  => 'Intenso',
      };
}

class TrainingContextModel {
  final Modality modality;
  final int durationMinutes;        // tempo disponível por sessão (endurance)
  final TrainingFocus focus;
  final DesiredIntensity intensity;
  final int sessionsCount;          // sessões no plano (endurance) ou splits/semana (musculação)
  final String freeText;            // contexto adicional em texto livre

  const TrainingContextModel({
    required this.modality,
    required this.durationMinutes,
    required this.focus,
    required this.intensity,
    this.sessionsCount = 3,
    this.freeText      = '',
  });

  /// Serializa para enviar à Cloud Function
  Map<String, dynamic> toMap() => {
        'modality':        modality.name,
        'durationMinutes': durationMinutes,
        'focus':           focus.name,
        'intensity':       intensity.name,
        'sessionsCount':   sessionsCount,
        'freeText':        freeText.trim(),
      };
}