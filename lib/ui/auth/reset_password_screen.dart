import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../widgets/treinix_button.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar senha')),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: _sent ? _successView() : _formView(),
      ),
    );
  }

  Widget _formView() => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Digite seu e-mail e enviaremos um link para redefinir sua senha.',
            style: AppTextStyles.bodyMedium),
        const SizedBox(height: 24),
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
      const Icon(Icons.check_circle_outline, color: AppColors.success, size: 48),
      const SizedBox(height: 16),
      const Text('E-mail enviado!', style: AppTextStyles.heading2),
      const SizedBox(height: 8),
      const Text('Verifique sua caixa de entrada e siga as instruções para redefinir sua senha.',
          style: AppTextStyles.bodyMedium),
      const SizedBox(height: 24),
      TreinixButton(
        label:     'Voltar ao login',
        onPressed: () => context.go('/login'),
      ),
    ],
  );
}
