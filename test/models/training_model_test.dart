// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : test/models/training_model_test.dart
// Camada   : Testes – Models de Treino
// Descrição: Testes unitários de ExerciseItem, TrainingSession e
//            TrainingPlanModel: serialização, displayLine, progresso e
//            rotação circular de sessões.
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:treinix/data/models/training_model.dart';
import 'package:treinix/data/models/user_model.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

const _s1 = TrainingSession(
  label: 'Treino 1', focus: 'Base aeróbica',
  description: 'Corrida Z2 contínua.', steps: [], durationMinutes: 45,
);
const _s2 = TrainingSession(
  label: 'Treino 2', focus: 'Velocidade',
  description: 'Tiros de 400m.', steps: [], durationMinutes: 50,
);
const _s3 = TrainingSession(
  label: 'Treino 3', focus: 'Regenerativo',
  description: 'Trote leve.', steps: [], durationMinutes: 30,
);

TrainingPlanModel _makePlan({
  int total     = 6,
  int completed = 0,
  int nextIndex = 0,
  List<TrainingSession>? sessions,
}) => TrainingPlanModel(
  id:              'plan-1',
  userId:          'user-1',
  modality:        Modality.corrida,
  planType:        PlanType.semanal,
  title:           'Plano de Corrida',
  overview:        '',
  sessions:        sessions ?? [_s1, _s2, _s3],
  tip:             '',
  generatedAt:     DateTime(2026, 9, 1),
  validUntil:      DateTime(2026, 9, 30),
  totalSlots:      total,
  completedCount:  completed,
  nextSessionIndex: nextIndex,
);

// ─── Testes ──────────────────────────────────────────────────────────────────

