// =============================================================================
// Projeto    : Treinix – Treinador Digital para Atletas Amadores
// Arquivo    : lib/viewmodels/suggestion_viewmodel.dart
// Camada     : ViewModel – Sugestão / Plano de Treino
// Descrição  : Orquestra a geração de plano via IA, persiste no Firestore e
//              controla o progresso de sessões (concluir, rotação circular).
// -----------------------------------------------------------------------------
// Autor      : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso      : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano        : 2026
// =============================================================================

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../data/models/user_model.dart';
import '../data/models/training_model.dart';
import '../data/models/training_context_model.dart';
import '../data/repositories/plan_repository.dart';

enum PlanStatus { idle, loading, active, error }

class SuggestionViewModel extends ChangeNotifier {
  final _repo      = PlanRepository();
  final _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  TrainingPlanModel? _activePlan;
  PlanStatus         _status       = PlanStatus.idle;
  String?            _errorMessage;

  TrainingPlanModel? get activePlan    => _activePlan;
  PlanStatus         get status        => _status;
  String?            get errorMessage  => _errorMessage;
  bool               get isLoading     => _status == PlanStatus.loading;

  // Plano ativo = existe, dentro da validade e não concluído
  bool get hasPlan =>
      _activePlan != null &&
      _activePlan!.isActive &&
      !_activePlan!.isPlanCompleted;

  // Plano foi concluído (todas as sessões feitas)
  bool get isPlanCompleted => _activePlan?.isPlanCompleted ?? false;

  // ─── Carrega plano ativo da modalidade ──────────────────────────────────

  Future<void> loadActivePlan(String uid, Modality modality) async {
    _status = PlanStatus.loading;
    notifyListeners();
    try {
      _activePlan = await _repo.getActivePlan(uid, modality);
      _status = _activePlan != null ? PlanStatus.active : PlanStatus.idle;
    } catch (e) {
      _status = PlanStatus.idle;
    }
    notifyListeners();
  }

  // ─── Gera novo plano via Cloud Function ─────────────────────────────────

  Future<void> generatePlan({
    required UserModel user,
    required TrainingContextModel context,
  }) async {
    _status       = PlanStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final callable = _functions.httpsCallable(
        'generateTrainingSuggestion',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 90)),
      );

      final result = await callable.call<Map<String, dynamic>>({
        // Dados do perfil (contexto base)
        'modality':           context.modality.name,
        'level':              user.level.name,
        'goal':               user.goal.name,
        'age':                user.age,
        'sessionsCount':       context.sessionsCount,
        'weeksToCompetition': user.weeksToCompetition ?? 0,
        'competitionName':    user.competitionName,
        // Intenção da sessão — vêm do formulário (prioridade alta)
        'focus':              context.focus.name,
        'intensity':          context.intensity.name,
        'durationMinutes':    context.durationMinutes,
        // Instruções livres do atleta (prioridade máxima)
        'freeText':           context.freeText,
      });

      final data = Map<String, dynamic>.from(result.data as Map);

      final validUntilStr = data['validUntil'] as String?;
      final isMusculacao  = context.modality == Modality.musculacao;
      final validUntil = validUntilStr != null
          ? DateTime.parse(validUntilStr)
          : DateTime.now().add(
              isMusculacao
                  ? const Duration(days: 30)
                  : const Duration(days: 7));

      final sessions = (data['sessions'] as List<dynamic>? ?? [])
          .map((s) => TrainingSession.fromMap(Map<String, dynamic>.from(s)))
          .toList();

      // Musculação: splits A/B/C definidos pelo usuário repetem por 4 semanas.
      // Endurance: a IA gera exatamente as sessões pedidas → sessions.length.
      final totalSlots = isMusculacao
          ? context.sessionsCount * 4
          : sessions.length;

      final plan = TrainingPlanModel(
        id:                 '',
        userId:             user.uid,
        modality:           context.modality,
        planType:           data['planType'] == 'mensal'
            ? PlanType.mensal
            : PlanType.semanal,
        title:              data['title']   ?? 'Plano de treino',
        overview:           data['overview'] ?? '',
        sessions:           sessions,
        tip:                data['tip']          ?? '',
        hasTapering:        data['hasTapering']  ?? false,
        weeksToCompetition: (data['weeksToCompetition'] as num?)?.toInt(),
        generatedAt:        DateTime.now(),
        validUntil:         validUntil,
        totalSlots:         totalSlots,
        completedCount:     0,
        nextSessionIndex:   0,
      );

      final id = await _repo.save(plan);
      _activePlan = plan.copyWith(id: id);
      _status     = PlanStatus.active;

    } on FirebaseFunctionsException catch (e) {
      _errorMessage = _mapError(e.code, e.message);
      _status       = PlanStatus.error;
    } catch (e) {
      _errorMessage = 'Erro inesperado. Tente novamente.';
      _status       = PlanStatus.error;
    }

    notifyListeners();
  }

  // ─── Marca a sessão atual como concluída e avança para a próxima ────────

  Future<void> completeSession() async {
    final plan = _activePlan;
    if (plan == null || plan.id.isEmpty || plan.sessions.isEmpty) return;

    final newCompleted = plan.completedCount + 1;
    final newIndex     = (plan.nextSessionIndex + 1) % plan.sessions.length;

    await _repo.updateProgress(
      plan.userId, plan.id,
      completedCount:   newCompleted,
      nextSessionIndex: newIndex,
    );

    _activePlan = plan.copyWith(
      completedCount:   newCompleted,
      nextSessionIndex: newIndex,
    );
    notifyListeners();
  }

  void reset() {
    _activePlan   = null;
    _status       = PlanStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  String _mapError(String code, [String? message]) => switch (code) {
        'unauthenticated'    => 'Você precisa estar logado.',
        'invalid-argument'   => 'Perfil incompleto. Complete o onboarding.',
        'deadline-exceeded'  => 'A IA demorou demais. Tente novamente.',
        'resource-exhausted' => message ?? 'Aguarde 24h para gerar um novo plano desta modalidade.',
        _                    => 'Erro ao gerar plano ($code). Tente novamente.',
      };
}
