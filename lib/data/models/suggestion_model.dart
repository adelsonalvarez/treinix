// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/data/models/suggestion_model.dart
// Camada   : Model – Sugestão IA
// Descrição: Modelo de dados da sugestão de treino gerada pela IA (Claude API)
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class SuggestionModel {
  final String id;
  final String userId;
  final Modality modality;
  final String title;
  final String description;
  final int durationMinutes;
  final String intensity;
  final List<String> steps;     // etapas do treino
  final String tip;             // dica do dia da IA
  final DateTime generatedAt;
  final bool accepted;

  const SuggestionModel({
    required this.id,
    required this.userId,
    required this.modality,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.intensity,
    required this.steps,
    required this.tip,
    required this.generatedAt,
    this.accepted = false,
  });

  factory SuggestionModel.fromJson(Map<String, dynamic> json, String userId) {
    return SuggestionModel(
      id: '',
      userId: userId,
      modality: Modality.values.firstWhere(
        (e) => e.name == json['modality'],
        orElse: () => Modality.corrida,
      ),
      title: json['title'] ?? 'Treino do dia',
      description: json['description'] ?? '',
      durationMinutes: json['durationMinutes'] ?? 30,
      intensity: json['intensity'] ?? 'Moderado',
      steps: List<String>.from(json['steps'] ?? []),
      tip: json['tip'] ?? '',
      generatedAt: DateTime.now(),
    );
  }

  factory SuggestionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SuggestionModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      modality: Modality.values.firstWhere(
        (e) => e.name == d['modality'],
        orElse: () => Modality.corrida,
      ),
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      durationMinutes: d['durationMinutes'] ?? 30,
      intensity: d['intensity'] ?? 'Moderado',
      steps: List<String>.from(d['steps'] ?? []),
      tip: d['tip'] ?? '',
      generatedAt: (d['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      accepted: d['accepted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'modality': modality.name,
        'title': title,
        'description': description,
        'durationMinutes': durationMinutes,
        'intensity': intensity,
        'steps': steps,
        'tip': tip,
        'generatedAt': Timestamp.fromDate(generatedAt),
        'accepted': accepted,
      };
}