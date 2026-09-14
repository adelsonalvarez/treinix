// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/ui/training/log_training_screen.dart
// Camada   : Screen – Criar Plano Manual de Treino
// Descrição: Construtor de plano manual. O usuário cadastra sessões uma a uma
//            (nome, tipo, duração, intensidade, descrição) e ao fim define a
//            periodicidade (semanal/quinzenal/mensal) ou o total de treinos
//            (musculação). O plano gerado segue o mesmo modelo do plano da IA
//            e aparece nos cards de "Próximos treinos" da home.
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/training_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/plan_repository.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../widgets/exercise_editor.dart';
import '../widgets/modality_chip.dart';
import '../widgets/treinix_app_bar.dart';

// ─── Rascunho de sessão enquanto o usuário preenche o formulário ──────────────

class _SessionDraft {
  String           label;
  String           focus;
  String           description;
  int              durationMinutes;
  IntensityLevel   intensity;
  List<ExerciseItem> exercises;

  _SessionDraft({
    required this.label,
    this.focus           = '',
    this.description     = '',
    this.durationMinutes = 45,
    this.intensity       = IntensityLevel.moderado,
    List<ExerciseItem>? exercises,
  }) : exercises = exercises ?? [];

  TrainingSession toSession() => TrainingSession(
        label:           label,
        focus:           '$focus · ${_intensityLabel(intensity)}',
        description:     description.trim(),
        steps:           exercises,
        durationMinutes: durationMinutes,
      );

  static String _intensityLabel(IntensityLevel i) => switch (i) {
        IntensityLevel.leve     => 'Leve',
        IntensityLevel.moderado => 'Moderado',
        IntensityLevel.intenso  => 'Intenso',
      };
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class LogTrainingScreen extends StatefulWidget {
  final TrainingPlanModel? existingPlan;
  const LogTrainingScreen({super.key, this.existingPlan});
  @override
  State<LogTrainingScreen> createState() => _LogTrainingScreenState();
}

class _LogTrainingScreenState extends State<LogTrainingScreen> {
  // Plano
  Modality            _modality = Modality.corrida;
  List<_SessionDraft> _sessions = [];
  bool                _saving   = false;

  // Formulário da sessão atual
  final _labelCtrl = TextEditingController();
  final _focusCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  int              _duration          = 45;
  IntensityLevel   _intensity         = IntensityLevel.moderado;
  List<ExerciseItem> _currentExercises = [];

  // Configuração do plano
  String _periodicity    = 'semanal'; // endurance: semanal|quinzenal|mensal
  int    _totalTrainings = 20;         // musculação: nº total de treinos

  bool get _isEditing => widget.existingPlan != null;

  // Converte uma sessão salva de volta para rascunho editável.
  static _SessionDraft _draftFromSession(TrainingSession s) {
    final parts = s.focus.split(' · ');
    final focus  = parts.first;
    final iStr   = parts.length > 1 ? parts.last : 'Moderado';
    final intensity = switch (iStr) {
      'Leve'    => IntensityLevel.leve,
      'Intenso' => IntensityLevel.intenso,
      _         => IntensityLevel.moderado,
    };
    return _SessionDraft(
      label:           s.label,
      focus:           focus,
      description:     s.description,
      durationMinutes: s.durationMinutes,
      intensity:       intensity,
      exercises:       List<ExerciseItem>.from(s.steps),
    );
  }

