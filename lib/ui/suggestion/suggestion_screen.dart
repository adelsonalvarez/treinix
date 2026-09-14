// =============================================================================
// Projeto    : Treinix – Treinador Digital para Atletas Amadores
// Arquivo    : lib/ui/suggestion/suggestion_screen.dart
// Camada     : Screen – Sugestão / Plano de Treino
// Descrição  : Exibição estilo Tecnofit: próximo treino em destaque,
//              progresso X/Y, rotação A→B→C→D automática ao concluir.
// -----------------------------------------------------------------------------
// Autor      : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso      : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano        : 2026
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/user_model.dart';
import '../../data/models/training_model.dart';
import '../../data/models/training_context_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/training_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../viewmodels/suggestion_viewmodel.dart';
import '../widgets/treinix_app_bar.dart';
import '../widgets/treinix_button.dart';
import '../widgets/modality_chip.dart';

class SuggestionScreen extends StatefulWidget {
  const SuggestionScreen({super.key});
  @override
  State<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  Modality         _modality      = Modality.corrida;
  int              _duration      = 45;
  TrainingFocus    _focus         = TrainingFocus.resistencia;
  DesiredIntensity _intensity     = DesiredIntensity.moderado;
  int              _sessionsCount = 3;
  final _freeTextCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await context.read<UserViewModel>().load(uid);
      if (mounted) {
        final user = context.read<UserViewModel>().user;
        if (user != null && user.modalities.isNotEmpty) {
          setState(() => _modality = user.modalities.first);
        }
        await context.read<SuggestionViewModel>().loadActivePlan(uid, _modality);
      }
    });
  }

  @override
  void dispose() { _freeTextCtrl.dispose(); super.dispose(); }

  Future<void> _onModalityChanged(Modality m) async {
    setState(() => _modality = m);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await context.read<SuggestionViewModel>().loadActivePlan(uid, m);
    }
  }

  Future<void> _generate() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;
    await firebaseUser.getIdToken(true);
    if (!mounted) return;

    final user = context.read<UserViewModel>().user;
    if (user == null) return;

    final vm  = context.read<SuggestionViewModel>();
    final ctx = TrainingContextModel(
      modality:        _modality,
      durationMinutes: _duration,
      focus:           _focus,
      intensity:       _intensity,
      sessionsCount:   _sessionsCount,
      freeText:        _freeTextCtrl.text,
    );

    await vm.generatePlan(user: user, context: ctx);
    if (!mounted) return;

    // Após geração bem-sucedida → redireciona para a tela de treino.
    if (vm.status == PlanStatus.active && vm.activePlan != null) {
      context.push('/training/${_modality.name}', extra: vm.activePlan);
    }
  }

  // Conclui a sessão atual e salva no histórico + home dashboard.
  Future<void> _onSessionCompleted() async {
    final vm   = context.read<SuggestionViewModel>();
    final plan = vm.activePlan;
    if (plan == null || plan.sessions.isEmpty) return;

    // Captura a sessão ANTES de avançar o índice.
    final session = plan.sessions[plan.nextSessionIndex % plan.sessions.length];

    await vm.completeSession();
    if (!mounted) return;

    // Registra no histórico para aparecer no Histórico e na Home.
    final uid = context.read<AuthViewModel>().currentUser?.uid
        ?? FirebaseAuth.instance.currentUser?.uid
        ?? '';
    if (uid.isNotEmpty) {
      try {
        await context.read<TrainingViewModel>().logTraining(
          uid:             uid,
          modality:        plan.modality,
          title:           '${session.label} — ${plan.modality.label}',
          description:     session.focus,
          durationMinutes: session.durationMinutes,
          intensity:       _intensityFromFocus(session.focus),
          isAiGenerated:   true,
        );
      } catch (e) {
        debugPrint('[SuggestionScreen] logTraining error: $e');
      }
    }

    if (!mounted) return;

    // Atualiza o card na Home sem recarregar tudo.
    final updated = vm.activePlan;
    if (updated != null) {
      context.read<HomeViewModel>().markSessionComplete(updated);
    }
  }

  static IntensityLevel _intensityFromFocus(String focus) {
    final f = focus.toLowerCase();
    if (f.contains('regenerat') || f.contains('leve') ||
        f.contains('z1') || f.contains('base')) { return IntensityLevel.leve; }
    if (f.contains('tiro') || f.contains('interval') ||
        f.contains('z4') || f.contains('z5') || f.contains('intenso')) {
      return IntensityLevel.intenso;
    }
    return IntensityLevel.moderado;
  }

  @override
  Widget build(BuildContext context) {
    final vm     = context.watch<SuggestionViewModel>();
    final userVm = context.watch<UserViewModel>();
    final modalities = userVm.user?.modalities.isEmpty ?? true
        ? Modality.values.toList()
        : userVm.user!.modalities;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TreinixAppBar(
        screenTitle:  'Plano',
        showAppMenu:  true,
        action: vm.isPlanCompleted
            ? TextButton(
                onPressed: () =>
                    context.read<SuggestionViewModel>().reset(),
                child: const Text('Novo plano'),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Modalidade', style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            Column(
              children: [
                for (int i = 0; i < modalities.length; i += 2)
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: i + 2 < modalities.length ? 10 : 0),
                    child: Row(children: [
                      Expanded(child: ModalityChip(
                        modality: modalities[i],
                        selected: _modality == modalities[i],
                        onTap: () => _onModalityChanged(modalities[i]),
                      )),
                      if (i + 1 < modalities.length) ...[
                        const SizedBox(width: 10),
                        Expanded(child: ModalityChip(
                          modality: modalities[i + 1],
                          selected: _modality == modalities[i + 1],
                          onTap: () => _onModalityChanged(modalities[i + 1]),
                        )),
                      ] else
                        const Expanded(child: SizedBox()),
                    ]),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (vm.isLoading)
              _LoadingCard(modality: _modality)
            else if (vm.isPlanCompleted)
              _CompletedCard(
                onNewPlan: () => context.read<SuggestionViewModel>().reset(),
              )
            else if (vm.hasPlan)
              _ActivePlanCard(
                plan:      vm.activePlan!,
                modality:  _modality,
                onComplete: _onSessionCompleted,
              )
            else
              _GenerateForm(
                modality:              _modality,
                duration:              _duration,
                focus:                 _focus,
                intensity:             _intensity,
                sessionsCount:         _sessionsCount,
                freeTextCtrl:          _freeTextCtrl,
                errorMessage:          vm.errorMessage,
                onDurationChanged:     (v) => setState(() => _duration      = v),
                onFocusChanged:        (f) => setState(() => _focus         = f),
                onIntensityChanged:    (i) => setState(() => _intensity     = i),
                onSessionsCountChanged:(s) => setState(() => _sessionsCount = s),
                onGenerate:            _generate,
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ─── Plano concluído ──────────────────────────────────────────────────────────

class _CompletedCard extends StatelessWidget {
  final VoidCallback onNewPlan;
  const _CompletedCard({required this.onNewPlan});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.success.withAlpha(80)),
    ),
    child: Column(children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          color: AppColors.success.withAlpha(30),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.emoji_events_rounded,
            color: AppColors.success, size: 36),
      ),
      const SizedBox(height: 16),
      Text('Plano concluído!',
          style: AppTextStyles.heading2.copyWith(color: AppColors.success)),
      const SizedBox(height: 8),
      const Text(
        'Parabéns! Você completou todos os treinos do plano. '
        'Gere um novo para continuar evoluindo.',
        style: AppTextStyles.bodySm,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      TreinixButton(
        label: 'Gerar novo plano',
        icon: Icons.auto_awesome,
        onPressed: onNewPlan,
      ),
    ]),
  );
}

