// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/ui/misc/about_screen.dart
// Camada   : Screen – Sobre o Treinix
// Descrição: Apresenta o propósito do app, contexto acadêmico (TCC PUC/PR),
//            tecnologias utilizadas e informações de versão.
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../widgets/treinix_app_bar.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const TreinixAppBar(screenTitle: 'Sobre o Treinix', showAppMenu: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
        children: [

          // ── Identidade ────────────────────────────────────────────────────
          Center(
            child: Column(children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withAlpha(60), width: 1.5),
                ),
                child: const Center(
                  child: Text('🏃', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 14),
              const Text('TREINIX',
                  style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w900,
                    fontSize: 22, letterSpacing: 3,
                  )),
              const SizedBox(height: 4),
              const Text('Treinador Digital para Atletas Amadores',
                  style: AppTextStyles.bodySm, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text('Versão 1.0.0 · Build 2026',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary)),
            ]),
          ),

          const SizedBox(height: 28),

          // ── Propósito ─────────────────────────────────────────────────────
          const _Card(children: [
            _CardTitle(icon: Icons.flag_outlined, label: 'Propósito'),
            SizedBox(height: 10),
            Text(
              'O Treinix foi criado para apoiar atletas amadores de corrida, '
              'natação, ciclismo e musculação na organização e personalização '
              'de seus treinos. Com o auxílio de Inteligência Artificial, o '
              'app sugere planos de treino adaptados ao perfil, ao nível e aos '
              'objetivos de cada atleta.',
              style: AppTextStyles.bodySm,
            ),
          ]),

          const SizedBox(height: 14),

          // ── Contexto acadêmico ────────────────────────────────────────────
          const _Card(children: [
            _CardTitle(icon: Icons.school_outlined, label: 'Contexto acadêmico'),
            SizedBox(height: 10),
            _InfoRow(label: 'Trabalho', value: 'Projeto de Conclusão de Curso (TCC)'),
            _InfoRow(label: 'Curso',    value: 'Pós-graduação em Desenvolvimento de Aplicativos Móveis'),
            _InfoRow(label: 'Instituição', value: 'Pontifícia Universidade Católica do Paraná – PUC/PR'),
            _InfoRow(label: 'Autor',    value: 'Adelson Fernando Alvarez Oliveira'),
            _InfoRow(label: 'Ano',      value: '2026'),
          ]),

          const SizedBox(height: 14),

          // ── Tecnologias ───────────────────────────────────────────────────
          const _Card(children: [
            _CardTitle(icon: Icons.code_outlined, label: 'Tecnologias'),
            SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                _TechChip(label: 'Flutter', emoji: '💙'),
                _TechChip(label: 'Firebase Auth', emoji: '🔐'),
                _TechChip(label: 'Firestore', emoji: '🗄️'),
                _TechChip(label: 'Cloud Functions', emoji: '⚡'),
                _TechChip(label: 'Claude AI', emoji: '🤖'),
                _TechChip(label: 'GoRouter', emoji: '🗺️'),
                _TechChip(label: 'Provider', emoji: '⚙️'),
              ],
            ),
          ]),

          const SizedBox(height: 14),

          // ── Funcionalidades ───────────────────────────────────────────────
          const _Card(children: [
            _CardTitle(icon: Icons.star_outline, label: 'O que o Treinix oferece'),
            SizedBox(height: 10),
            _BulletItem('Planos de treino gerados por IA'),
            _BulletItem('Registro manual de treinos'),
            _BulletItem('Acompanhamento de progresso com estatísticas'),
            _BulletItem('Histórico completo de treinos realizados'),
            _BulletItem('Perfil de atleta com modalidades e objetivos'),
            _BulletItem('Adaptação para metas competitivas e qualidade de vida'),
          ]),

          const SizedBox(height: 14),

          // ── Privacidade ───────────────────────────────────────────────────
          _Card(children: [
            const _CardTitle(icon: Icons.shield_outlined, label: 'Privacidade e LGPD'),
            const SizedBox(height: 10),
            const Text(
              'O Treinix respeita a Lei Geral de Proteção de Dados (Lei 13.709/2018). '
              'Seus dados são utilizados exclusivamente para personalizar sua '
              'experiência de treino. Consulte nossa política de privacidade completa:',
              style: AppTextStyles.bodySm,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/privacy'),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Ver política de privacidade'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Widgets locais ───────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border, width: 0.8),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );
}

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _CardTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 18, color: AppColors.primary),
    const SizedBox(width: 8),
    Text(label, style: AppTextStyles.bodyMedium),
  ]);
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 90,
        child: Text(label, style: AppTextStyles.caption
            .copyWith(fontWeight: FontWeight.w600)),
      ),
      Expanded(child: Text(value, style: AppTextStyles.bodySm)),
    ]),
  );
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('• ', style: TextStyle(color: AppColors.primary,
          fontWeight: FontWeight.w700, fontSize: 14)),
      Expanded(child: Text(text, style: AppTextStyles.bodySm)),
    ]),
  );
}

class _TechChip extends StatelessWidget {
  final String label;
  final String emoji;
  const _TechChip({required this.label, required this.emoji});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.primary.withAlpha(14),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.primary.withAlpha(40)),
    ),
    child: Text('$emoji $label',
        style: AppTextStyles.caption.copyWith(color: AppColors.primary,
            fontWeight: FontWeight.w600)),
  );
}
