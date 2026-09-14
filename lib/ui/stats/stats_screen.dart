// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/ui/stats/stats_screen.dart
// Camada   : Screen – Estatísticas / Visualização de Dados
// Descrição: Dashboard com frequência de treinos por semana (últimas 8 semanas),
//            distribuição por modalidade e indicadores de consistência.
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/training_model.dart';
import '../../data/models/user_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/training_viewmodel.dart';
import '../widgets/treinix_app_bar.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uid = context.read<AuthViewModel>().currentUser?.uid;
      if (uid != null) context.read<TrainingViewModel>().loadHistory(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrainingViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const TreinixAppBar(
        screenTitle: 'Estatísticas',
        showAppMenu: true,
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : _StatsBody(history: vm.history, weekStreak: vm.weekStreak),
    );
  }
}

// ─── Corpo das estatísticas ───────────────────────────────────────────────────

class _StatsBody extends StatelessWidget {
  final List<TrainingModel> history;
  final int                 weekStreak;

  const _StatsBody({required this.history, required this.weekStreak});

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<int> _sessionsPerWeek() {
    final now   = DateTime.now();
    final weeks = List<int>.filled(8, 0);
    for (final t in history) {
      if (t.status != TrainingStatus.realizado) continue;
      final diff = now.difference(t.date).inDays;
      final wk   = diff ~/ 7;
      if (wk < 8) weeks[wk]++;
    }
    return weeks.reversed.toList(); // semana mais antiga primeiro
  }

  Map<Modality, int> _byModality() {
    final map = <Modality, int>{};
    for (final t in history) {
      if (t.status != TrainingStatus.realizado) continue;
      map[t.modality] = (map[t.modality] ?? 0) + 1;
    }
    return map;
  }

  int get _totalSessions => history
      .where((t) => t.status == TrainingStatus.realizado)
      .length;

  int get _aiSessions => history
      .where((t) => t.status == TrainingStatus.realizado && t.isAiGenerated)
      .length;

  String _weekLabel(int weeksAgo) {
    if (weeksAgo == 0) return 'Esta\nsem.';
    if (weeksAgo == 1) return 'Sem.\nant.';
    final date = DateTime.now().subtract(Duration(days: weeksAgo * 7));
    return DateFormat('d/MM', 'pt_BR').format(date);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final perWeek   = _sessionsPerWeek();
    final maxWeek   = perWeek.isEmpty ? 1 : perWeek.reduce((a, b) => a > b ? a : b);
    final byMod     = _byModality();
    final total     = _totalSessions;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [

        // ── KPI row ──────────────────────────────────────────────────────────
        Row(children: [
          _KpiCard(value: '$total',       label: 'Treinos\nrealizados',  icon: Icons.fitness_center),
          const SizedBox(width: 10),
          _KpiCard(value: '$weekStreak',  label: 'Dias ativos\nesta semana', icon: Icons.local_fire_department_outlined),
          const SizedBox(width: 10),
          _KpiCard(value: '$_aiSessions', label: 'Planos\ncom IA',       icon: Icons.auto_awesome_outlined),
        ]),

        const SizedBox(height: 24),

        // ── Frequência semanal (gráfico de barras) ────────────────────────────
        const _SectionTitle(title: 'Frequência por semana', subtitle: 'Últimas 8 semanas'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: perWeek.every((v) => v == 0)
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Nenhum treino registrado ainda',
                        style: AppTextStyles.bodySm),
                  ))
              : Column(children: [
                  SizedBox(
                    height: 130,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(8, (i) {
                        final count  = perWeek[i];
                        final height = maxWeek > 0 ? (count / maxWeek) * 110 : 0.0;
                        final isLast = i == 7;
                        final color  = isLast
                            ? AppColors.primary
                            : AppColors.primary.withAlpha(120);
                        return Expanded(child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (count > 0)
                                Text('$count',
                                    style: AppTextStyles.caption.copyWith(
                                        color: isLast
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                        fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOut,
                                height: height.clamp(4.0, 110.0),
                                decoration: BoxDecoration(
                                  color: count > 0 ? color : AppColors.border,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ));
                      }),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(8, (i) => Expanded(
                      child: Text(
                        _weekLabel(7 - i),
                        style: AppTextStyles.caption.copyWith(
                            color: i == 7
                                ? AppColors.primary
                                : AppColors.textTertiary,
                            fontWeight: i == 7
                                ? FontWeight.w600
                                : FontWeight.w400),
                        textAlign: TextAlign.center,
                      ),
                    )),
                  ),
                ]),
        ),

        const SizedBox(height: 24),

        // ── Distribuição por modalidade ────────────────────────────────────────
        if (byMod.isNotEmpty) ...[
          const _SectionTitle(
            title:    'Treinos por modalidade',
            subtitle: 'Quantidade de treinos realizados em cada modalidade',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Column(children: [
              ...Modality.values
                  .where((m) => (byMod[m] ?? 0) > 0)
                  .map((m) {
                final count   = byMod[m]!;
                final pct     = total > 0 ? count / total : 0.0;
                final color   = switch (m) {
                  Modality.corrida    => AppColors.corrida,
                  Modality.natacao    => AppColors.natacao,
                  Modality.ciclismo   => AppColors.ciclismo,
                  Modality.musculacao => AppColors.musculacao,
                };
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(m.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(m.label, style: AppTextStyles.bodyMedium),
                        const Spacer(),
                        Text(
                          '$count de $total ${total == 1 ? 'treino' : 'treinos'}',
                          style: AppTextStyles.caption
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Text('${(pct * 100).round()}%',
                            style: AppTextStyles.caption
                                .copyWith(color: color, fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor: color.withAlpha(30),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ]),
          ),
          const SizedBox(height: 24),
        ],

        // ── Calendário de consistência (últimos 30 dias) ──────────────────────
        const _SectionTitle(title: 'Consistência', subtitle: 'Últimos 30 dias'),
        const SizedBox(height: 12),
        _ConsistencyCalendar(history: history),
      ],
    );
  }
}

// ─── Calendário de pontos (30 dias) ──────────────────────────────────────────

class _ConsistencyCalendar extends StatelessWidget {
  final List<TrainingModel> history;
  const _ConsistencyCalendar({required this.history});

  Set<DateTime> get _trainingDays {
    return history
        .where((t) => t.status == TrainingStatus.realizado)
        .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final days   = _trainingDays;
    final now    = DateTime.now();
    final today  = DateTime(now.year, now.month, now.day);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(30, (i) {
              final date   = today.subtract(Duration(days: 29 - i));
              final active = days.contains(date);
              final isToday = date == today;
              return Tooltip(
                message: DateFormat("d 'de' MMM", 'pt_BR').format(date),
                child: Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary
                        : isToday
                            ? AppColors.primary.withAlpha(40)
                            : AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isToday
                          ? AppColors.primary
                          : AppColors.border,
                      width: isToday ? 1.5 : 0.8,
                    ),
                  ),
                  child: active
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Container(width: 12, height: 12,
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            const Text('Treino realizado', style: AppTextStyles.caption),
            const SizedBox(width: 16),
            Container(width: 12, height: 12,
                decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: AppColors.border))),
            const SizedBox(width: 6),
            const Text('Sem treino', style: AppTextStyles.caption),
          ]),
        ],
      ),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String  value;
  final String  label;
  final IconData icon;
  const _KpiCard({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(
            fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppTextStyles.heading3),
      const SizedBox(height: 2),
      Text(subtitle, style: AppTextStyles.caption),
    ],
  );
}
