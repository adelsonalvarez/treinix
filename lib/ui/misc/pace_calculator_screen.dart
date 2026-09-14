// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/ui/misc/pace_calculator_screen.dart
// Camada   : Screen – Calculadora de Pace
// Descrição: Ferramenta para calcular pace e tempo de prova para corrida,
//            natação e ciclismo. Dois modos: Tempo → Pace e Pace → Tempo.
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../widgets/treinix_app_bar.dart';

// ─── Enum de modalidade ───────────────────────────────────────────────────────

enum _Sport { corrida, natacao, ciclismo }

extension _SportX on _Sport {
  String get label => switch (this) {
        _Sport.corrida   => 'Corrida',
        _Sport.natacao   => 'Natação',
        _Sport.ciclismo  => 'Ciclismo',
      };
  String get emoji => switch (this) {
        _Sport.corrida   => '🏃',
        _Sport.natacao   => '🏊',
        _Sport.ciclismo  => '🚴',
      };
  // Unidade de distância
  String get distUnit => switch (this) {
        _Sport.corrida   => 'km',
        _Sport.natacao   => 'm',
        _Sport.ciclismo  => 'km',
      };
  // Unidade de pace exibida no resultado
  String get paceUnit => switch (this) {
        _Sport.corrida   => 'min/km',
        _Sport.natacao   => 'min/100m',
        _Sport.ciclismo  => 'km/h',
      };
  // Distâncias de referência rápida
  List<({String label, double dist})> get quickDists => switch (this) {
        _Sport.corrida   => [
            (label: '1 km',       dist: 1),
            (label: '5 km',       dist: 5),
            (label: '10 km',      dist: 10),
            (label: '21,1 km',    dist: 21.0975),
            (label: '42,2 km',    dist: 42.195),
          ],
        _Sport.natacao   => [
            (label: '100 m',      dist: 100),
            (label: '200 m',      dist: 200),
            (label: '400 m',      dist: 400),
            (label: '1 500 m',    dist: 1500),
            (label: '3 800 m',    dist: 3800),
          ],
        _Sport.ciclismo  => [
            (label: '10 km',      dist: 10),
            (label: '20 km',      dist: 20),
            (label: '40 km',      dist: 40),
            (label: '90 km',      dist: 90),
            (label: '180 km',     dist: 180),
          ],
      };
  Color get color => switch (this) {
        _Sport.corrida  => AppColors.corrida,
        _Sport.natacao  => AppColors.natacao,
        _Sport.ciclismo => AppColors.ciclismo,
      };
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class PaceCalculatorScreen extends StatefulWidget {
  const PaceCalculatorScreen({super.key});

  @override
  State<PaceCalculatorScreen> createState() => _PaceCalculatorScreenState();
}

class _PaceCalculatorScreenState extends State<PaceCalculatorScreen> {
  _Sport _sport = _Sport.corrida;
  int    _mode  = 0; // 0 = Tempo → Pace  |  1 = Pace → Tempo

  // ── Campos modo 0: Tempo → Pace ───────────────────────────────────────────
  final _distCtrl = TextEditingController();
  final _hCtrl    = TextEditingController(text: '0');
  final _mCtrl    = TextEditingController(text: '0');
  final _sCtrl    = TextEditingController(text: '0');

  // ── Campos modo 1: Pace → Tempo ───────────────────────────────────────────
  final _dist2Ctrl  = TextEditingController();
  final _paceM      = TextEditingController(text: '5');
  final _paceS      = TextEditingController(text: '0');
  final _speedCtrl  = TextEditingController(text: '30'); // km/h (ciclismo)

  // ── Resultados ────────────────────────────────────────────────────────────
  String? _result;
  String? _extra; // linha secundária

