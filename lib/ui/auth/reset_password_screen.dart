// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/ui/auth/reset_password_screen.dart
// Camada   : Screen – Recuperação de Senha
// Descrição: Mesma identidade visual de login/cadastro: hero laranja +
//            card branco. Envia e-mail de redefinição via Firebase Auth.
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../widgets/treinix_button.dart';

const _kHeroGradient = LinearGradient(
  begin:  Alignment.topLeft,
  end:    Alignment.bottomRight,
  colors: [AppColors.primary, AppColors.primaryDark],
);

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  bool  _loading   = false;
  bool  _sent      = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailCtrl.text.trim());
      if (mounted) setState(() { _loading = false; _sent = true; });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:         Text(e.message ?? 'Erro ao enviar e-mail.'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenH  = MediaQuery.of(context).size.height;
    final isSmall  = screenH < 680;
    final logoSize = isSmall ? 72.0 : 100.0;
    final vPad     = isSmall ? 10.0 : 20.0;
    final gap1     = isSmall ?  8.0 : 14.0;
    final titleSz  = isSmall ? 22.0 : 26.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: _kHeroGradient),
        child: SafeArea(
          child: Column(
            children: [

              // ── Hero ─────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(8, vPad, 24, vPad),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size:  20,
                        ),
                        onPressed: () => context.go('/login'),
                      ),
                    ),

                    Image.asset(
                      'assets/images/logo.png',
                      width:  logoSize,
                      height: logoSize,
                      errorBuilder: (_, __, ___) => Container(
                        width: logoSize, height: logoSize,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('T', style: TextStyle(
                            fontSize:   logoSize * 0.44,
                            fontWeight: FontWeight.w800,
                            color:      Colors.white,
                          )),
                        ),
                      ),
                    ),

                    SizedBox(height: gap1),

                    Text(
                      'TREINIX',
                      style: TextStyle(
                        fontSize:      titleSz,
                        fontWeight:    FontWeight.w800,
                        color:         Colors.white,
                        letterSpacing: 5,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Recuperação de senha',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color:    Colors.white.withAlpha(210),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Card ─────────────────────────────────────────────────
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 36, 28, 48),
                    child: _sent ? _successView() : _formView(),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _formView() => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text('Redefinir senha', style: AppTextStyles.heading2),
        const SizedBox(height: 4),
        const Text(
          'Informe seu e-mail e enviaremos um link para redefinir sua senha.',
          style: AppTextStyles.bodySm,
        ),

        const SizedBox(height: 32),

        TextFormField(
          controller:   _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText:  'E-mail',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Informe o e-mail' : null,
        ),

        const SizedBox(height: 24),

        TreinixButton(
          label:     'Enviar link',
          loading:   _loading,
          onPressed: _send,
        ),

        const SizedBox(height: 16),

        Center(
          child: TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Voltar ao login'),
          ),
        ),
      ],
    ),
  );

  Widget _successView() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const Icon(Icons.check_circle_outline,
          color: AppColors.success, size: 56),
      const SizedBox(height: 20),
      const Text('E-mail enviado!', style: AppTextStyles.heading2),
      const SizedBox(height: 8),
      const Text(
        'Verifique sua caixa de entrada e siga as instruções para redefinir sua senha.',
        style: AppTextStyles.bodyMedium,
      ),
      const SizedBox(height: 32),
      TreinixButton(
        label:     'Voltar ao login',
        onPressed: () => context.go('/login'),
      ),
    ],
  );
}
