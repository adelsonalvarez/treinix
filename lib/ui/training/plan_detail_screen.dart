// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/ui/training/plan_detail_screen.dart
// Camada   : Screen – Detalhes do Plano de Treino
// Descrição: Exibe todos os treinos planejados de um plano com informações
//            completas. Permite editar e excluir sessões individualmente,
//            adicionar novas sessões e excluir o plano inteiro.
//            Planos concluídos são exibidos em modo somente leitura.
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/training_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/plan_repository.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../widgets/treinix_app_bar.dart';
import '../widgets/exercise_editor.dart';

class PlanDetailScreen extends StatefulWidget {
  final TrainingPlanModel plan;
  const PlanDetailScreen({super.key, required this.plan});

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  late TrainingPlanModel _plan;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _plan = widget.plan;
  }

  Color get _color => switch (_plan.modality) {
        Modality.corrida    => AppColors.corrida,
        Modality.natacao    => AppColors.natacao,
        Modality.ciclismo   => AppColors.ciclismo,
        Modality.musculacao => AppColors.musculacao,
      };

  bool get _isReadOnly => _plan.isPlanCompleted;

  String _badge(int index) {
    final total = _plan.sessions.length;
    final i     = total > 0 ? index % total : 0;
    return '${i + 1}';
  }

  ({String label, Color bg, Color fg}) get _status {
    if (_plan.isPlanCompleted) {
      return (label: 'Concluído', bg: AppColors.success.withAlpha(30), fg: AppColors.success);
    }
    if (!_plan.isActive) {
      return (label: 'Expirado', bg: AppColors.border, fg: AppColors.textTertiary);
    }
    return (label: 'Ativo', bg: _color.withAlpha(30), fg: _color);
  }

  TrainingPlanModel _planWithSessions(List<TrainingSession> sessions) =>
      TrainingPlanModel(
        id:                 _plan.id,
        userId:             _plan.userId,
        modality:           _plan.modality,
        planType:           _plan.planType,
        title:              _plan.title,
        overview:           _plan.overview,
        sessions:           sessions,
        tip:                _plan.tip,
        generatedAt:        _plan.generatedAt,
        validUntil:         _plan.validUntil,
        hasTapering:        _plan.hasTapering,
        weeksToCompetition: _plan.weeksToCompetition,
        totalSlots:         _plan.totalSlots,
        completedCount:     _plan.completedCount,
        nextSessionIndex:   _plan.nextSessionIndex,
      );

  Future<void> _persistSessions(List<TrainingSession> newSessions) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? _plan.userId;
    if (uid.isEmpty) return;
    setState(() { _saving = true; });
    try {
      final updated = _planWithSessions(newSessions);
      await PlanRepository().updateFull(updated);
      if (mounted) setState(() { _plan = updated; _saving = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _editSession(int index) async {
    final session = _plan.sessions[index];
    final result  = await _showSessionSheet(context, session: session, index: index, modality: _plan.modality);
    if (result == null) return;
    final newSessions = List<TrainingSession>.from(_plan.sessions);
    newSessions[index] = result;
    await _persistSessions(newSessions);
  }

  Future<void> _deleteSession(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir treino?'),
        content: Text(
          '"${_plan.sessions[index].label}" será removido permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final newSessions = List<TrainingSession>.from(_plan.sessions)..removeAt(index);
    await _persistSessions(newSessions);
  }

  Future<void> _addSession() async {
    final result = await _showSessionSheet(context, index: _plan.sessions.length, modality: _plan.modality);
    if (result == null) return;
    final newSessions = List<TrainingSession>.from(_plan.sessions)..add(result);
    await _persistSessions(newSessions);
  }

  Future<void> _deletePlan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir plano?'),
        content: Text(
          '"${_plan.title}" e todas as suas sessões serão removidos '
          'permanentemente.\n\nEssa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final uid = FirebaseAuth.instance.currentUser?.uid ?? _plan.userId;
    if (uid.isEmpty) return;

    setState(() => _saving = true);
    try {
      await PlanRepository().delete(uid, _plan.id);
      if (!mounted) return;
      context.read<HomeViewModel>().removePlan(_plan.modality);
      context.go('/history');
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao excluir: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s        = _status;
    final done     = _plan.completedCount;
    final total    = _plan.totalSlots;
    final progress = total > 0 ? done / total : 0.0;
    final nextIdx  = _plan.sessions.isEmpty
        ? 0
        : _plan.nextSessionIndex % _plan.sessions.length;
    final dateStr  = DateFormat("d MMM yyyy", 'pt_BR').format(_plan.generatedAt);
    final validStr = DateFormat("d MMM yyyy", 'pt_BR').format(_plan.validUntil);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TreinixAppBar(
        screenTitle: _plan.modality.label,
        showAppMenu: true,
      ),
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Card 1: cabeçalho do plano ───────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _color.withAlpha(80), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(_plan.modality.emoji,
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(
                        _plan.title,
                        style: AppTextStyles.heading3,
                      )),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: s.bg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(s.label,
                            style: AppTextStyles.caption.copyWith(
                              color:      s.fg,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Wrap(spacing: 12, children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 13, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text('Criado $dateStr', style: AppTextStyles.caption),
                      ]),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.event_available_outlined,
                            size: 13, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text('Válido até $validStr',
                            style: AppTextStyles.caption),
                      ]),
                    ]),
                    if (total > 0) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value:           progress,
                            minHeight:       6,
                            backgroundColor: _color.withAlpha(30),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(_color),
                          ),
                        )),
                        const SizedBox(width: 10),
                        Text('$done/$total',
                            style: AppTextStyles.caption.copyWith(
                              color:      _color,
                              fontWeight: FontWeight.w700,
                            )),
                        const SizedBox(width: 4),
                        const Text('treinos', style: AppTextStyles.caption),
                      ]),
                    ],
                  ],
                ),
              ),

              // ── Overview IA ──────────────────────────────────────────────
              if (_plan.overview.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.natacao.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.natacao.withAlpha(60)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 16, color: AppColors.natacao),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_plan.overview,
                          style: AppTextStyles.bodySm)),
                    ],
                  ),
                ),
              ],

              // ── Card 2: sessões expandidas ───────────────────────────────
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: Text(
                  'Treinos planejados (${_plan.sessions.length})',
                  style: AppTextStyles.label,
                )),
                if (_isReadOnly)
                  const Row(children: [
                    Icon(Icons.lock_outline,
                        size: 14, color: AppColors.textTertiary),
                    SizedBox(width: 4),
                    Text('Somente leitura',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        )),
                  ]),
              ]),
              const SizedBox(height: 10),

              if (_plan.sessions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    children: [
                      Text('📋', style: TextStyle(fontSize: 32)),
                      SizedBox(height: 8),
                      Text('Nenhum treino cadastrado',
                          style: AppTextStyles.bodySm),
                    ],
                  ),
                )
              else
                ...List.generate(_plan.sessions.length, (i) {
                  final session = _plan.sessions[i];
                  final isNext  = !_isReadOnly &&
                      _plan.isActive &&
                      !_plan.isPlanCompleted &&
                      i == nextIdx;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isNext
                            ? _color.withAlpha(120)
                            : AppColors.border,
                        width: isNext ? 1.5 : 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── Cabeçalho da sessão ─────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 8, 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 46, height: 46,
                                decoration: BoxDecoration(
                                  color: isNext
                                      ? _color
                                      : _color.withAlpha(40),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(child: Text(
                                  _badge(i),
                                  style: TextStyle(
                                    color: isNext
                                        ? Colors.white
                                        : _color,
                                    fontSize:   20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                )),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(child: Text(
                                      session.label,
                                      style: AppTextStyles.bodyMedium,
                                    )),
                                    if (isNext)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _color,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text('Próxima',
                                            style: TextStyle(
                                              color:      Colors.white,
                                              fontSize:   11,
                                              fontWeight: FontWeight.w700,
                                            )),
                                      ),
                                  ]),
                                  const SizedBox(height: 2),
                                  Text(session.focus,
                                      style: AppTextStyles.bodySm),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 2,
                                    children: [
                                      Row(mainAxisSize: MainAxisSize.min, children: [
                                        const Icon(Icons.timer_outlined,
                                            size: 13,
                                            color: AppColors.textTertiary),
                                        const SizedBox(width: 4),
                                        Text('${session.durationMinutes} min',
                                            style: AppTextStyles.caption),
                                      ]),
                                      if (session.steps.isNotEmpty)
                                        Row(mainAxisSize: MainAxisSize.min, children: [
                                          const Icon(Icons.fitness_center,
                                              size: 13,
                                              color: AppColors.textTertiary),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${session.steps.length} '
                                            '${session.steps.length == 1 ? 'exercício' : 'exercícios'}',
                                            style: AppTextStyles.caption,
                                          ),
                                        ]),
                                    ],
                                  ),
                                ],
                              )),
                              // Botões editar / excluir (somente quando não concluído)
                              if (!_isReadOnly) ...[
                                IconButton(
                                  onPressed: _saving
                                      ? null
                                      : () => _editSession(i),
                                  icon: Icon(Icons.edit_outlined,
                                      size: 18, color: _color),
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Editar sessão',
                                ),
                                IconButton(
                                  onPressed: _saving
                                      ? null
                                      : () => _deleteSession(i),
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18, color: AppColors.error),
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Excluir sessão',
                                ),
                              ],
                            ],
                          ),
                        ),

                        // ── Divisor ─────────────────────────────────────
                        const Divider(height: 20, indent: 14, endIndent: 14),

                        // ── Descrição ────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                          child: Text(session.description,
                              style: AppTextStyles.bodySm),
                        ),

                        // ── Lista de exercícios ──────────────────────────
                        if (session.steps.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                            child: Text('Exercícios',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                )),
                          ),
                          const SizedBox(height: 8),
                          ...session.steps.asMap().entries.map((e) {
                            final ex = e.value;
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24, height: 24,
                                    margin: const EdgeInsets.only(
                                        right: 10, top: 1),
                                    decoration: BoxDecoration(
                                      color: _color.withAlpha(30),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(child: Text(
                                      '${e.key + 1}',
                                      style: TextStyle(
                                        color:      _color,
                                        fontSize:   11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )),
                                  ),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(ex.name,
                                          style: AppTextStyles.body),
                                      if (ex.displayLine.isNotEmpty)
                                        Text(ex.displayLine,
                                            style: AppTextStyles.caption),
                                      if (ex.group != null)
                                        Container(
                                          margin: const EdgeInsets.only(top: 2),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: _color.withAlpha(30),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(ex.group!,
                                              style: AppTextStyles.caption
                                                  .copyWith(color: _color)),
                                        ),
                                    ],
                                  )),
                                ],
                              ),
                            );
                          }),
                        ],
                        const SizedBox(height: 14),
                      ],
                    ),
                  );
                }),

              // ── Adicionar sessão (somente quando não concluído) ──────────
              if (!_isReadOnly) ...[
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _addSession,
                  icon:  Icon(Icons.add, color: _color, size: 18),
                  label: Text('Adicionar treino',
                      style: TextStyle(color: _color)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    side: BorderSide(color: _color.withAlpha(120)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],

              // ── Dica ────────────────────────────────────────────────────
              if (_plan.tip.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.warning.withAlpha(60)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          size: 16, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_plan.tip,
                          style: AppTextStyles.bodySm)),
                    ],
                  ),
                ),
              ],

              // ── Excluir plano (somente quando não concluído) ─────────────
              if (!_isReadOnly) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _deletePlan,
                  icon: const Icon(Icons.delete_forever_outlined,
                      size: 18, color: AppColors.error),
                  label: const Text('Excluir plano de treino',
                      style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
              ] else ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
              ],

              // ── Voltar ────────────────────────────────────────────────────
              OutlinedButton.icon(
                onPressed: () => context.go('/history'),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Voltar'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),

        // ── Indicador de salvamento ────────────────────────────────────────
        if (_saving)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ]),
    );
  }
}