  @override
  void dispose() {
    for (final c in [_distCtrl, _hCtrl, _mCtrl, _sCtrl,
                     _dist2Ctrl, _paceM, _paceS, _speedCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Lógica de cálculo ─────────────────────────────────────────────────────

  void _calculate() {
    setState(() {
      _result = null;
      _extra  = null;
    });

    if (_mode == 0) {
      // Tempo → Pace
      final dist  = double.tryParse(_distCtrl.text.replaceAll(',', '.'));
      final h     = int.tryParse(_hCtrl.text) ?? 0;
      final m     = int.tryParse(_mCtrl.text) ?? 0;
      final s     = int.tryParse(_sCtrl.text) ?? 0;
      if (dist == null || dist <= 0) {
        _showError('Informe uma distância válida.');
        return;
      }
      final totalSec = h * 3600 + m * 60 + s;
      if (totalSec <= 0) {
        _showError('Informe um tempo válido.');
        return;
      }

      if (_sport == _Sport.ciclismo) {
        // Velocidade média
        final hours   = totalSec / 3600;
        final kmh     = dist / hours;
        setState(() {
          _result = '${kmh.toStringAsFixed(2)} km/h';
          _extra  = 'Tempo total: ${_fmtTime(totalSec)}';
        });
      } else {
        // Pace
        final unit   = _sport == _Sport.natacao ? dist / 100 : dist;
        final paceSec = totalSec / unit;
        final pm     = (paceSec ~/ 60);
        final ps     = (paceSec % 60).round();
        setState(() {
          _result = '$pm:${ps.toString().padLeft(2, '0')} ${_sport.paceUnit}';
          _extra  = 'Tempo total: ${_fmtTime(totalSec)}';
        });
      }
    } else {
      // Pace → Tempo
      final dist = double.tryParse(_dist2Ctrl.text.replaceAll(',', '.'));
      if (dist == null || dist <= 0) {
        _showError('Informe uma distância válida.');
        return;
      }

      if (_sport == _Sport.ciclismo) {
        final kmh = double.tryParse(_speedCtrl.text.replaceAll(',', '.'));
        if (kmh == null || kmh <= 0) {
          _showError('Informe uma velocidade válida.');
          return;
        }
        final totalSec = (dist / kmh * 3600).round();
        setState(() {
          _result = _fmtTime(totalSec);
          _extra  = 'Velocidade: ${kmh.toStringAsFixed(1)} km/h · '
              'Distância: ${dist.toStringAsFixed(1)} km';
        });
      } else {
        final pm = int.tryParse(_paceM.text) ?? 0;
        final ps = int.tryParse(_paceS.text) ?? 0;
        final paceSec = pm * 60 + ps;
        if (paceSec <= 0) {
          _showError('Informe um pace válido.');
          return;
        }
        final unit     = _sport == _Sport.natacao ? dist / 100 : dist;
        final totalSec = (paceSec * unit).round();
        setState(() {
          _result = _fmtTime(totalSec);
          _extra  = 'Pace: $pm:${ps.toString().padLeft(2, '0')} '
              '${_sport.paceUnit} · '
              'Distância: ${dist.toStringAsFixed(1)} ${_sport.distUnit}';
        });
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  String _fmtTime(int totalSec) {
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m '
          '${s.toString().padLeft(2, '0')}s';
    }
    return '${m}min ${s.toString().padLeft(2, '0')}s';
  }

  void _applyQuickDist(double dist) {
    final ctrl = _mode == 0 ? _distCtrl : _dist2Ctrl;
    ctrl.text = _sport == _Sport.natacao
        ? dist.toInt().toString()
        : dist.toStringAsFixed(dist % 1 == 0 ? 0 : 4)
              .replaceAll(RegExp(r'0+$'), '')
              .replaceAll(RegExp(r'\.$'), '');
    setState(() {
      _result = null;
      _extra  = null;
    });
  }

  void _clearAll() {
    for (final c in [_distCtrl, _dist2Ctrl]) { c.clear(); }
    _hCtrl.text   = '0';
    _mCtrl.text   = '0';
    _sCtrl.text   = '0';
    _paceM.text   = '5';
    _paceS.text   = '0';
    _speedCtrl.text = '30';
    setState(() { _result = null; _extra = null; });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TreinixAppBar(
        screenTitle: 'Calculadora de Pace',
        showAppMenu: true,
        action: TextButton(
          onPressed: _clearAll,
          child: const Text('Limpar',
              style: TextStyle(color: AppColors.primary)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [

          // ── Seletor de esporte ─────────────────────────────────────────
          Row(children: _Sport.values.map((s) {
            final sel = s == _sport;
            return Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => setState(() {
                  _sport = s;
                  _result = null;
                  _extra  = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? s.color : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: sel ? s.color : AppColors.border, width: 1.5),
                  ),
                  child: Column(children: [
                    Text(s.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(s.label,
                        style: TextStyle(
                          fontSize:   11,
                          fontWeight: FontWeight.w700,
                          color:      sel ? Colors.white : AppColors.textSecondary,
                        )),
                  ]),
                ),
              ),
            ));
          }).toList()),

          const SizedBox(height: 20),

          // ── Seletor de modo ────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color:        AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              _ModeTab(label: 'Tempo → Pace',
                  selected: _mode == 0,
                  color: _sport.color,
                  onTap: () => setState(() { _mode = 0; _result = null; _extra = null; })),
              _ModeTab(label: 'Pace → Tempo',
                  selected: _mode == 1,
                  color: _sport.color,
                  onTap: () => setState(() { _mode = 1; _result = null; _extra = null; })),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Distâncias rápidas ─────────────────────────────────────────
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _sport.quickDists.map((q) => GestureDetector(
              onTap: () => _applyQuickDist(q.dist),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _sport.color.withAlpha(18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _sport.color.withAlpha(60)),
                ),
                child: Text(q.label,
                    style: TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w600,
                      color:      _sport.color,
                    )),
              ),
            )).toList(),
          ),

          const SizedBox(height: 20),

          // ── Formulário ─────────────────────────────────────────────────
          _mode == 0 ? _buildModeTempoPace() : _buildModePaceTempo(),

          const SizedBox(height: 20),

          // ── Botão calcular ─────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _calculate,
              icon:  const Icon(Icons.calculate_outlined),
              label: const Text('Calcular'),
              style: FilledButton.styleFrom(
                backgroundColor: _sport.color,
                padding:         const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // ── Resultado ──────────────────────────────────────────────────
          if (_result != null) ...[
            const SizedBox(height: 20),
            _ResultCard(
              result: _result!,
              extra:  _extra,
              color:  _sport.color,
              label:  _mode == 0 ? _sport.paceUnit : 'Tempo total',
            ),
          ],

          const SizedBox(height: 20),

          // ── Referência de pace ─────────────────────────────────────────
          _PaceReference(sport: _sport),
        ],
      ),
    );
  }

