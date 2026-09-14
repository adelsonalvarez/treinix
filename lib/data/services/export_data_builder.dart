import 'dart:convert';

import '../models/user_model.dart';
import '../repositories/plan_repository.dart';
import '../repositories/training_repository.dart';

/// Coleta os dados do usuário e retorna o JSON formatado.
/// Compartilhado entre a implementação web e mobile.
Future<String> buildExportJson(UserModel user) async {
  final trainings = await TrainingRepository().getHistory(user.uid, limit: 500);
  final plans     = await PlanRepository().getAllForUser(user.uid, limit: 100);

  final data = <String, dynamic>{
    'exportDate': DateTime.now().toIso8601String(),
    'app':        'Treinix v1.0.0 (TCC PUC/PR)',
    'reference':  'LGPD Lei 13.709/2018 — Art. 18, V — Portabilidade de dados',
    'profile': {
      'name':       user.name,
      'email':      user.email,
      'age':        user.age,
      'modalities': user.modalities.map((m) => m.label).toList(),
      'level':      user.level.label,
      'goal':       user.goal.label,
      if (user.competitionName.isNotEmpty)
        'competitionName': user.competitionName,
      if (user.competitionDate != null)
        'competitionDate': user.competitionDate!.toIso8601String(),
      'accountCreated': user.createdAt.toIso8601String(),
      'consentGiven':   user.consentGiven,
      if (user.consentDate != null)
        'consentDate': user.consentDate!.toIso8601String(),
    },
    'trainings': trainings.map((t) => {
      'date':            t.date.toIso8601String(),
      'modality':        t.modality.label,
      'title':           t.title,
      'description':     t.description,
      'durationMinutes': t.durationMinutes,
      'intensity':       t.intensity.name,
      'isAiGenerated':   t.isAiGenerated,
    }).toList(),
    'plans': plans.map((p) => {
      'createdAt':      p.generatedAt.toIso8601String(),
      'modality':       p.modality.label,
      'title':          p.title,
      'completedCount': p.completedCount,
      'totalSlots':     p.totalSlots,
      'isCompleted':    p.isPlanCompleted,
      'sessions': p.sessions.map((s) => {
        'label':           s.label,
        'focus':           s.focus,
        'durationMinutes': s.durationMinutes,
        'description':     s.description,
      }).toList(),
    }).toList(),
  };

  return const JsonEncoder.withIndent('  ').convert(data);
}

/// Nome do arquivo de exportação com a data atual.
String exportFilename() {
  final now = DateTime.now();
  final d = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return 'treinix_dados_$d.json';
}
