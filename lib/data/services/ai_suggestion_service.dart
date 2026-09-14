// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/data/services/ai_suggestion_service.dart
// Camada   : Service – IA
// Descrição: Integração com Cloud Function que aciona a Claude API.
//            Envia perfil + contexto da sessão para sugestão personalizada.
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:cloud_functions/cloud_functions.dart';
import '../models/user_model.dart';
import '../models/suggestion_model.dart';
import '../models/training_context_model.dart';

class AiSuggestionService {
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<SuggestionModel> generate({
    required UserModel user,
    required TrainingContextModel context,
  }) async {
    final callable = _functions.httpsCallable(
      'generateTrainingSuggestion',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );

    try {
      final result = await callable.call<Map<String, dynamic>>({
        'level':       user.level.name,
        'goal':        user.goal.name,
        'age':         user.age,
        ...context.toMap(),
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      return SuggestionModel.fromJson(data, user.uid);

    } on FirebaseFunctionsException catch (e) {
      throw AiSuggestionException(_mapError(e.code, e.message));
    } catch (_) {
      throw const AiSuggestionException(
        'Não foi possível conectar ao servidor. Verifique sua internet.',
      );
    }
  }

  String _mapError(String code, String? message) => switch (code) {
        'unauthenticated'    => 'Você precisa estar logado.',
        'invalid-argument'   => 'Perfil incompleto. Complete o onboarding.',
        'deadline-exceeded'  => 'A IA demorou demais. Tente novamente.',
        'resource-exhausted' => message ?? 'Aguarde 24h para gerar um novo plano desta modalidade.',
        _                    => 'Erro ao gerar sugestão ($code). Tente novamente.',
      };
}

class AiSuggestionException implements Exception {
  final String message;
  const AiSuggestionException(this.message);
  @override
  String toString() => message;
}