// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/data/models/training_model.dart
// Camada   : Model – Treino e Plano de Treino
// Descrição: Modelos TrainingModel, ExerciseItem, TrainingSession e
//            TrainingPlanModel com suporte a exercícios estruturados e
//            backward-compat com o formato antigo de strings simples.
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

enum IntensityLevel { leve, moderado, intenso }
enum TrainingStatus { realizado, planejado }
enum PlanType { mensal, semanal }

// ─── TrainingModel ────────────────────────────────────────────────────────────

class TrainingModel {
  final String             id;
  final String             userId;
  final Modality           modality;
  final String             title;
  final String             description;
  final int                durationMinutes;
  final IntensityLevel     intensity;
  final TrainingStatus     status;
  final DateTime           date;
  final bool               isAiGenerated;
  final List<ExerciseItem> exercises; // vazio em registros antigos

  const TrainingModel({
    required this.id,
    required this.userId,
    required this.modality,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.intensity,
    required this.status,
    required this.date,
    this.isAiGenerated = false,
    this.exercises     = const [],
  });

  factory TrainingModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TrainingModel(
      id:              doc.id,
      userId:          d['userId']          ?? '',
      modality:        Modality.values.firstWhere(
          (e) => e.name == d['modality'], orElse: () => Modality.corrida),
      title:           d['title']           ?? '',
      description:     d['description']     ?? '',
      durationMinutes: (d['durationMinutes'] as num?)?.toInt() ?? 45,
      intensity:       IntensityLevel.values.firstWhere(
          (e) => e.name == d['intensity'], orElse: () => IntensityLevel.moderado),
      status:          TrainingStatus.values.firstWhere(
          (e) => e.name == d['status'], orElse: () => TrainingStatus.realizado),
      date:            (d['date'] as Timestamp).toDate(),
      isAiGenerated:   d['isAiGenerated'] ?? false,
      exercises: (d['exercises'] as List<dynamic>? ?? [])
          .map(ExerciseItem.fromMap)
          .where((e) => !e.isEmpty)
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId':          userId,
        'modality':        modality.name,
        'title':           title,
        'description':     description,
        'durationMinutes': durationMinutes,
        'intensity':       intensity.name,
        'status':          status.name,
        'date':            Timestamp.fromDate(date),
        'isAiGenerated':   isAiGenerated,
        if (exercises.isNotEmpty)
          'exercises': exercises.map((e) => e.toMap()).toList(),
      };
}

// ─── ExerciseItem ─────────────────────────────────────────────────────────────
// Representa um exercício ou bloco de exercício dentro de uma sessão.
// Compatível com o formato antigo (String simples) e o novo (Map estruturado).

class ExerciseItem {
  final String  name;   // Nome / tipo de esforço (obrigatório)
  final int?    sets;   // Séries ou repetições do bloco (ex: 3 ou 10×200m)
  final String? reps;   // Repetições por série, pode variar: "10" ou "12/10/8"
  final String? load;   // Carga/distância/tempo: "80kg", "200m", "5:30/km"
  final String? rest;   // Descanso/recuperação: "90s", "1 min", "100m caminhada"
  final String? group;  // Bi-set ou tri-set: "Bi-set A", "Tri-set 1"
  final String? notes;  // Observações livres, estilo de nado, progressão etc.

  const ExerciseItem({
    required this.name,
    this.sets,
    this.reps,
    this.load,
    this.rest,
    this.group,
    this.notes,
  });

  bool get isEmpty => name.trim().isEmpty;

  // Linha resumida exibida nos cards (ex: "3 × 10 · 80kg · Desc: 90s")
  String get displayLine {
    final parts = <String>[];
    if (sets != null && load != null) {
      parts.add('$sets× $load');
    } else if (sets != null) {
      parts.add('$sets séries');
    } else if (load != null) {
      parts.add(load!);
    }
    if (reps != null) { parts.add('$reps rep'); }
    if (rest != null) parts.add('Desc: $rest');
    if (group != null) parts.add(group!);
    if (notes != null) parts.add(notes!);
    return parts.join(' · ');
  }

  // Aceita tanto o formato antigo (String) quanto o novo (Map estruturado).
  factory ExerciseItem.fromMap(dynamic data) {
    if (data is String) return ExerciseItem(name: data);
    final m = Map<String, dynamic>.from(data as Map);
    return ExerciseItem(
      name:  m['name']?.toString()  ?? '',
      sets:  (m['sets']  as num?)?.toInt(),
      reps:  m['reps']?.toString(),
      load:  m['load']?.toString(),
      rest:  m['rest']?.toString(),
      group: m['group']?.toString(),
      notes: m['notes']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        if (sets  != null) 'sets':  sets,
        if (reps  != null) 'reps':  reps,
        if (load  != null) 'load':  load,
        if (rest  != null) 'rest':  rest,
        if (group != null) 'group': group,
        if (notes != null) 'notes': notes,
      };
}

// ─── TrainingSession ──────────────────────────────────────────────────────────

class TrainingSession {
  final String           label;
  final String           focus;
  final String           description;
  final List<ExerciseItem> steps;
  final int              durationMinutes;

