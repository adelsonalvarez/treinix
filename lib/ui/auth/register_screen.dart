// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/ui/auth/register_screen.dart
// Camada   : Screen – Cadastro
// Descrição: Mesma identidade visual da LoginScreen: hero azul (gradiente da
//            logo) + card branco responsivo via Expanded. Campos: nome, e-mail,
//            senha (com indicador de força), confirmação, consentimento LGPD,
//            e cadastro via Google.
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:flutter/gestures.dart';
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

// ── Helpers de força de senha ─────────────────────────────────────────────────

enum _PwdStrength { fraca, moderada, forte }

bool _hasUpper(String s)   => s.contains(RegExp(r'[A-Z]'));
bool _hasLower(String s)   => s.contains(RegExp(r'[a-z]'));
bool _hasDigit(String s)   => s.contains(RegExp(r'[0-9]'));
bool _hasSpecial(String s) =>
    s.contains(RegExp(r'[!@#$%^&*()\-_=+\[\]{};:,.<>?/|\\~`]'));

_PwdStrength _pwdStrength(String pwd) {
  if (pwd.isEmpty) return _PwdStrength.fraca;
  int score = 0;
  if (pwd.length >= 8) score++;
  if (_hasUpper(pwd))   score++;
  if (_hasLower(pwd))   score++;
  if (_hasDigit(pwd))   score++;
  if (_hasSpecial(pwd)) score++;
  if (score <= 2) return _PwdStrength.fraca;
  if (score <= 4) return _PwdStrength.moderada;
  return _PwdStrength.forte;
}