// ─── Plano ativo – estilo Tecnofit ────────────────────────────────────────────

class _ActivePlanCard extends StatefulWidget {
  final TrainingPlanModel      plan;
  final Modality               modality;
  final Future<void> Function() onComplete;
  const _ActivePlanCard({
    required this.plan,
    required this.modality,
    required this.onComplete,
  });
  @override
  State<_ActivePlanCard> createState() => _ActivePlanCardState();
}

class _ActivePlanCardState extends State<_ActivePlanCard> {
  bool _showAll    = false;
  bool _completing = false;

  Color get _color => switch (widget.modality) {
        Modality.corrida    => AppColors.corrida,
        Modality.natacao    => AppColors.natacao,
        Modality.ciclismo   => AppColors.ciclismo,
        Modality.musculacao => AppColors.musculacao,
      };

  String _badge(int index) {
    final len = widget.plan.sessions.length;
    final i   = len > 0 ? index % len : 0;
    return '${i + 1}';
  }

  Future<void> _complete() async {
    if (_completing) return;
    setState(() => _completing = true);
    await widget.onComplete();
    if (mounted) setState(() => _completing = false);
  }

  @override
  Widget build(BuildContext context) {
    final plan     = widget.plan;
    final next     = plan.nextSession;
    final total    = plan.totalSlots;
    final done     = plan.completedCount;
    final progress = total > 0 ? done / total : 0.0;
    final validStr = DateFormat("d 'de' MMMM", 'pt_BR').format(plan.validUntil);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Banner de progresso ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _color.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _color.withAlpha(60)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(plan.title, style: AppTextStyles.bodyMedium)),
                if (plan.hasTapering)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(38),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Tapering 🏁',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.warning, fontWeight: FontWeight.w600)),
                  ),
              ]),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text('Válido até $validStr', style: AppTextStyles.caption),
                  ]),
                  if (total > 0)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.fitness_center_outlined,
                          size: 13, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        plan.remainingSessions == 1
                            ? '1 treino restante'
                            : '${plan.remainingSessions} treinos restantes',
                        style: AppTextStyles.caption,
                      ),
                    ]),
                ],
              ),
              if (total > 0) ...[
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: _color.withAlpha(40),
                        valueColor: AlwaysStoppedAnimation<Color>(_color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('$done/$total',
                      style: AppTextStyles.caption
                          .copyWith(fontWeight: FontWeight.w600)),
                ]),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Próximo treino ───────────────────────────────────────────────
        if (next != null) ...[
          const Text('Próximo treino', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _color.withAlpha(100), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge + label + duração
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: _color,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Center(
                      child: Text(
                        _badge(plan.nextSessionIndex),
                        style: const TextStyle(
                          color: Colors.white, fontSize: 22,
                          fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(next.label, style: AppTextStyles.bodyMedium),
                      Text(next.focus,  style: AppTextStyles.caption),
                    ],
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${next.durationMinutes} min',
                        style: AppTextStyles.caption
                            .copyWith(fontWeight: FontWeight.w600)),
                  ),
                ]),

                const Divider(height: 24),

                Text(next.description, style: AppTextStyles.bodySm),
                const SizedBox(height: 14),

                // Passos
                ...next.steps.asMap().entries.map((e) {
                  final ex = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 24, height: 24,
                        margin: const EdgeInsets.only(right: 10, top: 1),
                        decoration: BoxDecoration(
                          color: _color.withAlpha(26),
                          shape: BoxShape.circle,
                        ),
                        child: Center(child: Text('${e.key + 1}',
                            style: TextStyle(
                              color: _color, fontSize: 11,
                              fontWeight: FontWeight.w700))),
                      ),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ex.name, style: AppTextStyles.body),
                          if (ex.displayLine.isNotEmpty)
                            Text(ex.displayLine, style: AppTextStyles.caption),
                        ],
                      )),
                    ]),
                  );
                }),

                // Dica
                if (plan.tip.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.warning.withAlpha(60)),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.lightbulb_outline,
                          color: AppColors.warning, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(plan.tip, style: AppTextStyles.caption)),
                    ]),
                  ),
                ],

                const SizedBox(height: 20),

                // Botão concluir
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _completing ? null : _complete,
                    icon: _completing
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline,
                            color: Colors.white),
                    label: Text(
                      _completing ? 'Salvando...' : 'Concluí este treino',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _color,
                      disabledBackgroundColor: _color.withAlpha(120),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // ── Ver todos os treinos ─────────────────────────────────────────
        GestureDetector(
          onTap: () => setState(() => _showAll = !_showAll),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              const Text(
                'Todos os treinos do plano',
                style: AppTextStyles.bodyMedium,
              ),
              const Spacer(),
              Text('${plan.sessions.length} treinos', style: AppTextStyles.caption),
              const SizedBox(width: 6),
              Icon(_showAll ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textTertiary, size: 20),
            ]),
          ),
        ),

        if (_showAll) ...[
          const SizedBox(height: 10),
          ...plan.sessions.asMap().entries.map((e) => _SessionTile(
            session: e.value,
            color:   _color,
            badge:   _badge(e.key),
            isNext:  e.key ==
                plan.nextSessionIndex % plan.sessions.length,
          )),
        ],
      ],
    );
  }
}

