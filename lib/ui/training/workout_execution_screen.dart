// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/ui/training/workout_execution_screen.dart
// Camada   : Screen – Execução de Treino (Workout Player)
// Descrição: Tela de execução passo a passo: um exercício por página, deslize
//            entre blocos. Musculação: contador de séries + cronômetro de
//            descanso + campo de carga. Endurance: confirmação de bloco.
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/training_model.dart';
import '../../data/models/user_model.dart';

class WorkoutExecutionScreen extends StatefulWidget {
  final TrainingSession session;
  final Modality        modality;

  const WorkoutExecutionScreen({
    super.key,
    required this.session,
    required this.modality,
  });

  @override
  State<WorkoutExecutionScreen> createState() => _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState extends State<WorkoutExecutionScreen> {
  late final PageController _pageCtrl;
  int _current = 0;

  // Um bool por exercício para rastrear conclusão
  late final List<bool> _done;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _done     = List<bool>.filled(widget.session.steps.length, false);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Color get _color => switch (widget.modality) {
    Modality.corrida    => AppColors.corrida,
    Modality.natacao    => AppColors.natacao,
    Modality.ciclismo   => AppColors.ciclismo,
    Modality.musculacao => AppColors.musculacao,
  };

  bool get _isMusc => widget.modality == Modality.musculacao;
  bool get _isLast => _current == widget.session.steps.length - 1;
  int  get _doneCount => _done.where((d) => d).length;

  void _markDone(int index) => setState(() => _done[index] = true);

  void _next() {
    if (_isLast) return;
    _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 350),
      curve:    Curves.easeInOut,
    );
  }

  void _prev() {
    if (_current == 0) return;
    _pageCtrl.previousPage(
      duration: const Duration(milliseconds: 350),
      curve:    Curves.easeInOut,
    );
  }

  void _finish() => Navigator.of(context).pop(true);

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair do treino?'),
        content: const Text('O progresso desta sessão não será salvo. Deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pop(false);
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.session.steps;

    if (steps.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor:  _color,
          foregroundColor:  Colors.white,
          title: const Text('Treino'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
        body: const Center(
          child: Text('Nenhum exercício nesta sessão.', style: AppTextStyles.bodySm),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _color,
        foregroundColor: Colors.white,
        elevation:       0,
        leading: IconButton(
          icon:      const Icon(Icons.close),
          onPressed: _confirmExit,
          tooltip:   'Sair do treino',
        ),
        title: Text(
          'Exercício ${_current + 1} de ${steps.length}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$_doneCount/${steps.length} ✓',
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),

      body: Column(children: [

        // ── Barra de progresso global ─────────────────────────────────────
        LinearProgressIndicator(
          value:            steps.isEmpty ? 0 : _doneCount / steps.length,
          minHeight:        4,
          backgroundColor:  _color.withAlpha(30),
          valueColor:       AlwaysStoppedAnimation<Color>(_color),
        ),

        // ── PageView com exercícios ───────────────────────────────────────
        Expanded(
          child: PageView.builder(
            controller:    _pageCtrl,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount:     steps.length,
            itemBuilder:   (_, i) {
              final ex = steps[i];
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: _isMusc
                    ? _MuscExerciseCard(
                        key:    ValueKey('musc_$i'),
                        ex:     ex,
                        index:  i,
                        color:  _color,
                        isDone: _done[i],
                        onDone: () => _markDone(i),
                      )
                    : _EnduranceExerciseCard(
                        key:      ValueKey('end_$i'),
                        ex:       ex,
                        index:    i,
                        total:    steps.length,
                        modality: widget.modality,
                        color:    _color,
                        isDone:   _done[i],
                        onDone:   () => _markDone(i),
                      ),
              );
            },
          ),
        ),

        // ── Indicadores de página (pontos) ────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(steps.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width:  _current == i ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _done[i]
                    ? AppColors.success
                    : _current == i
                        ? _color
                        : _color.withAlpha(50),
                borderRadius: BorderRadius.circular(4),
              ),
            )),
          ),
        ),

        // ── Navegação inferior ────────────────────────────────────────────
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(children: [

              // Anterior
              if (_current > 0)
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: _prev,
                    icon:  const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Anterior'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _color,
                      side:    BorderSide(color: _color.withAlpha(120)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape:   RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )
              else
                const Expanded(flex: 2, child: SizedBox()),

              const SizedBox(width: 12),

              // Próximo / Concluir
              Expanded(
                flex: 3,
                child: _isLast
                    ? ElevatedButton.icon(
                        onPressed: _finish,
                        icon:  const Icon(Icons.check_circle, color: Colors.white),
                        label: const Text(
                          'Concluir treino',
                          style: TextStyle(
                            color:      Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _next,
                        icon:  const Icon(Icons.arrow_forward, color: Colors.white),
                        label: const Text(
                          'Próximo',
                          style: TextStyle(
                            color:      Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _color,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─── Card de musculação — tabela de séries (reps + carga por série) ──────────

// Dados mutáveis de uma série individual.
class _SetData {
  bool done = false;
  final TextEditingController repsCtrl;
  final TextEditingController loadCtrl;

  _SetData({required String reps, required String load})
      : repsCtrl = TextEditingController(text: reps),
        loadCtrl = TextEditingController(text: load);

  void dispose() {
    repsCtrl.dispose();
    loadCtrl.dispose();
  }
}

class _MuscExerciseCard extends StatefulWidget {
  final ExerciseItem ex;
  final int          index;
  final Color        color;
  final bool         isDone;
  final VoidCallback onDone;

  const _MuscExerciseCard({
    super.key,
    required this.ex,
    required this.index,
    required this.color,
    required this.isDone,
    required this.onDone,
  });

  @override
  State<_MuscExerciseCard> createState() => _MuscExerciseCardState();
}

class _MuscExerciseCardState extends State<_MuscExerciseCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late List<_SetData> _sets;
  int    _restRemaining = 0;
  Timer? _restTimer;

  bool get _allDone => _sets.every((s) => s.done);

  // Converte campo rest em segundos. null = descanso descritivo.
  int? get _restSeconds {
    final r = widget.ex.rest?.toLowerCase().trim();
    if (r == null || r.isEmpty) return null;
    final mSec = RegExp(r'(\d+)\s*min.*?(\d+)\s*s').firstMatch(r);
    if (mSec != null) {
      return int.parse(mSec.group(1)!) * 60 + int.parse(mSec.group(2)!);
    }
    final mMin = RegExp(r'^(\d+)\s*min(?:uto)?s?$').firstMatch(r);
    if (mMin != null) return int.parse(mMin.group(1)!) * 60;
    final mSec2 = RegExp(r'^(\d+)\s*s(?:eg(?:undo)?s?)?$').firstMatch(r);
    if (mSec2 != null) return int.parse(mSec2.group(1)!);
    return null;
  }

  @override
  void initState() {
    super.initState();
    final n    = widget.ex.sets ?? 3;
    final reps = widget.ex.reps?.toString() ?? '';
    final load = widget.ex.load ?? '';
    _sets = List.generate(n, (_) => _SetData(reps: reps, load: load));
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    for (final s in _sets) { s.dispose(); }
    super.dispose();
  }

  void _completeSet(int i) {
    if (_sets[i].done) return;
    final restSec = _restSeconds;
    setState(() => _sets[i].done = true);

    if (_allDone) {
      widget.onDone();
    } else if (restSec != null && restSec > 0) {
      setState(() => _restRemaining = restSec);
      _startRestTimer();
    }
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _restRemaining--;
        if (_restRemaining <= 0) { t.cancel(); _restRemaining = 0; }
      });
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() => _restRemaining = 0);
  }

  InputDecoration _fieldDecoration({
    required Color color,
    required String hint,
    required String suffix,
    required bool enabled,
  }) =>
      InputDecoration(
        isDense:        true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        hintText:       hint,
        hintStyle:      const TextStyle(color: AppColors.textTertiary),
        suffixText:     suffix,
        suffixStyle:    const TextStyle(
            color: AppColors.textTertiary, fontSize: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   BorderSide(color: color.withAlpha(50)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   BorderSide(color: color.withAlpha(50)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   BorderSide(color: color, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   const BorderSide(color: AppColors.border),
        ),
      );

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Grupo (bi-set / tri-set) ────────────────────────────────────
        if (widget.ex.group != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color:        widget.color.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(widget.ex.group!,
                style: AppTextStyles.caption.copyWith(
                    color: widget.color, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
        ],

        // ── Nome do exercício ───────────────────────────────────────────
        Text(widget.ex.name,
            style: const TextStyle(
              fontSize: 26, fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            )),

        if (widget.ex.notes != null) ...[
          const SizedBox(height: 4),
          Text(widget.ex.notes!,
              style: AppTextStyles.bodySm.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary)),
        ],

        const SizedBox(height: 16),

        // ── Cabeçalho da tabela ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(left: 40, right: 40),
          child: Row(children: [
            Expanded(
              child: Text('Reps',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption
                      .copyWith(color: widget.color, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Carga',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption
                      .copyWith(color: widget.color, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 36),
          ]),
        ),
        const SizedBox(height: 6),

        // ── Linhas de série ─────────────────────────────────────────────
        ..._sets.asMap().entries.map((entry) {
          final i   = entry.key;
          final set = entry.value;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: set.done
                  ? AppColors.success.withAlpha(15)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: set.done
                    ? AppColors.success.withAlpha(80)
                    : widget.color.withAlpha(45),
              ),
            ),
            child: Row(children: [

              // Número da série
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: set.done
                      ? AppColors.success
                      : widget.color.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: set.done
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : Text('${i + 1}',
                          style: TextStyle(
                            color:      widget.color,
                            fontWeight: FontWeight.w700,
                            fontSize:   13,
                          )),
                ),
              ),

              const SizedBox(width: 8),

              // Campo de repetições
              Expanded(
                child: TextField(
                  controller:   set.repsCtrl,
                  enabled:      !set.done,
                  keyboardType: const TextInputType.numberWithOptions(),
                  textAlign:    TextAlign.center,
                  style: TextStyle(
                    fontSize:   15,
                    fontWeight: FontWeight.w700,
                    color:      set.done
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                  decoration: _fieldDecoration(
                    color:   widget.color,
                    hint:    '—',
                    suffix:  'rep',
                    enabled: !set.done,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Campo de carga
              Expanded(
                child: TextField(
                  controller:   set.loadCtrl,
                  enabled:      !set.done,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign:    TextAlign.center,
                  style: TextStyle(
                    fontSize:   15,
                    fontWeight: FontWeight.w700,
                    color:      set.done
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                  decoration: _fieldDecoration(
                    color:   widget.color,
                    hint:    '—',
                    suffix:  'kg',
                    enabled: !set.done,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Botão / ícone de concluir série
              if (set.done)
                const Icon(Icons.check_circle,
                    color: AppColors.success, size: 28)
              else
                InkWell(
                  onTap:        () => _completeSet(i),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(Icons.check_circle_outline,
                        color: widget.color, size: 28),
                  ),
                ),
            ]),
          );
        }),

        // ── Cronômetro de descanso ──────────────────────────────────────
        if (_restRemaining > 0) ...[
          const SizedBox(height: 8),
          _RestTimerCard(
            seconds: _restRemaining,
            total:   _restSeconds ?? _restRemaining,
            color:   widget.color,
            onSkip:  _skipRest,
          ),
        ],

        // ── Banner de exercício concluído ───────────────────────────────
        if (_allDone) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        AppColors.success.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: AppColors.success.withAlpha(77)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 20),
                SizedBox(width: 8),
                Text('Exercício concluído!',
                    style: TextStyle(
                      color:      AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize:   15,
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Card de endurance (corrida / natação / ciclismo) ─────────────────────────

class _EnduranceExerciseCard extends StatelessWidget {
  final ExerciseItem ex;
  final int          index;
  final int          total;
  final Modality     modality;
  final Color        color;
  final bool         isDone;
  final VoidCallback onDone;

  const _EnduranceExerciseCard({
    super.key,
    required this.ex,
    required this.index,
    required this.total,
    required this.modality,
    required this.color,
    required this.isDone,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Cabeçalho do bloco ──────────────────────────────────────────
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color:        isDone ? AppColors.success : color,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 24)
                  : Text('${index + 1}',
                      style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   20,
                          fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bloco ${index + 1} de $total',
                  style: AppTextStyles.caption,
                ),
                Text(
                  ex.name,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ]),

        const SizedBox(height: 20),

        // ── Estatísticas do bloco ───────────────────────────────────────
        Wrap(
          spacing: 10, runSpacing: 10,
          children: [
            if (ex.sets != null && ex.load != null)
              _StatBox(
                label: 'Volume',
                value: '${ex.sets}× ${ex.load}',
                icon:  Icons.repeat_rounded,
                color: color,
              ),
            if (ex.load != null && ex.sets == null)
              _StatBox(
                label: modality == Modality.corrida
                    ? 'Distância / Ritmo'
                    : modality == Modality.natacao
                        ? 'Distância'
                        : 'Duração / Carga',
                value: ex.load!,
                icon:  Icons.straighten,
                color: color,
              ),
            if (ex.rest != null)
              _StatBox(
                label: modality == Modality.natacao ? 'Intervalo' : 'Recuperação',
                value: ex.rest!,
                icon:  Icons.timer_outlined,
                color: color,
              ),
          ],
        ),

        // ── Notas / instruções ──────────────────────────────────────────
        if (ex.notes != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        color.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: color.withAlpha(50)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.info_outline, size: 14, color: color),
                  const SizedBox(width: 6),
                  Text('Instrução',
                      style: AppTextStyles.caption.copyWith(
                          color: color, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 6),
                Text(ex.notes!, style: AppTextStyles.bodySm),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // ── Botão / status de conclusão ─────────────────────────────────
        if (!isDone)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onDone,
              icon:  const Icon(Icons.check, color: Colors.white),
              label: const Text('Concluí este bloco',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:        AppColors.success.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: AppColors.success.withAlpha(77)),
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 22),
              SizedBox(width: 10),
              Text('Bloco concluído!',
                  style: TextStyle(
                    color:      AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize:   16,
                  )),
            ]),
          ),
      ],
    );
  }
}

// ─── Cronômetro de descanso ───────────────────────────────────────────────────

class _RestTimerCard extends StatelessWidget {
  final int          seconds;
  final int          total;
  final Color        color;
  final VoidCallback onSkip;

  const _RestTimerCard({
    required this.seconds,
    required this.total,
    required this.color,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final m     = seconds ~/ 60;
    final s     = seconds % 60;
    final label = m > 0
        ? '$m:${s.toString().padLeft(2, '0')}'
        : '${seconds}s';
    final pct   = total > 0 ? seconds / total : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(50), color.withAlpha(20)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.timer, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 8),
          const Text('Descansando...', style: AppTextStyles.bodyMedium),
          const Spacer(),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(foregroundColor: color),
            child: const Text('Pular', style: TextStyle(fontSize: 13)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize:   52,
            fontWeight: FontWeight.w900,
            color:      color,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value:            pct,
            minHeight:        6,
            backgroundColor:  color.withAlpha(30),
            valueColor:       AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ]),
    );
  }
}

// ─── Caixa de estatística ─────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color:        AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border:       Border.all(color: color.withAlpha(50)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.caption.copyWith(color: color)),
        ]),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