  @override
  void initState() {
    super.initState();
    final p = widget.existingPlan;
    if (p != null) {
      _modality = p.modality;
      _sessions = p.sessions.map(_draftFromSession).toList();
      if (p.modality == Modality.musculacao) {
        _totalTrainings = p.totalSlots;
      } else {
        final ratio = p.sessions.isNotEmpty ? p.totalSlots ~/ p.sessions.length : 1;
        _periodicity = switch (ratio) {
          1    => 'semanal',
          2    => 'quinzenal',
          _    => 'mensal',
        };
      }
    }
    _resetSessionForm();
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _focusCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  bool get _isMusc => _modality == Modality.musculacao;

  Color get _color => switch (_modality) {
        Modality.corrida    => AppColors.corrida,
        Modality.natacao    => AppColors.natacao,
        Modality.ciclismo   => AppColors.ciclismo,
        Modality.musculacao => AppColors.musculacao,
      };

  String get _focusHint => _isMusc
      ? 'Ex: Peito e Tríceps, Costas e Bíceps...'
      : 'Ex: Base Z2, Velocidade, Limiar, Longão...';

  String get _nextLabel {
    final n = _sessions.length;
    return 'Treino ${n + 1}';
  }

  void _resetSessionForm() {
    _labelCtrl.text   = _nextLabel;
    _focusCtrl.clear();
    _descCtrl.clear();
    _duration          = 45;
    _intensity         = IntensityLevel.moderado;
    _currentExercises  = [];
  }

  void _onModalityChanged(Modality m) {
    setState(() {
      _modality         = m;
      _sessions.clear();
      _currentExercises = [];
      _periodicity      = 'semanal';
      _totalTrainings   = 20;
    });
    _resetSessionForm();
  }

  // Totalslots
  int get _cycles => switch (_periodicity) {
        'semanal'   => 1,
        'quinzenal' => 2,
        _           => 4,
      };

  int get _totalSlots =>
      _isMusc ? _totalTrainings : (_sessions.length * _cycles);

  int get _validDays => _isMusc
      ? 365
      : switch (_periodicity) {
          'semanal'   => 7,
          'quinzenal' => 14,
          _           => 30,
        };

  String get _periodLabel => switch (_periodicity) {
        'semanal'   => '1 semana',
        'quinzenal' => '2 semanas',
        _           => '1 mês',
      };

  // ── Adicionar sessão ─────────────────────────────────────────────────────────

  void _addSession() {
    final label = _labelCtrl.text.trim();
    final focus = _focusCtrl.text.trim();
    if (label.isEmpty || focus.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Preencha o nome e o tipo/grupos do treino.'),
      ));
      return;
    }
    setState(() {
      _sessions.add(_SessionDraft(
        label:           label,
        focus:           focus,
        description:     _descCtrl.text.trim(),
        durationMinutes: _duration,
        intensity:       _intensity,
        exercises:       List<ExerciseItem>.from(_currentExercises),
      ));
      _currentExercises = [];
    });
    _resetSessionForm();
  }

  void _removeSession(int i) {
    setState(() => _sessions.removeAt(i));
    _labelCtrl.text = _nextLabel;
  }

  // ── Salvar plano ─────────────────────────────────────────────────────────────