// ─── Tile de sessão expandível ────────────────────────────────────────────────

class _SessionTile extends StatefulWidget {
  final TrainingSession session;
  final Color  color;
  final String badge;
  final bool   isNext;
  const _SessionTile({
    required this.session,
    required this.color,
    this.badge  = '',
    this.isNext = false,
  });
  @override
  State<_SessionTile> createState() => _SessionTileState();
}

class _SessionTileState extends State<_SessionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: widget.isNext ? widget.color.withAlpha(120) : AppColors.border,
        width: widget.isNext ? 1.5 : 0.8,
      ),
    ),
    child: Column(children: [
      InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: widget.color.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(
                widget.badge.isNotEmpty
                    ? widget.badge
                    : (widget.session.label.isNotEmpty
                        ? widget.session.label[0]
                        : '?'),
                style: TextStyle(
                  color: widget.color, fontWeight: FontWeight.w700, fontSize: 18),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(widget.session.label,
                        style: AppTextStyles.bodyMedium),
                  ),
                  if (widget.isNext)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.color.withAlpha(26),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('próximo',
                          style: AppTextStyles.caption.copyWith(
                            color: widget.color,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                ]),
                Text(widget.session.focus, style: AppTextStyles.caption),
              ],
            )),
            Row(children: [
              Text('${widget.session.durationMinutes} min',
                  style: AppTextStyles.caption),
              const SizedBox(width: 6),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textTertiary, size: 20),
            ]),
          ]),
        ),
      ),
      if (_expanded)
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const SizedBox(height: 8),
              Text(widget.session.description, style: AppTextStyles.bodySm),
              const SizedBox(height: 12),
              ...widget.session.steps.asMap().entries.map((e) {
                final ex = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 22, height: 22,
                      margin: const EdgeInsets.only(right: 8, top: 1),
                      decoration: BoxDecoration(
                          color: widget.color, shape: BoxShape.circle),
                      child: Center(child: Text('${e.key + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ))),
                    ),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ex.name, style: AppTextStyles.body),
                        if (ex.displayLine.isNotEmpty)
                          Text(ex.displayLine, style: AppTextStyles.caption),
                      ],
                    )),
                  ]),
                );
              }),
            ],
          ),
        ),
    ]),
  );
}

