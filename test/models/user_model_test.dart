// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : test/models/user_model_test.dart
// Camada   : Testes – Model de Usuário
// Descrição: Testes unitários de UserModel: cálculo de idade, hasCompetition,
//            weeksToCompetition, copyWith e labels dos enums.
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:treinix/data/models/user_model.dart';

UserModel _makeUser({
  Goal         goal            = Goal.resistencia,
  DateTime?    birthDate,
  DateTime?    competitionDate,
  String       competitionName = '',
  List<Modality> modalities    = const [Modality.corrida],
  Level        level           = Level.intermediario,
}) => UserModel(
  uid:             'uid-test',
  name:            'Atleta Teste',
  email:           'teste@treinix.com',
  birthDate:       birthDate,
  modalities:      modalities,
  level:           level,
  goal:            goal,
  competitionDate: competitionDate,
  competitionName: competitionName,
  createdAt:       DateTime(2026, 1, 1),
);

void main() {
  // ─── age ────────────────────────────────────────────────────────────────────

  group('UserModel.age', () {
    test('retorna 0 quando birthDate é nulo', () {
      expect(_makeUser().age, 0);
    });

    test('retorna idade correta quando aniversário já ocorreu este ano', () {
      // Usa 1° de janeiro para garantir que o aniversário sempre passou
      final user = _makeUser(
        birthDate: DateTime(DateTime.now().year - 30, 1, 1),
      );
      expect(user.age, 30);
    });

    test('retorna um ano a menos quando aniversário ainda não ocorreu', () {
      final now = DateTime.now();
      // Usa 31 de dezembro para garantir que o aniversário não passou
      // (exceto se hoje for exatamente 31/12)
      if (now.month < 12 || now.day < 31) {
        final user = _makeUser(
          birthDate: DateTime(now.year - 30, 12, 31),
        );
        expect(user.age, 29);
      }
    });

    test('retorna 0 para data futura (birthDate > hoje)', () {
      final user = _makeUser(
        birthDate: DateTime.now().add(const Duration(days: 30)),
      );
      expect(user.age, 0);
    });
  });

  // ─── hasCompetition ─────────────────────────────────────────────────────────

  group('UserModel.hasCompetition', () {
    test('false quando goal não é desempenho, mesmo com data', () {
      for (final goal in Goal.values.where((g) => g != Goal.desempenho)) {
        final user = _makeUser(
          goal:            goal,
          competitionDate: DateTime(2027, 3, 1),
        );
        expect(user.hasCompetition, isFalse,
            reason: 'Goal.${goal.name} não deve ativar hasCompetition');
      }
    });

    test('false quando goal é desempenho mas sem data de prova', () {
      final user = _makeUser(goal: Goal.desempenho);
      expect(user.hasCompetition, isFalse);
    });

    test('true quando goal é desempenho e há data de prova', () {
      final user = _makeUser(
        goal:            Goal.desempenho,
        competitionDate: DateTime(2027, 3, 1),
      );
      expect(user.hasCompetition, isTrue);
    });
  });

  // ─── weeksToCompetition ─────────────────────────────────────────────────────

  group('UserModel.weeksToCompetition', () {
    test('retorna null quando competitionDate é nulo', () {
      expect(_makeUser().weeksToCompetition, isNull);
    });

    test('retorna número positivo de semanas para prova futura', () {
      final user = _makeUser(
        competitionDate: DateTime.now().add(const Duration(days: 28)),
      );
      expect(user.weeksToCompetition, greaterThan(0));
    });

    test('retorna ~4 semanas para prova em 28 dias', () {
      final user = _makeUser(
        competitionDate: DateTime.now().add(const Duration(days: 28)),
      );
      expect(user.weeksToCompetition, 4);
    });
  });

  // ─── copyWith ───────────────────────────────────────────────────────────────

  group('UserModel.copyWith', () {
    test('sem argumentos preserva todos os campos', () {
      final user = _makeUser(goal: Goal.forca, level: Level.avancado);
      final copy = user.copyWith();
      expect(copy.uid,   user.uid);
      expect(copy.name,  user.name);
      expect(copy.goal,  user.goal);
      expect(copy.level, user.level);
    });

    test('altera apenas o campo especificado', () {
      final user    = _makeUser(goal: Goal.resistencia, level: Level.iniciante);
      final updated = user.copyWith(goal: Goal.emagrecimento);
      expect(updated.goal,  Goal.emagrecimento);
      expect(updated.level, Level.iniciante); // inalterado
      expect(updated.uid,   user.uid);        // inalterado
    });

    test('permite limpar birthDate explicitamente com null', () {
      final user    = _makeUser(birthDate: DateTime(1990, 5, 15));
      final cleared = user.copyWith(birthDate: null);
      expect(cleared.birthDate, isNull);
      expect(cleared.age, 0);
    });

    test('preserva birthDate existente quando não especificado', () {
      final born = DateTime(1992, 3, 10);
      final user = _makeUser(birthDate: born);
      final copy = user.copyWith(goal: Goal.saude);
      expect(copy.birthDate, born);
    });
  });

  // ─── GoalLabel ──────────────────────────────────────────────────────────────

  group('GoalLabel', () {
    test('todos os goals têm label não vazio', () {
      for (final goal in Goal.values) {
        expect(goal.label, isNotEmpty,
            reason: 'Goal.${goal.name} deve ter label');
      }
    });

    test('labels corretos', () {
      expect(Goal.saude.label,         'Saúde');
      expect(Goal.resistencia.label,   'Resistência');
      expect(Goal.forca.label,         'Força');
      expect(Goal.emagrecimento.label, 'Emagrecimento');
      expect(Goal.desempenho.label,    'Desempenho');
    });
  });

  // ─── ModalityLabel ──────────────────────────────────────────────────────────

  group('ModalityLabel', () {
    test('todas as modalidades têm label e emoji', () {
      for (final m in Modality.values) {
        expect(m.label, isNotEmpty, reason: 'Modality.${m.name} sem label');
        expect(m.emoji, isNotEmpty, reason: 'Modality.${m.name} sem emoji');
      }
    });

    test('musculação não é endurance; demais são', () {
      expect(Modality.musculacao.isEndurance, isFalse);
      expect(Modality.corrida.isEndurance,    isTrue);
      expect(Modality.natacao.isEndurance,    isTrue);
      expect(Modality.ciclismo.isEndurance,   isTrue);
    });
  });

  // ─── LevelLabel ─────────────────────────────────────────────────────────────

  group('LevelLabel', () {
    test('todos os níveis têm label', () {
      for (final l in Level.values) {
        expect(l.label, isNotEmpty, reason: 'Level.${l.name} sem label');
      }
    });

    test('labels corretos', () {
      expect(Level.iniciante.label,     'Iniciante');
      expect(Level.intermediario.label, 'Intermediário');
      expect(Level.avancado.label,      'Avançado');
    });
  });
}
