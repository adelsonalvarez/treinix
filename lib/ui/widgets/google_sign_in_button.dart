// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/ui/widgets/google_sign_in_button.dart
// Camada   : Widget – Botão Google
// Descrição: Botão "Continuar com Google" com logo "G" desenhado via
//            CustomPainter, sem assets externos, estilo Material/GitHub.
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// SVG oficial do Google "G" conforme Google Brand Guidelines.
const _kGoogleGSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
</svg>
''';

/// Botão "Continuar com Google" com o logo "G" oficial (SVG Google Brand
/// Guidelines) — aprovado para publicação na Play Store e App Store.
class GoogleSignInButton extends StatelessWidget {
  final String        label;
  final VoidCallback? onPressed;

  const GoogleSignInButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF3C4043),
          side:  const BorderSide(color: Color(0xFFDADCE0)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.string(_kGoogleGSvg, width: 20, height: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize:      14,
                fontWeight:    FontWeight.w500,
                color:         Color(0xFF3C4043),
                letterSpacing: 0.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
