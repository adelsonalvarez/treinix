// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/data/repositories/suggestion_repository.dart
// Camada   : Repository – Sugestões IA
// Descrição: Persistência e consulta de sugestões geradas pela IA no Firestore
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/suggestion_model.dart';

class SuggestionRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference _col(String uid) =>
      _db.collection('users').doc(uid).collection('suggestions');

  Future<String> save(SuggestionModel s) async {
    final ref = await _col(s.userId).add(s.toFirestore());
    return ref.id;
  }

  Future<SuggestionModel?> getLatest(String uid) async {
    final snap = await _col(uid)
        .orderBy('generatedAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return SuggestionModel.fromFirestore(snap.docs.first);
  }

  Future<void> markAccepted(String uid, String suggestionId) async {
    await _col(uid).doc(suggestionId).update({'accepted': true});
  }

  Future<List<SuggestionModel>> getAll(String uid) async {
    final snap = await _col(uid)
        .orderBy('generatedAt', descending: true)
        .limit(20)
        .get();
    return snap.docs.map((d) => SuggestionModel.fromFirestore(d)).toList();
  }
}