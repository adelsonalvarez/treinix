// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/ui/widgets/exercise_editor.dart
// Camada   : Widget compartilhado – Editor de exercícios
// Descrição: Dialog e seção de lista de exercícios cientes da modalidade.
//            Usados tanto no PlanDetailScreen quanto no LogTrainingScreen.
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
import '../../data/models/training_model.dart';
import '../../data/models/user_model.dart';

// ─── Configuração de campos por modalidade ────────────────────────────────────

class _ModalityConfig {
  final String nameLabel;
  final String setsLabel;
  final String loadLabel;
  final String restLabel;
  final String notesLabel;
  final bool showReps;
  final bool showGroup;
  final String namePlaceholder;
  final String setsPlaceholder;
  final String loadPlaceholder;
  final String restPlaceholder;
  final String notesPlaceholder;

  const _ModalityConfig({
    required this.nameLabel,
    required this.setsLabel,
    required this.loadLabel,
    required this.restLabel,
    required this.notesLabel,
    required this.showReps,
    required this.showGroup,
    required this.namePlaceholder,
    required this.setsPlaceholder,
    required this.loadPlaceholder,
    required this.restPlaceholder,
    required this.notesPlaceholder,
  });
}

_ModalityConfig _configFor(Modality m) => switch (m) {
  Modality.musculacao => const _ModalityConfig(
    nameLabel:       'Nome do exercício',
    setsLabel:       'Séries',
    loadLabel:       'Carga',
    restLabel:       'Descanso entre séries',
    notesLabel:      'Observações',
    showReps:        true,
    showGroup:       true,
    namePlaceholder: 'Ex: Supino Reto, Agachamento...',
    setsPlaceholder: 'Ex: 3',
    loadPlaceholder: 'Ex: 80kg ou 80/70/60kg',
    restPlaceholder: 'Ex: 90s, 2 min',
    notesPlaceholder: 'Ex: Manter coluna neutra',
  ),
  Modality.natacao => const _ModalityConfig(
    nameLabel:       'Estilo / descrição',
    setsLabel:       'Séries',
    loadLabel:       'Distância',
    restLabel:       'Pausa entre séries',
    notesLabel:      'Detalhes',
    showReps:        false,
    showGroup:       false,
    namePlaceholder: 'Ex: Crawl, Medley, Costas...',
    setsPlaceholder: 'Ex: 4',
    loadPlaceholder: 'Ex: 50m, 200m',
    restPlaceholder: 'Ex: 30s, 1 min',
    notesPlaceholder: 'Ex: B/C/P/L, foco em virada',
  ),
  _ => const _ModalityConfig(
    nameLabel:       'Tipo de esforço',
    setsLabel:       'Repetições',
    loadLabel:       'Distância / Tempo',
    restLabel:       'Recuperação',
    notesLabel:      'Observações',
    showReps:        false,
    showGroup:       false,
    namePlaceholder: 'Ex: Corrida forte, Base Z2, Limiar...',
    setsPlaceholder: 'Ex: 10 (deixe vazio se contínuo)',
    loadPlaceholder: 'Ex: 200m, 20 min, 5km',
    restPlaceholder: 'Ex: 100m caminhada, 2 min pausa',
    notesPlaceholder: 'Ex: FC > 90% FCmáx',
  ),
};

// ─── Dialog de edição de um exercício ────────────────────────────────────────

class ExerciseEditorDialog extends StatefulWidget {
  final ExerciseItem? exercise;
  final Modality      modality;

  const ExerciseEditorDialog({
    super.key,
    this.exercise,
    required this.modality,
  });

  @override
  State<ExerciseEditorDialog> createState() => _ExerciseEditorDialogState();
}