  // ── Modo 0: Tempo → Pace ──────────────────────────────────────────────────

  Widget _buildModeTempoPace() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Label('Distância (${_sport.distUnit})'),
      _DistField(_distCtrl, _sport.distUnit),
      const SizedBox(height: 14),
      const _Label('Tempo (h : min : s)'),
      Row(children: [
        Expanded(child: _TimeField(_hCtrl, 'h',   max: 24)),
        const SizedBox(width: 8),
        Expanded(child: _TimeField(_mCtrl, 'min', max: 59)),
        const SizedBox(width: 8),
        Expanded(child: _TimeField(_sCtrl, 's',   max: 59)),
      ]),
    ],
  );

  // ── Modo 1: Pace → Tempo ──────────────────────────────────────────────────

  Widget _buildModePaceTempo() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Label('Distância (${_sport.distUnit})'),
      _DistField(_dist2Ctrl, _sport.distUnit),
      const SizedBox(height: 14),
      if (_sport == _Sport.ciclismo) ...[
        const _Label('Velocidade média (km/h)'),
        _DistField(_speedCtrl, 'km/h'),
      ] else ...[
        _Label('Pace (${_sport.paceUnit})'),
        Row(children: [
          Expanded(child: _TimeField(_paceM, 'min', max: 99)),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(':', style: TextStyle(fontSize: 24,
                  fontWeight: FontWeight.w700))),
          Expanded(child: _TimeField(_paceS, 's',   max: 59)),
        ]),
      ],
    ],
  );
}

