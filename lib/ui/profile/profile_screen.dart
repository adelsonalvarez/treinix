// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/ui/profile/profile_screen.dart
// Camada   : Screen – Perfil
// Descrição: Perfil esportivo + edição de modalidades via bottom sheet
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../widgets/treinix_app_bar.dart';
import '../widgets/treinix_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // ─── Bottom sheet para editar todo o perfil de treino ────────────────────

  void _editSportProfile(BuildContext context, AuthViewModel auth) {
    if (auth.currentUser == null) return;
    final user = auth.currentUser!;

    final mods      = Set<Modality>.from(user.modalities);
    var   level     = user.level;
    var   goal      = user.goal;
    var   compDate = user.competitionDate;
    var   age      = user.age > 0 ? user.age : null;
    final nameCtrl = TextEditingController(text: user.competitionName);
    final ageCtrl  = TextEditingController(text: age != null ? '$age' : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              24, 12, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Handle
              Center(child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              )),

              const Text('Editar perfil de treino',
                  style: AppTextStyles.heading3),
              const SizedBox(height: 20),

              // ── Modalidades ────────────────────────────────────────────
              const Text('Modalidades', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 4),
              const Text('Selecione pelo menos uma',
                  style: AppTextStyles.caption),
              const SizedBox(height: 10),
              ...Modality.values.map((m) {
                final isSel = mods.contains(m);
                return GestureDetector(
                  onTap: () => setSheet(() {
                    if (isSel && mods.length > 1) { mods.remove(m); }
                    else if (!isSel) { mods.add(m); }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primaryLight : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isSel ? AppColors.primary : AppColors.border,
                          width: isSel ? 2 : 1),
                    ),
                    child: Row(children: [
                      Text(m.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Text(m.label, style: AppTextStyles.bodyMedium),
                      const Spacer(),
                      Icon(isSel ? Icons.check_circle : Icons.circle_outlined,
                          color: isSel ? AppColors.primary : AppColors.border,
                          size: 22),
                    ]),
                  ),
                );
              }),

              const Divider(height: 28),

              // ── Nível ──────────────────────────────────────────────────
              const Text('Nível', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              Row(children: Level.values.map((l) {
                final sel = level == l;
                return Expanded(child: GestureDetector(
                  onTap: () => setSheet(() => level = l),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: EdgeInsets.only(
                        right: l != Level.avancado ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: sel ? AppColors.primary : AppColors.border,
                          width: sel ? 2 : 1),
                    ),
                    child: Text(l.label,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySm.copyWith(
                          color: sel ? Colors.white : AppColors.textPrimary,
                          fontWeight:
                              sel ? FontWeight.w600 : FontWeight.w400)),
                  ),
                ));
              }).toList()),
              const SizedBox(height: 20),

              // ── Objetivo ───────────────────────────────────────────────
              const Text('Objetivo', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: Goal.values.map((g) {
                  final sel = goal == g;
                  return GestureDetector(
                    onTap: () => setSheet(() => goal = g),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: sel ? AppColors.primary : AppColors.border,
                            width: sel ? 2 : 1),
                      ),
                      child: Text(g.label,
                          style: AppTextStyles.bodySm.copyWith(
                            color: sel ? Colors.white : AppColors.textPrimary,
                            fontWeight:
                                sel ? FontWeight.w600 : FontWeight.w400)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Idade ──────────────────────────────────────────────────
              const Text('Idade', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              TextField(
                controller: ageCtrl,
                keyboardType: TextInputType.number,
                maxLength: 2,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: 'Ex: 32',
                  suffixText: 'anos',
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  final n = int.tryParse(val);
                  setSheet(() => age = n != null && n >= 10 && n <= 99 ? n : null);
                },
              ),
              const SizedBox(height: 20),

              // Campos de competição (visíveis quando objetivo é Desempenho)
              if (goal == Goal.desempenho) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nome da prova / competição',
                    hintText: 'Ex: Ironman 70.3, SP City Marathon',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: compDate ??
                          DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 730)),
                      locale: const Locale('pt', 'BR'),
                    );
                    if (picked != null) {
                      setSheet(() => compDate = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(
                    compDate != null
                        ? 'Prova: ${DateFormat('dd/MM/yyyy').format(compDate!)}'
                        : 'Selecionar data da prova',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              TreinixButton(
                label: 'Salvar perfil',
                onPressed: mods.isEmpty
                    ? () {}
                    : () async {
                        Navigator.pop(ctx);
                        if (auth.currentUser == null) return;
                        final updated = auth.currentUser!.copyWith(
                          modalities:      mods.toList(),
                          level:           level,
                          goal:            goal,
                          birthDate:       age != null
                              ? DateTime(DateTime.now().year - age!, 1, 1)
                              : null,
                          competitionName: goal == Goal.desempenho
                              ? nameCtrl.text.trim()
                              : '',
                          competitionDate: goal == Goal.desempenho
                              ? compDate
                              : null,
                        );
                        await UserRepository().updateUser(updated);
                        auth.updateCurrentUser(updated);
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const TreinixAppBar(screenTitle: 'Perfil', showAppMenu: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // ── Card de perfil — mesmo estilo do card de streak da Home ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name.split(' ').first ?? 'Atleta',
                        style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '—',
                        style: TextStyle(
                          color:    Colors.white.withAlpha(200),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _StatChip(
                            icon:  Icons.signal_cellular_alt_outlined,
                            label: user?.level.label ?? '—',
                          ),
                          _StatChip(
                            icon:  Icons.flag_outlined,
                            label: user?.goal.label ?? '—',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white,
                  child: Text(
                    user?.name.isNotEmpty == true
                        ? user!.name[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      color:      AppColors.primary,
                      fontSize:   28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 24),

            // Perfil esportivo
            _InfoSection(
              title: 'Meu perfil esportivo',
              items: [
                ('Modalidades',
                    user?.modalities.map((m) => m.label).join(', ') ?? '—'),
                ('Nível', user?.level.label ?? '—'),
                ('Objetivo', user?.goal.label ?? '—'),
                ('Idade',
                    user != null && user.age > 0
                        ? '${user.age} anos'
                        : '—'),
                if (user?.hasCompetition ?? false) ...[
                  ('Prova / competição',
                      user!.competitionName.isNotEmpty
                          ? user.competitionName
                          : '—'),
                  ('Data da prova',
                      user.competitionDate != null
                          ? DateFormat('dd/MM/yyyy')
                              .format(user.competitionDate!)
                          : '—'),
                ],
              ],
            ),

            const SizedBox(height: 8),

            // Botão editar perfil de treino
            if (user != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _editSportProfile(context, auth),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar perfil de treino'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary),
                ),
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ─── Chip de estatística (usado no card de perfil) ────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withAlpha(40),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white, size: 12),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(
          color:      Colors.white,
          fontSize:   11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ]),
  );
}

// ─── Seção de informações ─────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final String title;
  final List<(String, String)> items;
  const _InfoSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.label),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final (label, value) = e.value;
              final isLast = e.key == items.length - 1;
              return Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(children: [
                    Text(label, style: AppTextStyles.bodySm),
                    const Spacer(),
                    Flexible(
                      child: Text(value,
                          style: AppTextStyles.bodyMedium,
                          textAlign: TextAlign.right),
                    ),
                  ]),
                ),
                if (!isLast) const Divider(height: 0),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}
