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

import 'dart:math';

import 'package:flutter/material.dart';

/// Botão "Continuar com Google" no estilo do GitHub / Google Material:
/// fundo branco, borda cinza fina, "G" colorido oficial desenhado via
/// CustomPainter (sem assets externos).
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
            const _GoogleG(size: 20),
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

// ─── Logo "G" multicolorido ───────────────────────────────────────────────────

class _GoogleG extends StatelessWidget {
  final double size;
  const _GoogleG({required this.size});

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(size, size),
    painter: _GoogleGPainter(),
  );
}

class _GoogleGPainter extends CustomPainter {
  static const _blue   = Color(0xFF4285F4);
  static const _red    = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green  = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final r      = size.width / 2;
    final center = Offset(r, r);
    final sw     = r * 0.30;          // espessura do traço
    final arcR   = r - sw / 2;        // raio da linha central do arco

    final arcRect = Rect.fromCircle(center: center, radius: arcR);

    final stroke = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap   = StrokeCap.butt;

    // Arco em 4 cores, horário a partir de ~10° (logo abaixo de "3 horas").
    // O gap de 20° (de -10° a 10°) é onde a barra horizontal se encaixa.
    //   verde   10° →  90°  (canto inferior direito)
    //   amarelo 90° → 180°  (canto inferior esquerdo)
    //   vermelho 180° → 270° (canto superior esquerdo)
    //   azul   270° → 350°  (canto superior direito)
    void arc(Color c, double startDeg, double sweepDeg) {
      stroke.color = c;
      canvas.drawArc(
        arcRect,
        startDeg * pi / 180,
        sweepDeg * pi / 180,
        false,
        stroke,
      );
    }

    arc(_green,   10, 80);
    arc(_yellow,  90, 90);
    arc(_red,    180, 90);
    arc(_blue,   270, 80);

    // Barra horizontal azul (o travessão do G),
    // do centro do círculo até a borda exterior do arco.
    canvas.drawRect(
      Rect.fromLTRB(
        r - 1,              // começa no centro (1 px de overlap p/ junção limpa)
        r - sw / 2,         // topo da barra
        r + arcR + sw / 2,  // vai até a borda exterior do arco
        r + sw / 2,         // base da barra
      ),
      Paint()
        ..color = _blue
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