// ─── Bottom sheet para editar/criar sessão ────────────────────────────────────

Future<TrainingSession?> _showSessionSheet(
  BuildContext context, {
  TrainingSession? session,
  required int index,
  required Modality modality,
}) =>
    showModalBottomSheet<TrainingSession>(
      context:            context,
      isScrollControlled: true,
      useSafeArea:        true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SessionEditSheet(
          session: session, index: index, modality: modality),
    );

class _SessionEditSheet extends StatefulWidget {
  final TrainingSession? session;
  final int              index;
  final Modality         modality;
  const _SessionEditSheet(
      {this.session, required this.index, required this.modality});

  @override
  State<_SessionEditSheet> createState() => _SessionEditSheetState();
}

class _SessionEditSheetState extends State<_SessionEditSheet> {
  final _formKey    = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _focus;
  late final TextEditingController _duration;
  late final TextEditingController _description;
  late List<ExerciseItem> _exercises;

  @override
  void initState() {
    super.initState();
    final s  = widget.session;
    _label       = TextEditingController(text: s?.label       ?? '');
    _focus       = TextEditingController(text: s?.focus       ?? '');
    _duration    = TextEditingController(
        text: s != null ? '${s.durationMinutes}' : '60');
    _description = TextEditingController(text: s?.description ?? '');
    _exercises   = List<ExerciseItem>.from(s?.steps ?? []);
  }

