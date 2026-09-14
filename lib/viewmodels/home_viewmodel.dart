// =============================================================================
// Projeto    : Treinix – Treinador Digital para Atletas Amadores
// Arquivo    : lib/viewmodels/home_viewmodel.dart
// Camada     : ViewModel – Home / Dashboard
// Descrição  : Carrega planos ativos e últimos treinos; notifica a HomeScreen
//              sobre conclusão de sessões e remoção de planos.
// -----------------------------------------------------------------------------
// Autor      : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso      : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano        : 2026
// =============================================================================

import 'package:flutter/material.dart';
import '../data/models/training_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/plan_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final _repo = PlanRepository();

  Map<Modality, TrainingPlanModel?> _plans = {};
  bool _loading = false;

  Map<Modality, TrainingPlanModel?> get plans  => _plans;
  bool                               get loading => _loading;

  Future<void> load(String uid, List<Modality> modalities) async {
    if (modalities.isEmpty) return;
    _loading = true;
    notifyListeners();

    try {
      final results = await Future.wait(
        modalities.map((m) => _repo.getActivePlan(uid, m)),
      );
      _plans = {for (int i = 0; i < modalities.length; i++) modalities[i]: results[i]};
    } catch (_) {
      // Falha silenciosa — o mapa de planos permanece com o último estado conhecido.
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Atualiza o plano em memória após concluir uma sessão na tela de treino.
  void markSessionComplete(TrainingPlanModel updated) {
    _plans[updated.modality] = updated;
    notifyListeners();
  }

  // Remove o plano de uma modalidade (após exclusão).
  void removePlan(Modality modality) {
    _plans[modality] = null;
    notifyListeners();
  }
}
