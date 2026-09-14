// =============================================================================
// Projeto    : Treinix – Treinador Digital para Atletas Amadores
// Arquivo    : lib/viewmodels/user_viewmodel.dart
// Camada     : ViewModel – Usuário
// Descrição  : Estado do perfil do usuário e conclusão do onboarding
// -----------------------------------------------------------------------------
// Autor      : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso      : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano        : 2026
// =============================================================================

import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/repositories/user_repository.dart';

class UserViewModel extends ChangeNotifier {
  final _repo = UserRepository();

  UserModel? _user;
  bool _loading = false;

  UserModel? get user => _user;
  bool get loading => _loading;
  bool get onboardingDone => _user?.onboardingDone ?? false;

  Future<void> load(String uid) async {
    _loading = true;
    notifyListeners();
    _user = await _repo.getUser(uid);
    _loading = false;
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required String uid,
    required String name,
    required String email,
    required List<Modality> modalities,
    required Level level,
    required Goal goal,
    DateTime? birthDate,
  }) async {
    final updated = (_user ?? UserModel(
      uid: uid, name: name, email: email,
      modalities: modalities, level: level, goal: goal,
      createdAt: DateTime.now(),
    )).copyWith(
      name: name,
      modalities: modalities,
      level: level,
      goal: goal,
      onboardingDone: true,
      birthDate: birthDate,
    );

    await _repo.completeOnboarding(uid, updated);
    _user = updated;
    notifyListeners();
  }
}