  @override
  void dispose() {
    _label.dispose();
    _focus.dispose();
    _duration.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(TrainingSession(
      label:           _label.text.trim(),
      focus:           _focus.text.trim(),
      description:     _description.text.trim(),
      durationMinutes: int.tryParse(_duration.text.trim()) ?? 60,
      steps:           _exercises,
    ));
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText:      label,
        hintText:       hint,
        border:         const OutlineInputBorder(),
        isDense:        true,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
      );

  @override
  Widget build(BuildContext context) {
    final isNew = widget.session == null;
    return Padding(
      padding: EdgeInsets.only(
        left:   20,
        right:  20,
        top:    20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              )),

              Text(
                isNew ? 'Novo treino' : 'Editar treino',
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: 16),

              // Nome da sessão
              TextFormField(
                controller: _label,
                decoration: _dec('Nome do treino',
                    hint: 'Ex: Treino 1, Treino 2...'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),

              // Foco / grupos musculares
              TextFormField(
                controller: _focus,
                decoration: _dec(
                  widget.modality == Modality.musculacao
                      ? 'Grupos musculares'
                      : 'Tipo de sessão',
                  hint: widget.modality == Modality.musculacao
                      ? 'Ex: Peito e Tríceps'
                      : 'Ex: Base Z2, Intervalado, Limiar...',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),

              // Duração
              TextFormField(
                controller:   _duration,
                decoration:   _dec('Duração (minutos)'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Informe um número';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Descrição breve da sessão
              TextFormField(
                controller: _description,
                decoration: _dec('Descrição da sessão (opcional)',
                    hint: 'Ex: Objetivo fisiológico desta sessão...'),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // Lista de exercícios estruturados
              ExerciseListSection(
                exercises: _exercises,
                modality:  widget.modality,
                color:     AppColors.primary,
                onChanged: (updated) =>
                    setState(() => _exercises = updated),
              ),
              const SizedBox(height: 20),

              // Botões
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancelar'),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isNew ? 'Adicionar' : 'Salvar',
                    style: const TextStyle(color: Colors.white),
                  ),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
