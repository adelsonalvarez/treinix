// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/ui/auth/login_screen.dart
// Camada   : Screen – Login
// Descrição: Hero azul (gradiente idêntico à logo) + card branco responsivo.
//            O card ocupa exatamente o espaço restante via Expanded, sem
//            percentuais fixos que causam overflow em telas menores.
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/treinix_button.dart';

const _kHeroGradient = LinearGradient(
  begin:  Alignment.topLeft,
  end:    Alignment.bottomRight,
  colors: [AppColors.primary, AppColors.primaryDark],
);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    final vm    = context.read<AuthViewModel>();
    final route = await vm.signInWithGoogle();
    if (!mounted) return;
    if (route != null) {
      context.go(route);
    } else if (vm.status == AuthStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:         Text(vm.errorMessage ?? 'Erro ao entrar com Google.'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<AuthViewModel>();
    final ok = await vm.signIn(
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:         Text(vm.errorMessage ?? 'Erro ao entrar.'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    final screenH  = MediaQuery.of(context).size.height;
    final isSmall  = screenH < 680;
    final logoSize = isSmall ? 72.0 : 110.0;
    final vPad     = isSmall ? 10.0 : 20.0;
    final gap1     = isSmall ?  8.0 : 14.0;
    final gap2     = isSmall ?  2.0 :  6.0;
    final titleSz  = isSmall ? 24.0 : 28.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: _kHeroGradient),
        child: SafeArea(
          child: Column(
            children: [

              // ── Hero: logo + marca + tagline ──────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(24, vPad, 24, vPad),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width:  logoSize,
                      height: logoSize,
                      errorBuilder: (_, __, ___) => Container(
                        width: logoSize, height: logoSize,
                        decoration: BoxDecoration(
                          color:  Colors.white.withAlpha(30),
                          shape:  BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('T', style: TextStyle(
                            fontSize:   logoSize * 0.43,
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

                    SizedBox(height: gap2),

                    Text(
                      'Treine com inteligência. Evolua todo dia.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize:      12,
                        color:         Colors.white.withAlpha(210),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Card do formulário — Expanded preenche o restante ─────
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          const Text('Bem-vindo de volta',
                              style: AppTextStyles.heading2),
                          const SizedBox(height: 4),
                          const Text('Entre para continuar seu treino',
                              style: AppTextStyles.bodySm),

                          const SizedBox(height: 32),

                          // E-mail
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

                          const SizedBox(height: 16),

                          // Senha
                          TextFormField(
                            controller:  _passCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText:  'Senha',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Informe a senha' : null,
                          ),

                          const SizedBox(height: 4),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.go('/reset-password'),
                              child: const Text('Esqueci minha senha'),
                            ),
                          ),

                          const SizedBox(height: 20),

                          TreinixButton(
                            label:     'Entrar',
                            loading:   vm.isLoading,
                            onPressed: _submit,
                          ),

                          const SizedBox(height: 20),

                          // Divisor "ou"
                          Row(children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Text('ou',
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.textTertiary)),
                            ),
                            const Expanded(child: Divider()),
                          ]),

                          const SizedBox(height: 20),

                          GoogleSignInButton(
                            label:     'Entrar com Google',
                            onPressed: vm.isLoading ? null : _signInWithGoogle,
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Não tem conta?',
                                  style: AppTextStyles.bodySm),
                              TextButton(
                                onPressed: () => context.go('/register'),
                                child: const Text('Criar conta'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