  Future<void> _savePlan() async {
    if (_sessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adicione pelo menos um treino.')));
      return;
    }
    if (_isMusc && _totalTrainings < _sessions.length) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Total de treinos deve ser pelo menos ${_sessions.length}.',
        ),
      ));
      return;
    }

    setState(() => _saving = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { setState(() => _saving = false); return; }

    final auth = context.read<AuthViewModel>();
    final homeVm = context.read<HomeViewModel>();

    final now   = DateTime.now();
    final label = _sessions.length == 1 ? 'treino' : 'treinos';
    final title = _isMusc
        ? 'Musculação — ${_sessions.length} treino(s) · $_totalTrainings no plano'
        : '${_modality.label} — ${_sessions.length} $label por $_periodLabel';

    final plan = TrainingPlanModel(
      id:               '',
      userId:           uid,
      modality:         _modality,
      planType:         _isMusc ? PlanType.mensal : PlanType.semanal,
      title:            title,
      overview:         '',
      sessions:         _sessions.map((s) => s.toSession()).toList(),
      tip:              '',
      hasTapering:      false,
      generatedAt:      now,
      validUntil:       now.add(Duration(days: _validDays)),
      totalSlots:       _totalSlots,
      completedCount:   0,
      nextSessionIndex: 0,
    );

    try {
      if (_isEditing) {
        final updated = TrainingPlanModel(
          id:               widget.existingPlan!.id,
          userId:           uid,
          modality:         _modality,
          planType:         _isMusc ? PlanType.mensal : PlanType.semanal,
          title:            title,
          overview:         '',
          sessions:         _sessions.map((s) => s.toSession()).toList(),
          tip:              '',
          hasTapering:      false,
          generatedAt:      widget.existingPlan!.generatedAt,
          validUntil:       now.add(Duration(days: _validDays)),
          totalSlots:       _totalSlots,
          completedCount:   0,
          nextSessionIndex: 0,
        );
        await PlanRepository().updateFull(updated);
      } else {
        await PlanRepository().save(plan);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao salvar o plano: $e'),
          backgroundColor: AppColors.error,
        ));
      }
      return;
    }

    // Salvo com sucesso — navegar imediatamente e recarregar home em background.
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    // Dispara o reload sem await para não bloquear a navegação.
    if (auth.currentUser != null) {
      homeVm.load(uid, auth.currentUser!.modalities).ignore();
    }

    context.go('/home');
    messenger.showSnackBar(SnackBar(
      content: Text(_isEditing ? 'Plano atualizado! 💪' : 'Plano criado com sucesso! 💪'),
      backgroundColor: AppColors.success,
    ));
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TreinixAppBar(
        screenTitle: _isEditing ? 'Editar plano' : 'Novo registro',
        showAppMenu: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── 1. Modalidade ────────────────────────────────────────────────
            const _SectionTitle('1. Modalidade'),
            const SizedBox(height: 10),
            Column(children: [
              Row(children: [
                Expanded(child: ModalityChip(
                  modality: Modality.corrida,
                  selected: _modality == Modality.corrida,
                  onTap: () => _onModalityChanged(Modality.corrida),
                )),
                const SizedBox(width: 10),
                Expanded(child: ModalityChip(
                  modality: Modality.natacao,
                  selected: _modality == Modality.natacao,
                  onTap: () => _onModalityChanged(Modality.natacao),
                )),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: ModalityChip(
                  modality: Modality.ciclismo,
                  selected: _modality == Modality.ciclismo,
                  onTap: () => _onModalityChanged(Modality.ciclismo),
                )),
                const SizedBox(width: 10),
                Expanded(child: ModalityChip(
                  modality: Modality.musculacao,
                  selected: _modality == Modality.musculacao,
                  onTap: () => _onModalityChanged(Modality.musculacao),
                )),
              ]),
            ]),

            const SizedBox(height: 28),

            // ── 2. Formulário da sessão ──────────────────────────────────────
            _SectionTitle(
              _sessions.isEmpty
                  ? '2. Cadastrar primeiro treino'
                  : '2. Adicionar treino ${_sessions.length + 1}',
            ),
            const SizedBox(height: 14),
            _SessionForm(
              color:              _color,
              isMusc:             _isMusc,
              modality:           _modality,
              labelCtrl:          _labelCtrl,
              focusCtrl:          _focusCtrl,
              descCtrl:           _descCtrl,
              focusHint:          _focusHint,
              duration:           _duration,
              intensity:          _intensity,
              exercises:          _currentExercises,
              onDuration:         (v) => setState(() => _duration  = v),
              onIntensity:        (i) => setState(() => _intensity = i),
              onExercisesChanged: (list) => setState(() => _currentExercises = list),
              onAdd:              _addSession,
            ),

            // ── 3. Sessões cadastradas ───────────────────────────────────────
            if (_sessions.isNotEmpty) ...[
              const SizedBox(height: 28),
              const _SectionTitle('3. Treinos do plano'),
              const SizedBox(height: 12),
              ..._sessions.asMap().entries.map((e) => _SessionTile(
                    draft:    e.value,
                    index:    e.key,
                    color:    _color,
                    onDelete: () => _removeSession(e.key),
                  )),
            ],

            // ── 4. Configuração do plano ─────────────────────────────────────
            if (_sessions.isNotEmpty) ...[
              const SizedBox(height: 28),
              const _SectionTitle('4. Configuração do plano'),
              const SizedBox(height: 14),

              if (_isMusc)
                _TotalTrainingsConfig(
                  color:        _color,
                  sessions:     _sessions.length,
                  total:        _totalTrainings,
                  onDecrement:  () => setState(() {
                    if (_totalTrainings > _sessions.length) {
                      _totalTrainings--;
                    }
                  }),
                  onIncrement:  () => setState(() {
                    if (_totalTrainings < 200) _totalTrainings++;
                  }),
                )
              else
                _PeriodicityConfig(
                  color:       _color,
                  periodicity: _periodicity,
                  sessions:    _sessions.length,
                  cycles:      _cycles,
                  totalSlots:  _totalSlots,
                  periodLabel: _periodLabel,
                  onChanged:   (v) => setState(() => _periodicity = v),
                ),
            ],

            // ── 5. Botão salvar ──────────────────────────────────────────────
            if (_sessions.isNotEmpty) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _savePlan,
                  icon: _saving
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded, color: Colors.white),
                  label: Text(
                    _saving
                        ? 'Salvando...'
                        : _isEditing
                            ? 'Salvar alterações'
                            : 'Criar plano de ${_modality.label}',
                    style: const TextStyle(
                      color:      Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize:   16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:         _color,
                    disabledBackgroundColor: _color.withAlpha(120),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Formulário de uma sessão ─────────────────────────────────────────────────

class _SessionForm extends StatelessWidget {
  final Color                           color;
  final bool                            isMusc;
  final Modality                        modality;
  final TextEditingController           labelCtrl;
  final TextEditingController           focusCtrl;
  final TextEditingController           descCtrl;
  final String                          focusHint;
  final int                             duration;
  final IntensityLevel                  intensity;
  final List<ExerciseItem>              exercises;
  final void Function(int)              onDuration;
  final void Function(IntensityLevel)   onIntensity;
  final void Function(List<ExerciseItem>) onExercisesChanged;
  final VoidCallback                    onAdd;

  const _SessionForm({
    required this.color, required this.isMusc, required this.modality,
    required this.labelCtrl, required this.focusCtrl, required this.descCtrl,
    required this.focusHint,
    required this.duration, required this.intensity,
    required this.exercises,
    required this.onDuration, required this.onIntensity,
    required this.onExercisesChanged, required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:  AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(80), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Nome da sessão
          TextField(
            controller: labelCtrl,
            decoration: const InputDecoration(
              labelText: 'Nome do treino *',
              hintText:  'Ex: Treino 1, Treino 2...',
              border:    OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),

          // Tipo / grupos musculares
          TextField(
            controller: focusCtrl,
            decoration: InputDecoration(
              labelText: isMusc ? 'Grupos musculares *' : 'Tipo de treino *',
              hintText:  focusHint,
              border:    const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),

          // Duração
          Row(children: [
            Text('Duração: $duration min', style: AppTextStyles.bodyMedium),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$duration min',
                  style: AppTextStyles.caption
                      .copyWith(color: color, fontWeight: FontWeight.w700)),
            ),
          ]),
          Slider(
            value:       duration.toDouble(),
            min:         10,
            max:         180,
            divisions:   34,
            activeColor: color,
            onChanged:   (v) => onDuration(v.round()),
          ),
          const SizedBox(height: 8),

          // Intensidade
          const Text('Intensidade', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 10),
          Row(
            children: IntensityLevel.values.map((il) {
              final sel = intensity == il;
              final lbl = switch (il) {
                IntensityLevel.leve     => 'Leve',
                IntensityLevel.moderado => 'Moderado',
                IntensityLevel.intenso  => 'Intenso',
              };
              final dot = switch (il) {
                IntensityLevel.leve     => '🟢',
                IntensityLevel.moderado => '🟡',
                IntensityLevel.intenso  => '🔴',
              };
              return Expanded(child: GestureDetector(
                onTap: () => onIntensity(il),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: EdgeInsets.only(
                      right: il != IntensityLevel.intenso ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? color : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: sel ? color : AppColors.border,
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(dot, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(lbl, textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            color:      sel ? Colors.white : AppColors.textPrimary,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                          )),
                    ],
                  ),
                ),
              ));
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Exercícios estruturados
          ExerciseListSection(
            exercises: exercises,
            modality:  modality,
            color:     color,
            onChanged: onExercisesChanged,
          ),
          const SizedBox(height: 16),

          // Observações gerais (opcional)
          TextField(
            controller: descCtrl,
            maxLines:   3,
            decoration: const InputDecoration(
              labelText:          'Observações gerais (opcional)',
              hintText:           'Ex: aquecimento, dicas, observações do treino...',
              alignLabelWithHint: true,
              border:             OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 18),

          // Botão adicionar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon:  const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Adicionar treino',
                style: TextStyle(
                  color:      Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tile de sessão cadastrada ────────────────────────────────────────────────

class _SessionTile extends StatelessWidget {
  final _SessionDraft draft;
  final int           index;
  final Color         color;
  final VoidCallback  onDelete;

  const _SessionTile({
    required this.draft, required this.index,
    required this.color, required this.onDelete,
  });

  String get _badge => '${index + 1}';

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withAlpha(60)),
    ),
    child: Row(children: [
      // Badge
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: Text(
          _badge,
          style: const TextStyle(
            color:      Colors.white,
            fontWeight: FontWeight.w800,
            fontSize:   18,
          ),
        )),
      ),
      const SizedBox(width: 12),
      // Info
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(draft.label, style: AppTextStyles.bodyMedium),
          Text(
            '${draft.focus} · ${draft.durationMinutes} min',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 2),
          Text(
            draft.exercises.isEmpty
                ? 'Sem exercícios cadastrados'
                : '${draft.exercises.length} exercício(s)',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textTertiary),
          ),
        ],
      )),
      // Delete
      IconButton(
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline,
            color: AppColors.error, size: 20),
        tooltip: 'Remover sessão',
      ),
    ]),
  );
}