// ─── Formulário de geração ────────────────────────────────────────────────────

class _GenerateForm extends StatelessWidget {
  final Modality modality;
  final int duration;
  final TrainingFocus focus;
  final DesiredIntensity intensity;
  final int sessionsCount;
  final TextEditingController freeTextCtrl;
  final String? errorMessage;
  final void Function(int) onDurationChanged;
  final void Function(TrainingFocus) onFocusChanged;
  final void Function(DesiredIntensity) onIntensityChanged;
  final void Function(int) onSessionsCountChanged;
  final VoidCallback onGenerate;

  const _GenerateForm({
    required this.modality, required this.duration, required this.focus,
    required this.intensity, required this.sessionsCount,
    required this.freeTextCtrl, required this.errorMessage,
    required this.onDurationChanged, required this.onFocusChanged,
    required this.onIntensityChanged, required this.onSessionsCountChanged,
    required this.onGenerate,
  });

  bool get _isMusculacao => modality == Modality.musculacao;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.natacao.withAlpha(18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.natacao.withAlpha(51)),
          ),
          child: Row(children: [
            const Icon(Icons.auto_awesome, color: AppColors.natacao, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(
              _isMusculacao
                  ? 'A IA vai gerar um plano mensal com treinos progressivos e sobrecarga crescente.'
                  : 'A IA vai gerar exatamente o número de treinos que você configurar abaixo, adaptados ao seu perfil.',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.natacao),
            )),
          ]),
        ),

        const SizedBox(height: 20),

        if (!_isMusculacao) ...[
          const Text('Tempo disponível por treino', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(child: Slider(
              value: duration.toDouble(), min: 15, max: 180,
              divisions: 33, activeColor: AppColors.primary,
              onChanged: (v) => onDurationChanged(v.round()),
            )),
            Container(
              width: 70,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$duration min',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
            ),
          ]),
          const Divider(height: 28),
        ],

        if (!_isMusculacao) ...[
          const Text('Foco do plano', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: TrainingFocus.values.map((f) {
              final sel = focus == f;
              return GestureDetector(
                onTap: () => onFocusChanged(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.natacao : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: sel ? AppColors.natacao : AppColors.border,
                      width: sel ? 2 : 1),
                  ),
                  child: Text(f.label, style: AppTextStyles.bodySm.copyWith(
                    color: sel ? Colors.white : AppColors.textPrimary,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                ),
              );
            }).toList(),
          ),
          const Divider(height: 28),
        ],

        // ── Número de sessões ────────────────────────────────────────────
        Text(
          _isMusculacao ? 'Treinos por semana' : 'Treinos neste plano',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          _isMusculacao
              ? 'Quantos dias de treino por semana? A IA cria os treinos (1, 2, 3...).'
              : 'Quantos treinos você quer neste plano? A IA respeitará exatamente esse número.',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 10),
        Row(
          children: (_isMusculacao ? [2, 3, 4, 5] : [1, 2, 3, 4, 5, 6])
              .map((n) {
            final sel = sessionsCount == n;
            return Expanded(child: GestureDetector(
              onTap: () => onSessionsCountChanged(n),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: EdgeInsets.only(right: n != (_isMusculacao ? 5 : 6) ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: sel ? AppColors.primary : AppColors.border,
                    width: sel ? 2 : 1),
                ),
                child: Text('$n',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: sel ? Colors.white : AppColors.textPrimary,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
              ),
            ));
          }).toList(),
        ),

        const Divider(height: 28),

        const Text('Intensidade', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 10),
        Row(children: DesiredIntensity.values.map((i) {
          final sel = intensity == i;
          return Expanded(child: GestureDetector(
            onTap: () => onIntensityChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: i != DesiredIntensity.intenso ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: sel ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: sel ? AppColors.primary : AppColors.border,
                  width: sel ? 2 : 1),
              ),
              child: Text(i.label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySm.copyWith(
                    color: sel ? Colors.white : AppColors.textPrimary,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
            ),
          ));
        }).toList()),

        const Divider(height: 28),

        Row(children: [
          const Text('Contexto adicional', style: AppTextStyles.bodyMedium),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('opcional', style: AppTextStyles.caption),
          ),
        ]),
        const SizedBox(height: 8),
        TextField(
          controller: freeTextCtrl,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: _isMusculacao
                ? 'Ex: 42 anos, pratico musculação há 6 meses. Quero 3 treinos '
                    'por semana durante 4 semanas para ganhar força e perder peso. '
                    'Tenho pressão alta controlada e hérnia de disco L4-L5 — '
                    'evitar agachamento e sobrecarga na coluna. Segunda, quarta e sexta.'
                : 'Ex: 35 anos, pratico corrida há 1 ano. Quero 3 treinos por '
                    'semana durante 2 semanas para melhorar resistência e emagrecer. '
                    'Tenho diabetes tipo 2 — evitar intensidade muito alta. '
                    'Disponível terças, quintas e sábados, 50 min por treino.',
            hintStyle:
                AppTextStyles.bodySm.copyWith(color: AppColors.textTertiary),
          ),
        ),
        const SizedBox(height: 6),
        const Row(children: [
          Icon(Icons.info_outline, size: 14, color: AppColors.textTertiary),
          SizedBox(width: 6),
          Expanded(child: Text(
            'Escreva o que precisar: idade, experiência, dias e duração do plano, '
            'objetivos (emagrecer, força, resistência) e condições de saúde '
            '(diabetes, pressão alta, hérnia...). A IA prioriza tudo que você informar.',
            style: AppTextStyles.caption,
          )),
        ]),

        const SizedBox(height: 24),

        if (errorMessage != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withAlpha(77)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(errorMessage!,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.error))),
            ]),
          ),
        ],

        TreinixButton(
          label: 'Gerar Plano',
          icon: Icons.auto_awesome,
          onPressed: onGenerate,
        ),
      ],
    );
  }
}