void main() {

  // ─── ExerciseItem.isEmpty ─────────────────────────────────────────────────

  group('ExerciseItem.isEmpty', () {
    test('true para nome em branco', () {
      expect(const ExerciseItem(name: '').isEmpty, isTrue);
      expect(const ExerciseItem(name: '   ').isEmpty, isTrue);
    });

    test('false para nome preenchido', () {
      expect(const ExerciseItem(name: 'Agachamento').isEmpty, isFalse);
    });
  });

  // ─── ExerciseItem.displayLine ─────────────────────────────────────────────

  group('ExerciseItem.displayLine', () {
    test('vazio quando sem campos opcionais', () {
      expect(const ExerciseItem(name: 'Supino').displayLine, isEmpty);
    });

    test('exibe sets × load quando ambos presentes', () {
      const ex = ExerciseItem(name: 'Supino', sets: 3, load: '80kg');
      expect(ex.displayLine, contains('3×'));
      expect(ex.displayLine, contains('80kg'));
    });

    test('exibe "séries" quando só sets informado', () {
      const ex = ExerciseItem(name: 'Supino', sets: 4);
      expect(ex.displayLine, contains('séries'));
      expect(ex.displayLine, isNot(contains('×')));
    });

    test('exibe load isolado quando sem sets', () {
      const ex = ExerciseItem(name: 'Prancha', load: '60s');
      expect(ex.displayLine, '60s');
    });

    test('inclui descanso com prefixo "Desc:"', () {
      const ex = ExerciseItem(name: 'Agachamento', rest: '90s');
      expect(ex.displayLine, contains('Desc: 90s'));
    });

    test('usa · como separador entre múltiplos campos', () {
      const ex = ExerciseItem(
        name: 'Supino', sets: 3, load: '80kg', rest: '60s');
      expect(ex.displayLine.contains('·'), isTrue);
    });

    test('inclui reps quando informado', () {
      const ex = ExerciseItem(name: 'Curl', sets: 3, reps: '12/10/8');
      expect(ex.displayLine, contains('12/10/8 rep'));
    });
  });

  // ─── ExerciseItem – backward compatibility ────────────────────────────────

  group('ExerciseItem.fromMap – compatibilidade', () {
    test('aceita String (formato antigo)', () {
      final ex = ExerciseItem.fromMap('Corrida leve 20 min');
      expect(ex.name, 'Corrida leve 20 min');
      expect(ex.sets,  isNull);
      expect(ex.load,  isNull);
    });

    test('aceita Map estruturado (formato novo)', () {
      final ex = ExerciseItem.fromMap({
        'name': 'Agachamento',
        'sets': 3,
        'reps': '12',
        'load': '60kg',
        'rest': '90s',
        'notes': 'Joelhos alinhados',
      });
      expect(ex.name,  'Agachamento');
      expect(ex.sets,  3);
      expect(ex.reps,  '12');
      expect(ex.load,  '60kg');
      expect(ex.rest,  '90s');
      expect(ex.notes, 'Joelhos alinhados');
    });

    test('toMap → fromMap round-trip preserva todos os campos', () {
      const original = ExerciseItem(
        name: 'Desenvolvimento', sets: 4, reps: '10', load: '40kg',
        rest: '60s', group: 'Bi-set A', notes: 'Cotovelos fechados',
      );
      final restored = ExerciseItem.fromMap(original.toMap());
      expect(restored.name,  original.name);
      expect(restored.sets,  original.sets);
      expect(restored.reps,  original.reps);
      expect(restored.load,  original.load);
      expect(restored.rest,  original.rest);
      expect(restored.group, original.group);
      expect(restored.notes, original.notes);
    });

    test('toMap não inclui campos nulos', () {
      const ex = ExerciseItem(name: 'Prancha');
      final map = ex.toMap();
      expect(map.containsKey('sets'),  isFalse);
      expect(map.containsKey('reps'),  isFalse);
      expect(map.containsKey('load'),  isFalse);
      expect(map.containsKey('rest'),  isFalse);
      expect(map.containsKey('group'), isFalse);
      expect(map.containsKey('notes'), isFalse);
    });
  });

  // ─── TrainingSession.fromMap ──────────────────────────────────────────────

  group('TrainingSession.fromMap', () {
    test('desserializa campos corretamente', () {
      final map = {
        'label':           'Treino 1',
        'focus':           'Base aeróbica',
        'description':     'Corrida leve Z2.',
        'durationMinutes': 45,
        'steps': [
          {'name': 'Aquecimento', 'load': '10 min'},
          'Corrida Z2 30 min',       // formato antigo (String)
        ],
      };
      final session = TrainingSession.fromMap(map);
      expect(session.label,           'Treino 1');
      expect(session.focus,           'Base aeróbica');
      expect(session.durationMinutes, 45);
      expect(session.steps.length,    2);
      expect(session.steps[0].name,   'Aquecimento');
      expect(session.steps[1].name,   'Corrida Z2 30 min');
    });

    test('steps com nome vazio são filtrados', () {
      final map = {
        'label': 'Treino 2', 'focus': '', 'description': '',
        'durationMinutes': 30,
        'steps': ['', ' ', 'Passada longa 5×100m'],
      };
      final session = TrainingSession.fromMap(map);
      expect(session.steps.length, 1);
      expect(session.steps.first.name, 'Passada longa 5×100m');
    });

    test('toMap → fromMap round-trip preserva campos', () {
      const s = TrainingSession(
        label: 'Treino A', focus: 'Força', description: 'Peito e tríceps.',
        steps: [ExerciseItem(name: 'Supino', sets: 3, load: '80kg')],
        durationMinutes: 60,
      );
      final restored = TrainingSession.fromMap(s.toMap());
      expect(restored.label,           s.label);
      expect(restored.focus,           s.focus);
      expect(restored.durationMinutes, s.durationMinutes);
      expect(restored.steps.length,    1);
      expect(restored.steps.first.name, 'Supino');
    });
  });

  // ─── TrainingPlanModel – progresso ────────────────────────────────────────

  group('TrainingPlanModel.remainingSessions', () {
    test('total − concluídos', () {
      expect(_makePlan(total: 6, completed: 2).remainingSessions, 4);
    });

    test('nunca negativo (clamp)', () {
      expect(_makePlan(total: 3, completed: 5).remainingSessions, 0);
    });

    test('zero quando completedCount == totalSlots', () {
      expect(_makePlan(total: 6, completed: 6).remainingSessions, 0);
    });
  });

  group('TrainingPlanModel.isPlanCompleted', () {
    test('false quando ainda há treinos pendentes', () {
      expect(_makePlan(total: 6, completed: 5).isPlanCompleted, isFalse);
    });

    test('true quando completedCount == totalSlots', () {
      expect(_makePlan(total: 6, completed: 6).isPlanCompleted, isTrue);
    });

    test('true quando completedCount > totalSlots', () {
      expect(_makePlan(total: 3, completed: 4).isPlanCompleted, isTrue);
    });

    test('false quando totalSlots == 0 (plano sem slots)', () {
      expect(_makePlan(total: 0, completed: 0).isPlanCompleted, isFalse);
    });
  });

  // ─── TrainingPlanModel – rotação de sessões ───────────────────────────────

  group('TrainingPlanModel.nextSession', () {
    test('retorna null quando não há sessões', () {
      expect(_makePlan(sessions: []).nextSession, isNull);
    });

    test('retorna a sessão correta pelo índice', () {
      expect(_makePlan(nextIndex: 0).nextSession?.label, 'Treino 1');
      expect(_makePlan(nextIndex: 1).nextSession?.label, 'Treino 2');
      expect(_makePlan(nextIndex: 2).nextSession?.label, 'Treino 3');
    });

    test('rotação circular: índice 3 com 3 sessões → Treino 1', () {
      expect(_makePlan(nextIndex: 3).nextSession?.label, 'Treino 1');
    });

    test('rotação circular: índice 7 com 3 sessões → Treino 2 (7 % 3 = 1)', () {
      expect(_makePlan(nextIndex: 7).nextSession?.label, 'Treino 2');
    });
  });

  // ─── TrainingPlanModel – isActive ─────────────────────────────────────────

  group('TrainingPlanModel.isActive', () {
    test('true quando validUntil está no futuro', () {
      final plan = _makePlan().copyWith(); // validUntil = 2026-09-30
      // Se today < 2026-09-30 → true; se já passou, este teste é documentativo
      final expected = DateTime.now().isBefore(DateTime(2026, 9, 30));
      expect(plan.isActive, expected);
    });

    test('false quando validUntil está no passado', () {
      final plan = TrainingPlanModel(
        id: 'p', userId: 'u', modality: Modality.corrida,
        planType: PlanType.semanal, title: '', overview: '',
        sessions: const [], tip: '',
        generatedAt: DateTime(2020, 1, 1),
        validUntil:  DateTime(2020, 1, 31),  // passado definitivo
      );
      expect(plan.isActive, isFalse);
    });
  });
}
