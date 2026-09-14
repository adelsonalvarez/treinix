// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/data/repositories/training_repository.dart
// Camada   : Repository – Treinos
// Descrição: CRUD de treinos registrados no Firestore
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/training_model.dart';

class TrainingRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference _col(String uid) =>
      _db.collection('users').doc(uid).collection('trainings');

  Future<void> save(TrainingModel t) async {
    if (t.id.isEmpty) {
      await _col(t.userId).add(t.toFirestore());
    } else {
      await _col(t.userId).doc(t.id).set(t.toFirestore());
    }
  }

  Future<void> updateStatus(String uid, String trainingId, TrainingStatus status) async {
    await _col(uid).doc(trainingId).update({'status': status.name});
  }

  Future<List<TrainingModel>> getHistory(String uid, {int limit = 30}) async {
    final snap = await _col(uid)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => TrainingModel.fromFirestore(d)).toList();
  }

  Future<TrainingModel?> getLastTraining(String uid) async {
    final snap = await _col(uid)
        .where('status', isEqualTo: TrainingStatus.realizado.name)
        .orderBy('date', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return TrainingModel.fromFirestore(snap.docs.first);
  }
}