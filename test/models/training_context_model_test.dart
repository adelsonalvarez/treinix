// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : test/models/training_context_model_test.dart
// Camada   : Testes – Model de Contexto de Treino
// Descrição: Testes unitários de TrainingContextModel: serialização toMap,
//            trim de freeText e labels dos enums TrainingFocus/DesiredIntensity.
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:treinix/data/models/training_context_model.dart';
import 'package:treinix/data/models/user_model.dart';

void main() {

  // ─── TrainingContextModel.toMap ───────────────────────────────────────────

  group('TrainingContextModel.toMap', () {
    test('serializa todos os campos corretamente', () {
      const ctx = TrainingContextModel(
        modality:        Modality.natacao,
        durationMinutes: 60,
        focus:           TrainingFocus.velocidade,
        intensity:       DesiredIntensity.intenso,
        sessionsCount:   4,
        freeText:        'Quero focar em sprints.',
      );
      final map = ctx.toMap();
      expect(map['modality'],        'natacao');
      expect(map['durationMinutes'], 60);
      expect(map['focus'],           'velocidade');
      expect(map['intensity'],       'intenso');
      expect(map['sessionsCount'],   4);
      expect(map['freeText'],        'Quero focar em sprints.');
    });

    test('aplica trim no freeText antes de serializar', () {
      const ctx = TrainingContextModel(
        modality:        Modality.corrida,
        durationMinutes: 45,
        focus:           TrainingFocus.resistencia,
        intensity:       DesiredIntensity.moderado,
        freeText:        '  texto com espaços  ',
      );
      expect(ctx.toMap()['freeText'], 'texto com espaços');
    });

    test('freeText vazio permanece vazio após trim', () {
      const ctx = TrainingContextModel(
        modality:        Modality.ciclismo,
        durationMinutes: 90,
        focus:           TrainingFocus.tecnica,
        intensity:       DesiredIntensity.leve,
      );
      expect(ctx.toMap()['freeText'], '');
    });

    test('usa valor padrão de sessionsCount (3) quando não informado', () {
      const ctx = TrainingContextModel(
        modality:        Modality.musculacao,
        durationMinutes: 60,
        focus:           TrainingFocus.forca,
        intensity:       DesiredIntensity.moderado,
      );
      expect(ctx.toMap()['sessionsCount'], 3);
    });

    test('serializa todas as modalidades corretamente', () {
      for (final m in Modality.values) {
        final ctx = TrainingContextModel(
          modality:        m,
          durationMinutes: 45,
          focus:           TrainingFocus.resistencia,
          intensity:       DesiredIntensity.moderado,
        );
        expect(ctx.toMap()['modality'], m.name);
      }
    });
  });

  // ─── TrainingFocusLabel ───────────────────────────────────────────────────

  group('TrainingFocusLabel', () {
    test('todos os focos têm label não vazio', () {
      for (final f in TrainingFocus.values) {
        expect(f.label, isNotEmpty,
            reason: 'TrainingFocus.${f.name} deve ter label');
      }
    });

    test('labels corretos', () {
      expect(TrainingFocus.velocidade.label,   'Velocidade');
      expect(TrainingFocus.resistencia.label,  'Resistência');
      expect(TrainingFocus.tecnica.label,      'Técnica');
      expect(TrainingFocus.regenerativo.label, 'Regenerativo');
      expect(TrainingFocus.forca.label,        'Força');
    });
  });

  // ─── DesiredIntensityLabel ────────────────────────────────────────────────

  group('DesiredIntensityLabel', () {
    test('todas as intensidades têm label não vazio', () {
      for (final i in DesiredIntensity.values) {
        expect(i.label, isNotEmpty,
            reason: 'DesiredIntensity.${i.name} deve ter label');
      }
    });

    test('labels corretos', () {
      expect(DesiredIntensity.leve.label,    'Leve');
      expect(DesiredIntensity.moderado.label, 'Moderado');
      expect(DesiredIntensity.intenso.label,  'Intenso');
    });
  });
}
