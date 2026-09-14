// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/data/repositories/plan_repository.dart
// Camada   : Repository – Planos de Treino
// Descrição: CRUD dos planos gerados pela IA no Firestore.
//            Busca o plano ativo por modalidade e salva novos planos.
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/training_model.dart';
import '../models/user_model.dart';

class PlanRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference _col(String uid) =>
      _db.collection('users').doc(uid).collection('plans');

  /// Retorna o plano ativo para a modalidade informada, ou null se não houver.
  /// Filtra por modalidade no servidor (índice único automático) e aplica o
  /// filtro de validade em Dart para evitar exigir um índice composto.
  Future<TrainingPlanModel?> getActivePlan(String uid, Modality modality) async {
    final snap = await _col(uid)
        .where('modality', isEqualTo: modality.name)
        .get();

    if (snap.docs.isEmpty) return null;

    final now = DateTime.now();
    final candidates = snap.docs
        .map((d) => TrainingPlanModel.fromFirestore(d))
        .where((p) => p.validUntil.isAfter(now) && !p.isPlanCompleted)
        .toList();

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
    return candidates.first;
  }

  /// Salva um novo plano e retorna o ID gerado.
  Future<String> save(TrainingPlanModel plan) async {
    final ref = await _col(plan.userId).add(plan.toFirestore());
    return ref.id;
  }

  /// Atualiza o progresso (sessões concluídas e índice da próxima).
  Future<void> updateProgress(
    String uid,
    String planId, {
    required int completedCount,
    required int nextSessionIndex,
  }) async {
    await _col(uid).doc(planId).update({
      'completedCount':   completedCount,
      'nextSessionIndex': nextSessionIndex,
    });
  }

  /// Lista todos os planos do usuário para uma modalidade.
  Future<List<TrainingPlanModel>> getAll(String uid, Modality modality) async {
    final snap = await _col(uid)
        .where('modality', isEqualTo: modality.name)
        .orderBy('generatedAt', descending: true)
        .limit(10)
        .get();
    return snap.docs
        .map((d) => TrainingPlanModel.fromFirestore(d))
        .toList();
  }

  /// Retorna todos os planos do usuário (todas as modalidades), mais recentes primeiro.
  Future<List<TrainingPlanModel>> getAllForUser(String uid, {int limit = 30}) async {
    final snap = await _col(uid)
        .orderBy('generatedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => TrainingPlanModel.fromFirestore(d))
        .toList();
  }

  /// Exclui um plano permanentemente.
  Future<void> delete(String uid, String planId) async {
    await _col(uid).doc(planId).delete();
  }

  /// Substitui um plano existente (usado ao editar — preserva o ID).
  Future<void> updateFull(TrainingPlanModel plan) async {
    await _col(plan.userId).doc(plan.id).set(plan.toFirestore());
  }
}