// ─── Widgets auxiliares da calculadora ───────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: AppTextStyles.label),
  );
}

class _DistField extends StatelessWidget {
  final TextEditingController ctrl;
  final String suffix;
  const _DistField(this.ctrl, this.suffix);

  @override
  Widget build(BuildContext context) => TextField(
    controller:  ctrl,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
    decoration: InputDecoration(
      suffixText: suffix,
      border:     OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );
}

class _TimeField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final int max;
  const _TimeField(this.ctrl, this.label, {required this.max});

  @override
  Widget build(BuildContext context) => TextField(
    controller:   ctrl,
    keyboardType: TextInputType.number,
    textAlign:    TextAlign.center,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      _RangeFormatter(max),
    ],
    decoration: InputDecoration(
      labelText: label,
      border:    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    ),
  );
}

class _RangeFormatter extends TextInputFormatter {
  final int max;
  const _RangeFormatter(this.max);
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final v = int.tryParse(newValue.text);
    if (v == null || v > max) return old;
    return newValue;
  }
}

class _ModeTab extends StatelessWidget {
  final String     label;
  final bool       selected;
  final Color      color;
  final VoidCallback onTap;
  const _ModeTab({required this.label, required this.selected,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color:        selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w700,
              color:      selected ? Colors.white : AppColors.textSecondary,
            )),
      ),
    ),
  );
}

class _ResultCard extends StatelessWidget {
  final String  result;
  final String? extra;
  final Color   color;
  final String  label;
  const _ResultCard({required this.result, this.extra,
      required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color, color.withAlpha(180)],
        begin: Alignment.topLeft,
        end:   Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(children: [
      const Text('Resultado', style: TextStyle(
          color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600,
          letterSpacing: 1)),
      const SizedBox(height: 8),
      Text(result, style: const TextStyle(
          color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
      if (extra != null) ...[
        const SizedBox(height: 6),
        Text(extra!, style: const TextStyle(
            color: Colors.white70, fontSize: 12)),
      ],
    ]),
  );
}

// ─── Tabela de referência de pace ─────────────────────────────────────────────

class _PaceReference extends StatelessWidget {
  final _Sport sport;
  const _PaceReference({required this.sport});

  List<({String level, String value})> get _refs => switch (sport) {
        _Sport.corrida  => [
            (level: 'Iniciante',       value: '7:00–9:00 min/km'),
            (level: 'Intermediário',   value: '5:00–7:00 min/km'),
            (level: 'Avançado',        value: '4:00–5:00 min/km'),
            (level: 'Elite amador',    value: '< 4:00 min/km'),
          ],
        _Sport.natacao  => [
            (level: 'Iniciante',       value: '2:30–3:30 min/100m'),
            (level: 'Intermediário',   value: '1:45–2:30 min/100m'),
            (level: 'Avançado',        value: '1:20–1:45 min/100m'),
            (level: 'Elite amador',    value: '< 1:20 min/100m'),
          ],
        _Sport.ciclismo => [
            (level: 'Iniciante',       value: '15–20 km/h'),
            (level: 'Intermediário',   value: '20–28 km/h'),
            (level: 'Avançado',        value: '28–35 km/h'),
            (level: 'Elite amador',    value: '> 35 km/h'),
          ],
      };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border, width: 0.8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.info_outline, size: 16, color: sport.color),
          const SizedBox(width: 6),
          Text('Referências de pace — ${sport.label}',
              style: AppTextStyles.label),
        ]),
        const SizedBox(height: 10),
        ..._refs.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Expanded(child: Text(r.level, style: AppTextStyles.bodySm)),
            Text(r.value,
                style: AppTextStyles.bodySm.copyWith(
                    color: sport.color, fontWeight: FontWeight.w600)),
          ]),
        )),
      ],
    ),
  );
}