// ─── Loading ──────────────────────────────────────────────────────────────────

class _LoadingCard extends StatefulWidget {
  final Modality modality;
  const _LoadingCard({required this.modality});

  @override
  State<_LoadingCard> createState() => _LoadingCardState();
}

class _LoadingCardState extends State<_LoadingCard>
    with SingleTickerProviderStateMixin {

  late AnimationController _iconCtrl;
  late Animation<double>   _iconAnim;

  double _progress   = 0.0;
  bool   _goingRight = true;

  // (delay-ms, progress-target) — stops at 96% until ViewModel completes
  static const List<(int, double)> _stages = [
    (400,  0.10),
    (1400, 0.27),
    (2000, 0.51),
    (2500, 0.73),
    (3000, 0.88),
    (3500, 0.96),
  ];

  @override
  void initState() {
    super.initState();
    final isMusc = widget.modality == Modality.musculacao;

    _iconCtrl = AnimationController(
      vsync:    this,
      duration: Duration(milliseconds: isMusc ? 500 : 1800),
    )..repeat(reverse: true);

    _iconCtrl.addStatusListener((status) {
      if (!mounted) return;
      if (status == AnimationStatus.forward) setState(() => _goingRight = true);
      if (status == AnimationStatus.reverse) setState(() => _goingRight = false);
    });

    _iconAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _iconCtrl, curve: Curves.easeInOut));

    _runStages();
  }

  Future<void> _runStages() async {
    for (final (ms, target) in _stages) {
      await Future.delayed(Duration(milliseconds: ms));
      if (!mounted) return;
      setState(() => _progress = target);
    }
  }

  @override
  void dispose() {
    _iconCtrl.dispose();
    super.dispose();
  }

  Color get _color => switch (widget.modality) {
    Modality.corrida    => AppColors.corrida,
    Modality.natacao    => AppColors.natacao,
    Modality.ciclismo   => AppColors.ciclismo,
    Modality.musculacao => AppColors.musculacao,
  };

  String get _emoji => switch (widget.modality) {
    Modality.corrida    => '🏃',
    Modality.natacao    => '🏊',
    Modality.ciclismo   => '🚴',
    Modality.musculacao => '🏋️',
  };

  String get _headline => switch (widget.modality) {
    Modality.corrida    => 'Elaborando seu plano de corrida...',
    Modality.natacao    => 'Elaborando seu plano de natação...',
    Modality.ciclismo   => 'Elaborando seu plano de ciclismo...',
    Modality.musculacao => 'Montando sua divisão de musculação...',
  };

  String _stageMsg(double p) {
    if (p < 0.15) return 'Analisando seu perfil de atleta...';
    if (p < 0.35) return 'Definindo periodização e volume...';
    if (p < 0.60) return 'Estruturando treinos e estímulos...';
    if (p < 0.80) return 'Ajustando intensidade e recuperação...';
    if (p < 0.96) return 'Revisando e otimizando o plano...';
    return 'Finalizando os detalhes...';
  }

  @override
  Widget build(BuildContext context) {
    final isMusc = widget.modality == Modality.musculacao;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: _color.withAlpha(70)),
      ),
      child: Column(children: [

        // ── Título ────────────────────────────────────────────────────────
        Text(_headline,
            style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        const Text('A IA está personalizando o plano para o seu perfil.',
            style: AppTextStyles.caption, textAlign: TextAlign.center),

        const SizedBox(height: 32),

        // ── Ícone animado sobre a barra ───────────────────────────────────
        AnimatedBuilder(
          animation: _iconAnim,
          builder: (_, __) => SizedBox(
            height: 52,
            child: LayoutBuilder(builder: (_, box) {
              const double sz = 38;

              if (isMusc) {
                // Musculação: fica no centro e sobe/desce (levantamento de peso)
                return Stack(clipBehavior: Clip.none, children: [
                  Positioned(
                    left: (box.maxWidth - sz) / 2,
                    top:  10 + _iconAnim.value * -24,
                    child: Text(_emoji, style: const TextStyle(fontSize: sz)),
                  ),
                ]);
              }

              // Endurance: percorre a barra da esquerda para a direita e volta
              return Stack(clipBehavior: Clip.none, children: [
                Positioned(
                  left: _iconAnim.value * (box.maxWidth - sz),
                  top:  6,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(
                      _goingRight ? -1.0 : 1.0, 1.0, 1.0),
                    child: Text(_emoji, style: const TextStyle(fontSize: sz)),
                  ),
                ),
              ]);
            }),
          ),
        ),

        const SizedBox(height: 6),

        // ── Barra de progresso ────────────────────────────────────────────
        TweenAnimationBuilder<double>(
          tween:    Tween<double>(begin: 0, end: _progress),
          duration: const Duration(milliseconds: 900),
          curve:    Curves.easeOut,
          builder: (_, val, __) => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value:            val,
              minHeight:        14,
              backgroundColor:  _color.withAlpha(30),
              valueColor:       AlwaysStoppedAnimation<Color>(_color),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── Percentual ────────────────────────────────────────────────────
        TweenAnimationBuilder<double>(
          tween:    Tween<double>(begin: 0, end: _progress),
          duration: const Duration(milliseconds: 900),
          builder: (_, val, __) => Text(
            '${(val * 100).round()}%',
            style: TextStyle(
              fontSize: 36, fontWeight: FontWeight.w800, color: _color),
          ),
        ),

        const SizedBox(height: 8),
        Text(_stageMsg(_progress),
            style: AppTextStyles.caption, textAlign: TextAlign.center),
      ]),
    );
  }
}