  const TrainingSession({
    required this.label,
    required this.focus,
    required this.description,
    required this.steps,
    required this.durationMinutes,
  });

  factory TrainingSession.fromMap(Map<String, dynamic> m) => TrainingSession(
        label:           m['label']       ?? '',
        focus:           m['focus']       ?? '',
        description:     m['description'] ?? '',
        steps: (m['steps'] as List<dynamic>? ?? [])
            .map(ExerciseItem.fromMap)
            .where((e) => !e.isEmpty)
            .toList(),
        durationMinutes: (m['durationMinutes'] as num?)?.toInt() ?? 45,
      );

  Map<String, dynamic> toMap() => {
        'label':           label,
        'focus':           focus,
        'description':     description,
        'steps':           steps.map((e) => e.toMap()).toList(),
        'durationMinutes': durationMinutes,
      };
}

// ─── TrainingPlanModel ────────────────────────────────────────────────────────

class TrainingPlanModel {
  final String   id;
  final String   userId;
  final Modality modality;
  final PlanType planType;
  final String   title;
  final String   overview;
  final List<TrainingSession> sessions;
  final String   tip;
  final DateTime generatedAt;
  final DateTime validUntil;
  final bool     hasTapering;
  final int?     weeksToCompetition;

  // Controle de progresso estilo Tecnofit
  final int totalSlots;        // Total de visitas planejadas no período
  final int completedCount;    // Quantas sessões já foram concluídas
  final int nextSessionIndex;  // Índice da próxima sessão (rotação circular)

  const TrainingPlanModel({
    required this.id,
    required this.userId,
    required this.modality,
    required this.planType,
    required this.title,
    required this.overview,
    required this.sessions,
    required this.tip,
    required this.generatedAt,
    required this.validUntil,
    this.hasTapering          = false,
    this.weeksToCompetition,
    this.totalSlots            = 0,
    this.completedCount        = 0,
    this.nextSessionIndex      = 0,
  });

  bool get isActive => DateTime.now().isBefore(validUntil);

  int get remainingSessions => (totalSlots - completedCount).clamp(0, totalSlots);
  bool get isPlanCompleted  => totalSlots > 0 && completedCount >= totalSlots;

  TrainingSession? get nextSession => sessions.isEmpty
      ? null
      : sessions[nextSessionIndex % sessions.length];

  factory TrainingPlanModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TrainingPlanModel(
      id:       doc.id,
      userId:   d['userId']   ?? '',
      modality: Modality.values.firstWhere(
          (e) => e.name == d['modality'], orElse: () => Modality.corrida),
      planType: PlanType.values.firstWhere(
          (e) => e.name == d['planType'], orElse: () => PlanType.semanal),
      title:    d['title']    ?? '',
      overview: d['overview'] ?? '',
      sessions: (d['sessions'] as List<dynamic>? ?? [])
          .map((s) => TrainingSession.fromMap(Map<String, dynamic>.from(s)))
          .toList(),
      tip:          d['tip']          ?? '',
      generatedAt:  (d['generatedAt'] as Timestamp).toDate(),
      validUntil:   (d['validUntil']  as Timestamp).toDate(),
      hasTapering:  d['hasTapering']  ?? false,
      weeksToCompetition: (d['weeksToCompetition'] as num?)?.toInt(),
      totalSlots:        (d['totalSlots']       as num?)?.toInt() ?? 0,
      completedCount:    (d['completedCount']   as num?)?.toInt() ?? 0,
      nextSessionIndex:  (d['nextSessionIndex'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId':              userId,
        'modality':            modality.name,
        'planType':            planType.name,
        'title':               title,
        'overview':            overview,
        'sessions':            sessions.map((s) => s.toMap()).toList(),
        'tip':                 tip,
        'generatedAt':         Timestamp.fromDate(generatedAt),
        'validUntil':          Timestamp.fromDate(validUntil),
        'hasTapering':         hasTapering,
        'weeksToCompetition':  weeksToCompetition,
        'totalSlots':          totalSlots,
        'completedCount':      completedCount,
        'nextSessionIndex':    nextSessionIndex,
      };

  TrainingPlanModel copyWith({
    String? id,
    int? completedCount,
    int? nextSessionIndex,
  }) =>
      TrainingPlanModel(
        id:                 id               ?? this.id,
        userId:             userId,
        modality:           modality,
        planType:           planType,
        title:              title,
        overview:           overview,
        sessions:           sessions,
        tip:                tip,
        generatedAt:        generatedAt,
        validUntil:         validUntil,
        hasTapering:        hasTapering,
        weeksToCompetition: weeksToCompetition,
        totalSlots:         totalSlots,
        completedCount:     completedCount    ?? this.completedCount,
        nextSessionIndex:   nextSessionIndex  ?? this.nextSessionIndex,
      );
}
