// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/ui/profile/privacy_screen.dart
// Camada   : Screen – Política de Privacidade (LGPD)
// Descrição: Tela com a política de privacidade do aplicativo, descrevendo
//            quais dados são coletados, a finalidade e os direitos do titular
//            conforme a Lei 13.709/2018 (LGPD).
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../widgets/treinix_app_bar.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const TreinixAppBar(screenTitle: 'Política de Privacidade', showAppMenu: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
        children: const [
          _Header(
            emoji: '🔒',
            title: 'Política de Privacidade — Treinix',
            subtitle: 'Última atualização: agosto de 2026',
          ),

          SizedBox(height: 6),

          _Section(
            number: '1',
            title: 'Dados pessoais coletados',
            body:
                'O Treinix coleta os seguintes dados para funcionamento do aplicativo:\n\n'
                '• Nome e endereço de e-mail (identificação e acesso)\n'
                '• Idade e perfil esportivo (modalidades, nível, objetivo, dias de treino)\n'
                '• Histórico de treinos realizados\n'
                '• Planos de treino criados manualmente ou pela IA\n'
                '• Data e nome de prova (se o usuário treina para competição)',
          ),

          _Section(
            number: '2',
            title: 'Finalidade do tratamento',
            body:
                'Os dados são utilizados exclusivamente para:\n\n'
                '• Personalizar as sugestões de treino geradas por inteligência artificial\n'
                '• Exibir o histórico e o progresso pessoal do usuário\n'
                '• Identificar o usuário na plataforma\n\n'
                'Não há uso dos dados para fins publicitários, comerciais ou de perfilagem.',
          ),

          _Section(
            number: '3',
            title: 'Base legal (LGPD, Art. 7)',
            body:
                'O tratamento de dados é realizado com base em:\n\n'
                '• Consentimento do titular (Art. 7, I) — ao criar uma conta, o usuário '
                'consente com esta política\n'
                '• Execução de contrato (Art. 7, V) — necessário para fornecer os serviços '
                'de personalização de treinos',
          ),

          _Section(
            number: '4',
            title: 'Compartilhamento com terceiros',
            body:
                'Para gerar sugestões de treino, dados de perfil esportivo '
                '(modalidade, nível, objetivo, idade) são enviados à API da Anthropic '
                '(modelo Claude Sonnet). Esses dados são processados conforme a '
                'política de privacidade da Anthropic (https://anthropic.com/privacy).\n\n'
                'Nenhum dado pessoal identificável (nome, e-mail) é compartilhado com '
                'a IA ou com terceiros.',
          ),

          _Section(
            number: '5',
            title: 'Armazenamento e segurança',
            body:
                'Os dados são armazenados no Firebase (Google Cloud), com:\n\n'
                '• Criptografia em trânsito (TLS/HTTPS)\n'
                '• Criptografia em repouso (AES-256)\n'
                '• Regras de segurança do Firestore que garantem que cada usuário '
                'acesse apenas os seus próprios dados\n\n'
                'O acesso ao banco de dados requer autenticação via Firebase Auth.',
          ),

          _Section(
            number: '6',
            title: 'Retenção de dados',
            body:
                'Os dados são mantidos enquanto a conta estiver ativa. '
                'Ao solicitar a exclusão da conta (disponível na seção "Privacidade" '
                'do perfil), TODOS os dados são apagados permanentemente e de forma '
                'imediata, sem possibilidade de recuperação.',
          ),

          _Section(
            number: '7',
            title: 'Seus direitos como titular (LGPD, Art. 18)',
            body:
                'Você tem os seguintes direitos sobre seus dados:\n\n'
                '• Confirmação e acesso — ver todos os dados que o app armazena\n'
                '• Correção — atualizar dados incorretos ou incompletos\n'
                '• Eliminação — excluir sua conta e todos os dados (disponível no perfil)\n'
                '• Portabilidade — solicitar seus dados em formato legível\n'
                '• Revogação do consentimento — excluir a conta encerra o tratamento\n\n'
                'Para exercer qualquer desses direitos, acesse a seção "Privacidade" '
                'no seu perfil ou entre em contato pelo e-mail abaixo.',
          ),

          _Section(
            number: '8',
            title: 'Contato e encarregado de dados (DPO)',
            body:
                'Para questões relacionadas à privacidade ou exercício de direitos:\n\n'
                'Desenvolvedor: Adelson Fernando Alvarez Oliveira\n'
                'E-mail: adelsonalvarez@gmail.com\n'
                'Instituição: PUC/PR — Pós-graduação em Desenvolvimento de Aplicativos Móveis',
          ),

          SizedBox(height: 8),
          _Note(
            'Ao usar o Treinix, você declara ter lido e concordado com esta '
            'Política de Privacidade. Alterações significativas serão comunicadas '
            'por meio do aplicativo.',
          ),
        ],
      ),
    );
  }
}

// ─── Componentes internos ─────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  const _Header({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(emoji, style: const TextStyle(fontSize: 40)),
      const SizedBox(height: 10),
      Text(title, style: AppTextStyles.heading2),
      const SizedBox(height: 4),
      Text(subtitle,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textTertiary,
          )),
      const SizedBox(height: 16),
      const Divider(),
      const SizedBox(height: 8),
    ],
  );
}

class _Section extends StatelessWidget {
  final String number;
  final String title;
  final String body;
  const _Section({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: Text(body, style: AppTextStyles.bodySm),
        ),
      ],
    ),
  );
}

class _Note extends StatelessWidget {
  final String text;
  const _Note(this.text);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.primary.withAlpha(15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.primary.withAlpha(60)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline,
            color: AppColors.primary, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textPrimary)),
        ),
      ],
    ),
  );
}