String? _validatePassword(String? v) {
  if (v == null || v.isEmpty) return 'Informe a senha';
  final erros = <String>[];
  if (v.length < 8)    erros.add('mín. 8 caracteres');
  if (!_hasUpper(v))   erros.add('1 maiúscula');
  if (!_hasLower(v))   erros.add('1 minúscula');
  if (!_hasDigit(v))   erros.add('1 número');
  if (!_hasSpecial(v)) erros.add('1 caractere especial');
  if (erros.isNotEmpty) return 'Adicione: ${erros.join(', ')}';
  return null;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _nameCtrl      = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passCtrl      = TextEditingController();
  final _confirmCtrl   = TextEditingController();
  final _policyRec     = TapGestureRecognizer();
  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _consentGiven   = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _policyRec.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Aceite a Política de Privacidade para continuar.'),
      ));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<AuthViewModel>();
    final ok = await vm.signUp(
      name:     _nameCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      context.go('/onboarding');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:         Text(vm.errorMessage ?? 'Erro ao criar conta.'),
        backgroundColor: AppColors.error,
      ));
    }
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

  @override
  Widget build(BuildContext context) {
    final vm  = context.watch<AuthViewModel>();
    final pwd = _passCtrl.text;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: _kHeroGradient),
        child: SafeArea(
          child: Column(
            children: [

              // ── Hero compacto: voltar + logo + marca ──────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 24, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // Botão voltar alinhado à esquerda
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color:  Colors.white,
                          size:   20,
                        ),
                        onPressed: () => context.go('/login'),
                      ),
                    ),

                    Image.asset(
                      'assets/images/logo.png',
                      width:  90,
                      height: 90,
                      errorBuilder: (_, __, ___) => Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('T', style: TextStyle(
                            fontSize:   40,
                            fontWeight: FontWeight.w800,
                            color:      Colors.white,
                          )),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'TREINIX',
                      style: TextStyle(
                        fontSize:      26,
                        fontWeight:    FontWeight.w800,
                        color:         Colors.white,
                        letterSpacing: 5,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Crie sua conta e comece a evoluir',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color:    Colors.white.withAlpha(210),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Card do formulário ────────────────────────────────────
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
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 48),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          const Text('Vamos começar',
                              style: AppTextStyles.heading2),
                          const SizedBox(height: 4),
                          const Text(
                            'Preencha os dados abaixo para criar sua conta',
                            style: AppTextStyles.bodySm,
                          ),

                          const SizedBox(height: 28),

                          // Nome
                          TextFormField(
                            controller:         _nameCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText:  'Nome completo',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Informe seu nome'
                                    : null,
                          ),

                          const SizedBox(height: 16),

                          // E-mail
                          TextFormField(
                            controller:   _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText:  'E-mail',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Informe o e-mail';
                              if (!v.contains('@'))       return 'E-mail inválido';
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Senha
                          TextFormField(
                            controller:  _passCtrl,
                            obscureText: _obscurePass,
                            onChanged:   (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText:  'Senha',
                              hintText:   'Mín. 8 caracteres',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePass
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                                onPressed: () =>
                                    setState(() => _obscurePass = !_obscurePass),
                              ),
                            ),
                            validator: _validatePassword,
                          ),

                          if (pwd.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _PasswordStrengthBar(
                              strength: _pwdStrength(pwd),
                              password: pwd,
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Confirmar senha
                          TextFormField(
                            controller:  _confirmCtrl,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              labelText:  'Confirmar senha',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                                onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Confirme a senha';
                              if (v != _passCtrl.text) return 'As senhas não coincidem';
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Consentimento LGPD (Art. 7, I)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24, height: 24,
                                child: Checkbox(
                                  value:                 _consentGiven,
                                  onChanged:             (v) => setState(
                                      () => _consentGiven = v ?? false),
                                  activeColor:           AppColors.primary,
                                  visualDensity:         VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: RichText(
                                    text: TextSpan(
                                      style: AppTextStyles.bodySm
                                          .copyWith(color: AppColors.textPrimary),
                                      children: [
                                        const TextSpan(text: 'Li e concordo com a '),
                                        TextSpan(
                                          text: 'Política de Privacidade',
                                          style: const TextStyle(
                                            color:      AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                            decoration: TextDecoration.underline,
                                          ),
                                          recognizer: _policyRec
                                            ..onTap = () => context.push('/privacy'),
                                        ),
                                        const TextSpan(text: ' do Treinix (LGPD).'),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          TreinixButton(
                            label:     'Criar conta',
                            loading:   vm.isLoading,
                            onPressed: _submit,
                          ),

                          const SizedBox(height: 20),

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
                            label:     'Continuar com Google',
                            onPressed: vm.isLoading ? null : _signInWithGoogle,
                          ),

                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Já tem conta?',
                                  style: AppTextStyles.bodySm),
                              TextButton(
                                onPressed: () => context.go('/login'),
                                child: const Text('Entrar'),
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

// ── Widget: barra de força de senha ──────────────────────────────────────────

class _PasswordStrengthBar extends StatelessWidget {
  final _PwdStrength strength;
  final String       password;
  const _PasswordStrengthBar({
    required this.strength,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color, value) = switch (strength) {
      _PwdStrength.fraca    => ('Fraca',    const Color(0xFFEF4444), 0.33),
      _PwdStrength.moderada => ('Moderada', const Color(0xFFF97316), 0.67),
      _PwdStrength.forte    => ('Forte',    const Color(0xFF22C55E), 1.00),
    };

    final missing = <String>[];
    if (password.length < 8)    missing.add('mín. 8 caracteres');
    if (!_hasUpper(password))   missing.add('maiúscula');
    if (!_hasLower(password))   missing.add('minúscula');
    if (!_hasDigit(password))   missing.add('número');
    if (!_hasSpecial(password)) missing.add('caractere especial');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value:           value,
                backgroundColor: AppColors.border,
                valueColor:      AlwaysStoppedAnimation(color),
                minHeight:       5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: AppTextStyles.caption.copyWith(
                color:      color,
                fontWeight: FontWeight.w700,
              )),
        ]),
        if (missing.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Faltam: ${missing.join(' · ')}',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}