// ─── Configuração: total de treinos (musculação) ──────────────────────────────

class _TotalTrainingsConfig extends StatelessWidget {
  final Color        color;
  final int          sessions;
  final int          total;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _TotalTrainingsConfig({
    required this.color, required this.sessions, required this.total,
    required this.onDecrement, required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final repsPerSession = total ~/ sessions;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:  AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total de treinos no plano',
              style: AppTextStyles.bodyMedium),
          const SizedBox(height: 4),
          const Text(
            'Informe quantas vezes irá a academia neste plano.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepBtn(icon: Icons.remove, color: color, onTap: onDecrement),
              const SizedBox(width: 20),
              Column(children: [
                Text('$total',
                    style: TextStyle(
                      color:      color,
                      fontSize:   40,
                      fontWeight: FontWeight.w800,
                    )),
                const Text('treinos', style: AppTextStyles.caption),
              ]),
              const SizedBox(width: 20),
              _StepBtn(icon: Icons.add, color: color, onTap: onIncrement),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(
                '$sessions treino(s) cadastrado(s) × $repsPerSession repetição(ões) '
                '= $total visitas à academia',
                style: AppTextStyles.caption.copyWith(color: color),
              )),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── Configuração: periodicidade (endurance) ──────────────────────────────────

class _PeriodicityConfig extends StatelessWidget {
  final Color                   color;
  final String                  periodicity;
  final int                     sessions;
  final int                     cycles;
  final int                     totalSlots;
  final String                  periodLabel;
  final void Function(String)   onChanged;

  const _PeriodicityConfig({
    required this.color, required this.periodicity, required this.sessions,
    required this.cycles, required this.totalSlots, required this.periodLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withAlpha(60)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Periodicidade do plano',
            style: AppTextStyles.bodyMedium),
        const SizedBox(height: 4),
        const Text(
          'Com que frequência o ciclo de sessões se repetirá.',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 16),
        Row(children: [
          for (final opt in [
            ('semanal',   'Semanal',   '1 semana',   1),
            ('quinzenal', 'Quinzenal', '2 semanas',  2),
            ('mensal',    'Mensal',    '1 mês',      4),
          ])
            Expanded(child: GestureDetector(
              onTap: () => onChanged(opt.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: opt.$1 != 'mensal'
                    ? const EdgeInsets.only(right: 8)
                    : EdgeInsets.zero,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: periodicity == opt.$1 ? color : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: periodicity == opt.$1 ? color : AppColors.border,
                    width: periodicity == opt.$1 ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(opt.$2,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySm.copyWith(
                          color: periodicity == opt.$1
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: periodicity == opt.$1
                              ? FontWeight.w600
                              : FontWeight.w400,
                        )),
                    Text(opt.$3,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                          color: periodicity == opt.$1
                              ? Colors.white70
                              : AppColors.textTertiary,
                        )),
                  ],
                ),
              ),
            )),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Icon(Icons.repeat_rounded, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(
              '$sessions treino(s) × $cycles ciclo(s) = $totalSlots treinos em $periodLabel',
              style: AppTextStyles.caption.copyWith(color: color),
            )),
          ]),
        ),
      ],
    ),
  );
}

// ─── Botão de incremento/decremento ──────────────────────────────────────────

class _StepBtn extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        shape: BoxShape.circle,
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Icon(icon, color: color, size: 22),
    ),
  );
}

// ─── Título de seção ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(text, style: AppTextStyles.heading3);
}
