// =============================================================================
// Projeto    : Treinix – Treinador Digital para Atletas Amadores
// Arquivo    : lib/viewmodels/training_viewmodel.dart
// Camada     : ViewModel – Treinos
// Descrição  : Listagem, registro e cálculo de streak semanal de treinos
// -----------------------------------------------------------------------------
// Autor      : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso      : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano        : 2026
// =============================================================================

import 'package:flutter/material.dart';
import '../data/repositories/training_repository.dart';
import '../data/models/training_model.dart';
import '../data/models/user_model.dart';

class TrainingViewModel extends ChangeNotifier {
  final _repo = TrainingRepository();

  List<TrainingModel> _history = [];
  bool _loading = false;
  String? _error;

  List<TrainingModel> get history => _history;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadHistory(String uid) async {
    _loading = true;
    notifyListeners();
    try {
      _history = await _repo.getHistory(uid);
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> logTraining({
    required String uid,
    required Modality modality,
    required String title,
    required String description,
    required int durationMinutes,
    required IntensityLevel intensity,
    bool isAiGenerated = false,
    List<ExerciseItem> exercises = const [],
  }) async {
    final t = TrainingModel(
      id: '',
      userId: uid,
      modality: modality,
      title: title,
      description: description,
      durationMinutes: durationMinutes,
      intensity: intensity,
      status: TrainingStatus.realizado,
      date: DateTime.now(),
      isAiGenerated: isAiGenerated,
      exercises: exercises,
    );
    await _repo.save(t);
    await loadHistory(uid);
  }

  // Agrupa o histórico por data (para exibir no histórico)
  Map<DateTime, List<TrainingModel>> get groupedByDate {
    final map = <DateTime, List<TrainingModel>>{};
    for (final t in _history) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      map.putIfAbsent(day, () => []).add(t);
    }
    return map;
  }

  int get weekStreak {
    // Conta quantos dias distintos houve treino nos últimos 7 dias
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final days = _history
        .where((t) =>
            t.date.isAfter(cutoff) && t.status == TrainingStatus.realizado)
        .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
        .toSet();
    return days.length;
  }
}