class _ExerciseEditorDialogState extends State<ExerciseEditorDialog> {
  final _formKey   = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _sets;
  late final TextEditingController _reps;
  late final TextEditingController _load;
  late final TextEditingController _rest;
  late final TextEditingController _group;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final ex = widget.exercise;
    _name  = TextEditingController(text: ex?.name  ?? '');
    _sets  = TextEditingController(text: ex?.sets?.toString() ?? '');
    _reps  = TextEditingController(text: ex?.reps  ?? '');
    _load  = TextEditingController(text: ex?.load  ?? '');
    _rest  = TextEditingController(text: ex?.rest  ?? '');
    _group = TextEditingController(text: ex?.group ?? '');
    _notes = TextEditingController(text: ex?.notes ?? '');
  }

  @override
  void dispose() {
    for (final c in [_name, _sets, _reps, _load, _rest, _group, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(ExerciseItem(
      name:  _name.text.trim(),
      sets:  int.tryParse(_sets.text.trim()),
      reps:  _reps.text.trim().isEmpty ? null : _reps.text.trim(),
      load:  _load.text.trim().isEmpty ? null : _load.text.trim(),
      rest:  _rest.text.trim().isEmpty ? null : _rest.text.trim(),
      group: _group.text.trim().isEmpty ? null : _group.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    ));
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText:      label,
        hintText:       hint,
        hintStyle:      AppTextStyles.caption
            .copyWith(color: AppColors.textTertiary),
        border:         const OutlineInputBorder(),
        isDense:        true,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
      );

  @override
  Widget build(BuildContext context) {
    final cfg   = _configFor(widget.modality);
    final isNew = widget.exercise == null;

    return AlertDialog(
      title: Text(isNew ? 'Novo exercício' : 'Editar exercício'),
      scrollable: true,
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Nome (obrigatório)
              TextFormField(
                controller: _name,
                decoration: _dec(cfg.nameLabel,
                    hint: cfg.namePlaceholder),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),

              // Séries + Repetições (reps apenas musculação)
              if (cfg.showReps)
                Row(children: [
                  Expanded(child: TextFormField(
                    controller: _sets,
                    decoration: _dec(cfg.setsLabel,
                        hint: cfg.setsPlaceholder),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(
                    controller: _reps,
                    decoration: _dec('Repetições',
                        hint: 'Ex: 10 ou 12/10/8'),
                  )),
                ])
              else
                TextFormField(
                  controller: _sets,
                  decoration:
                      _dec(cfg.setsLabel, hint: cfg.setsPlaceholder),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              const SizedBox(height: 12),

              // Carga / Distância / Tempo
              TextFormField(
                controller: _load,
                decoration:
                    _dec(cfg.loadLabel, hint: cfg.loadPlaceholder),
              ),
              const SizedBox(height: 12),

              // Descanso / Recuperação / Pausa
              TextFormField(
                controller: _rest,
                decoration:
                    _dec(cfg.restLabel, hint: cfg.restPlaceholder),
              ),

              // Grupo (bi-set / tri-set) — somente musculação
              if (cfg.showGroup) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _group,
                  decoration: _dec(
                    'Agrupar em (bi-set / tri-set)',
                    hint: 'Ex: Bi-set A, Tri-set 1',
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Observações / Detalhes
              TextFormField(
                controller: _notes,
                decoration: _dec(cfg.notesLabel,
                    hint: cfg.notesPlaceholder),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: Text(
            isNew ? 'Adicionar' : 'Salvar',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ─── Seção de lista de exercícios (display + add/edit/delete) ─────────────────

class ExerciseListSection extends StatelessWidget {
  final List<ExerciseItem>              exercises;
  final Modality                        modality;
  final Color                           color;
  final bool                            readOnly;
  final void Function(List<ExerciseItem>) onChanged;

  const ExerciseListSection({
    super.key,
    required this.exercises,
    required this.modality,
    required this.color,
    required this.onChanged,
    this.readOnly = false,
  });

  Future<void> _openEditor(
      BuildContext context, {ExerciseItem? exercise}) async {
    final result = await showDialog<ExerciseItem>(
      context: context,
      builder: (_) => ExerciseEditorDialog(
        exercise: exercise,
        modality: modality,
      ),
    );
    if (result == null || !context.mounted) return;

    if (exercise == null) {
      // add
      onChanged([...exercises, result]);
    } else {
      // edit
      final idx = exercises.indexOf(exercise);
      final updated = List<ExerciseItem>.from(exercises);
      updated[idx] = result;
      onChanged(updated);
    }
  }

  void _delete(BuildContext context, ExerciseItem exercise) {
    final updated = List<ExerciseItem>.from(exercises)..remove(exercise);
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(children: [
          Text(
            'Exercícios${exercises.isEmpty ? '' : ' (${exercises.length})'}',
            style: AppTextStyles.label,
          ),
          const Spacer(),
          if (!readOnly)
            TextButton.icon(
              onPressed: () => _openEditor(context),
              icon:  Icon(Icons.add, size: 16, color: color),
              label: Text('Adicionar', style: TextStyle(color: color)),
              style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact),
            ),
        ]),
        const SizedBox(height: 8),

        if (exercises.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color:        AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border:       Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'Nenhum exercício cadastrado',
                style: AppTextStyles.caption,
              ),
            ),
          )
        else
          ...exercises.asMap().entries.map((e) {
            final i  = e.key;
            final ex = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Número
                  Container(
                    width: 26, height: 26,
                    margin: const EdgeInsets.only(right: 10, top: 2),
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color:      color,
                        fontSize:   12,
                        fontWeight: FontWeight.w700,
                      ),
                    )),
                  ),
                  // Conteúdo
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ex.name,
                          style: AppTextStyles.bodyMedium),
                      if (ex.displayLine.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(ex.displayLine,
                              style: AppTextStyles.caption),
                        ),
                      if (ex.group != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withAlpha(30),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(ex.group!,
                                style: AppTextStyles.caption
                                    .copyWith(color: color)),
                          ),
                        ),
                    ],
                  )),
                  // Botões (apenas em modo edição)
                  if (!readOnly) ...[
                    InkWell(
                      onTap: () => _openEditor(context, exercise: ex),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.edit_outlined,
                            size: 16, color: color),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _delete(context, ex),
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline,
                            size: 16, color: AppColors.error),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }
}
