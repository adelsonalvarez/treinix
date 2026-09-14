// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : test/widget_test.dart
// Camada   : Testes – Smoke test de widgets
// Descrição: Verifica que os widgets utilitários básicos renderizam
//            sem erros. Não requer Firebase nem Provider.
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:treinix/ui/widgets/treinix_button.dart';

void main() {
  group('TreinixButton', () {
    testWidgets('renderiza o label corretamente', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TreinixButton(
            label: 'Gerar Plano',
            icon: Icons.auto_awesome,
            onPressed: () {},
          ),
        ),
      ));

      expect(find.text('Gerar Plano'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('é clicável quando onPressed informado', (tester) async {
      var clicked = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TreinixButton(
            label: 'Salvar',
            onPressed: () => clicked = true,
          ),
        ),
      ));

      await tester.tap(find.text('Salvar'));
      expect(clicked, isTrue);
    });
  });
}
