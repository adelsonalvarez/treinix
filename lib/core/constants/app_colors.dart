// =============================================================================
// Projeto    : Treinix – Treinador Digital para Atletas Amadores
// Arquivo    : lib/core/constants/app_colors.dart
// Camada     : Constantes – Cores
// Descrição  : Paleta de cores do design system Treinix
// -----------------------------------------------------------------------------
// Autor      : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso      : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano        : 2026
// =============================================================================

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primária — laranja Treinix
  static const primary = Color(0xFFE8593C);
  static const primaryDark = Color(0xFFC44227);
  static const primaryLight = Color(0xFFFAECE7);

  // Neutros
  static const background = Color(0xFFF8F7F4);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF1EFE8);
  static const border = Color(0xFFE0DED6);

  // Texto
  static const textPrimary = Color(0xFF1A1A18);
  static const textSecondary = Color(0xFF5F5E5A);
  static const textTertiary = Color(0xFF888780);

  // Modalidades
  static const corrida = Color(0xFFE8593C);   // laranja
  static const natacao = Color(0xFF378ADD);   // azul
  static const ciclismo = Color(0xFF639922);  // verde
  static const musculacao = Color(0xFF7F77DD); // roxo

  // Semânticas
  static const success = Color(0xFF1D9E75);
  static const warning = Color(0xFFEF9F27);
  static const error = Color(0xFFE24B4A);
  static const info = Color(0xFF378ADD);

  // Gradiente do splash
  static const List<Color> splashGradient = [
    Color(0xFFE8593C),
    Color(0xFFD85A30),
  ];
}