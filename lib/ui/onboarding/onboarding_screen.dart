// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/ui/onboarding/onboarding_screen.dart
// Camada   : Screen – Onboarding
// Descrição: Fluxo de 3 etapas: modalidade, nível e objetivo
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/user_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../widgets/treinix_button.dart';
import '../widgets/modality_chip.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  final List<Modality> _modalities = [];
  Level _level = Level.iniciante;
  Goal _goal = Goal.resistencia;
  int? _age;

  void _next() {
    if (_page < 3) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _page++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_page > 0) {
      _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _page--);
    }
  }

  Future<void> _finish() async {
    final auth = context.read<AuthViewModel>();
    final userVm = context.read<UserViewModel>();
    final uid = auth.currentUser?.uid ?? '';

    final birthDate = _age != null
        ? DateTime(DateTime.now().year - _age!, 1, 1)
        : null;

    await userVm.completeOnboarding(
      uid:        uid,
      name:       auth.currentUser?.name  ?? '',
      email:      auth.currentUser?.email ?? '',
      modalities: _modalities.isEmpty ? [Modality.corrida] : _modalities,
      level:      _level,
      goal:       _goal,
      birthDate:  birthDate,
    );

    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Indicador de progresso
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: List.generate(4, (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: i <= _page ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
            ),
            const SizedBox(height: 8),
            // Back button
            if (_page > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _back,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Voltar'),
                ),
              )
            else
              const SizedBox(height: 40),

            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StepModality(
                    selected: _modalities,
                    onToggle: (m) => setState(() {
                      _modalities.contains(m) ? _modalities.remove(m) : _modalities.add(m);
                    }),
                  ),
                  _StepLevel(
                    selected: _level,
                    onSelect: (l) => setState(() => _level = l),
                  ),
                  _StepGoal(
                    selected: _goal,
                    onSelect: (g) => setState(() => _goal = g),
                  ),
                  _StepAge(
                    value:    _age,
                    onSelect: (a) => setState(() => _age = a),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: TreinixButton(
                label: _page < 3 ? 'Continuar' : 'Começar a treinar',
                icon: _page < 3 ? Icons.arrow_forward : Icons.check,
                onPressed: () {
                  if (_page == 0 && _modalities.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Selecione ao menos uma modalidade')),
                    );
                    return;
                  }
                  _next();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 1: Modalidades ───────────────────────────────────────────────────

class _StepModality extends StatelessWidget {
  final List<Modality> selected;
  final void Function(Modality) onToggle;
  const _StepModality({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quais modalidades\nvocê pratica?', style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          const Text('Pode escolher mais de uma.', style: AppTextStyles.bodySm),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: Modality.values.map((m) => ModalityChip(
              modality: m,
              selected: selected.contains(m),
              onTap: () => onToggle(m),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Step 2: Nível ────────────────────────────────────────────────────────

class _StepLevel extends StatelessWidget {
  final Level selected;
  final void Function(Level) onSelect;
  const _StepLevel({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final options = [
      (Level.iniciante, 'Iniciante', 'Pratico há menos de 6 meses ou voltei agora'),
      (Level.intermediario, 'Intermediário', 'Já treino regularmente há mais de 6 meses'),
      (Level.avancado, 'Avançado', 'Compito ou treino há mais de 2 anos'),
    ];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Qual é seu nível\natual?', style: AppTextStyles.heading2),
          const SizedBox(height: 32),
          ...options.map((o) {
            final (level, label, sub) = o;
            final sel = selected == level;
            return GestureDetector(
              onTap: () => onSelect(level),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primaryLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: sel ? AppColors.primary : AppColors.border,
                    width: sel ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: AppTextStyles.bodyMedium.copyWith(
                            color: sel ? AppColors.primary : AppColors.textPrimary,
                          )),
                          const SizedBox(height: 2),
                          Text(sub, style: AppTextStyles.bodySm),
                        ],
                      ),
                    ),
                    if (sel) const Icon(Icons.check_circle, color: AppColors.primary),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Step 3: Objetivo e Idade ─────────────────────────────────────────────

class _StepGoal extends StatelessWidget {
  final Goal selected;
  final void Function(Goal) onSelect;
  const _StepGoal({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final goals = [
      (Goal.saude,         '💚', 'Saúde',         'Qualidade de vida e bem-estar geral'),
      (Goal.resistencia,   '🏅', 'Resistência',   'Aguentar mais, ir mais longe'),
      (Goal.forca,         '💪', 'Força',         'Ganhar massa muscular e potência'),
      (Goal.emagrecimento, '🔥', 'Emagrecimento', 'Perder peso com saúde'),
      (Goal.desempenho,    '🏆', 'Desempenho',    'Melhorar resultado em provas e competições'),
    ];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Qual é seu\nobjetivo principal?', style: AppTextStyles.heading2),
          const SizedBox(height: 32),
          ...goals.map((g) {
            final (goal, emoji, label, sub) = g;
            final sel = selected == goal;
            return GestureDetector(
              onTap: () => onSelect(goal),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primaryLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: sel ? AppColors.primary : AppColors.border,
                    width: sel ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: AppTextStyles.bodyMedium.copyWith(
                            color: sel ? AppColors.primary : AppColors.textPrimary,
                          )),
                          Text(sub, style: AppTextStyles.bodySm),
                        ],
                      ),
                    ),
                    if (sel) const Icon(Icons.check_circle, color: AppColors.primary),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Step 4: Idade ────────────────────────────────────────────────────────

class _StepAge extends StatefulWidget {
  final int? value;
  final void Function(int?) onSelect;
  const _StepAge({required this.value, required this.onSelect});

  @override
  State<_StepAge> createState() => _StepAgeState();
}

class _StepAgeState extends State<_StepAge> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.value != null ? '${widget.value}' : '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String val) {
    final n = int.tryParse(val);
    widget.onSelect(n != null && n >= 10 && n <= 99 ? n : null);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Qual é a sua\nidade?', style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          const Text(
            'Ajuda a IA a calibrar intensidade e volume de recuperação.',
            style: AppTextStyles.bodySm,
          ),
          const SizedBox(height: 48),
          Center(
            child: SizedBox(
              width: 140,
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 2,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
                decoration: InputDecoration(
                  hintText: '--',
                  hintStyle: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: AppColors.border,
                  ),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                ),
                onChanged: _onChanged,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(child: Text('anos', style: AppTextStyles.bodySm)),
          const Spacer(),
          Center(
            child: TextButton(
              onPressed: () {
                _ctrl.clear();
                widget.onSelect(null);
              },
              child: const Text('Prefiro não informar'),
            ),
          ),
        ],
      ),
    );
  }
}