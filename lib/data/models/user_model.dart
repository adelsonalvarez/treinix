// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/data/models/user_model.dart
// Camada   : Model – Usuário
// Descrição: Modelo de dados do usuário com enums de modalidade, nível e
//            objetivo. Competição é inferida de goal == desempenho.
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

enum Modality { corrida, natacao, ciclismo, musculacao }
enum Level    { iniciante, intermediario, avancado }
enum Goal     { saude, resistencia, forca, emagrecimento, desempenho }

extension ModalityLabel on Modality {
  String get label => switch (this) {
        Modality.corrida    => 'Corrida',
        Modality.natacao    => 'Natação',
        Modality.ciclismo   => 'Ciclismo',
        Modality.musculacao => 'Musculação',
      };
  String get emoji => switch (this) {
        Modality.corrida    => '🏃',
        Modality.natacao    => '🏊',
        Modality.ciclismo   => '🚴',
        Modality.musculacao => '🏋️',
      };
  bool get isEndurance => this != Modality.musculacao;
}

extension LevelLabel on Level {
  String get label => switch (this) {
        Level.iniciante     => 'Iniciante',
        Level.intermediario => 'Intermediário',
        Level.avancado      => 'Avançado',
      };
}

extension GoalLabel on Goal {
  String get label => switch (this) {
        Goal.saude         => 'Saúde',
        Goal.resistencia   => 'Resistência',
        Goal.forca         => 'Força',
        Goal.emagrecimento => 'Emagrecimento',
        Goal.desempenho    => 'Desempenho',
      };
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final DateTime? birthDate;
  final List<Modality> modalities;
  final Level  level;
  final Goal   goal;
  final DateTime? competitionDate;     // null quando goal != desempenho
  final String    competitionName;     // nome da prova (opcional)
  final bool      onboardingDone;
  final DateTime  createdAt;
  // LGPD – registro de consentimento explícito (Art. 7, I)
  final bool      consentGiven;
  final DateTime? consentDate;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.birthDate,
    required this.modalities,
    required this.level,
    required this.goal,
    this.competitionDate,
    this.competitionName = '',
    this.onboardingDone  = false,
    required this.createdAt,
    this.consentGiven    = false,
    this.consentDate,
  });

  /// Idade calculada automaticamente a partir da data de nascimento.
  int get age {
    if (birthDate == null) return 0;
    final today = DateTime.now();
    int years = today.year - birthDate!.year;
    if (today.month < birthDate!.month ||
        (today.month == birthDate!.month && today.day < birthDate!.day)) {
      years--;
    }
    return years < 0 ? 0 : years;
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid:        doc.id,
      name:       d['name']  ?? '',
      email:      d['email'] ?? '',
      birthDate:  (d['birthDate'] as Timestamp?)?.toDate(),
      modalities: (d['modalities'] as List<dynamic>? ?? [])
          .map((m) => Modality.values.firstWhere((e) => e.name == m,
              orElse: () => Modality.corrida))
          .toList(),
      level: Level.values.firstWhere(
          (e) => e.name == d['level'], orElse: () => Level.iniciante),
      goal: Goal.values.firstWhere(
          (e) => e.name == d['goal'], orElse: () => Goal.resistencia),
      competitionDate: (d['competitionDate'] as Timestamp?)?.toDate(),
      competitionName: d['competitionName'] ?? '',
      onboardingDone:  d['onboardingDone']  ?? false,
      createdAt:       (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      consentGiven:    d['consentGiven']  ?? false,
      consentDate:     (d['consentDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name':            name,
        'email':           email,
        'birthDate':       birthDate != null
            ? Timestamp.fromDate(birthDate!)
            : null,
        'modalities':      modalities.map((m) => m.name).toList(),
        'level':           level.name,
        'goal':            goal.name,
        'competitionDate': competitionDate != null
            ? Timestamp.fromDate(competitionDate!)
            : null,
        'competitionName': competitionName,
        'onboardingDone':  onboardingDone,
        'createdAt':       Timestamp.fromDate(createdAt),
        'consentGiven':    consentGiven,
        'consentDate':     consentDate != null
            ? Timestamp.fromDate(consentDate!)
            : null,
      };

  // Sentinel para distinguir "não informado" de "null explícito" em copyWith.
  static const _keep = Object();

  UserModel copyWith({
    String? name,
    Object? birthDate       = _keep,
    List<Modality>? modalities,
    Level? level,
    Goal? goal,
    Object? competitionDate = _keep,
    String? competitionName,
    bool? onboardingDone,
    bool? consentGiven,
    Object? consentDate     = _keep,
  }) =>
      UserModel(
        uid:             uid,
        name:            name            ?? this.name,
        email:           email,
        birthDate:       identical(birthDate, _keep)
            ? this.birthDate
            : birthDate as DateTime?,
        modalities:      modalities      ?? this.modalities,
        level:           level           ?? this.level,
        goal:            goal            ?? this.goal,
        competitionDate: identical(competitionDate, _keep)
            ? this.competitionDate
            : competitionDate as DateTime?,
        competitionName: competitionName ?? this.competitionName,
        onboardingDone:  onboardingDone  ?? this.onboardingDone,
        createdAt:       createdAt,
        consentGiven:    consentGiven    ?? this.consentGiven,
        consentDate:     identical(consentDate, _keep)
            ? this.consentDate
            : consentDate as DateTime?,
      );

  /// Semanas até a competição (null se não houver data)
  int? get weeksToCompetition {
    if (competitionDate == null) return null;
    final diff = competitionDate!.difference(DateTime.now()).inDays;
    return (diff / 7).ceil();
  }

  bool get hasCompetition =>
      goal == Goal.desempenho && competitionDate != null;
}
