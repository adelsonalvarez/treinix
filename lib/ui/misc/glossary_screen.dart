// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : lib/ui/misc/glossary_screen.dart
// Camada   : Screen – Glossário de Termos Técnicos
// Descrição: Dicionário pesquisável com termos técnicos de treino, fisiologia
//            e esportes de endurance — auxilia atletas iniciantes a
//            compreenderem os planos gerados pela IA.
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

// ─── Modelo de verbete ────────────────────────────────────────────────────────

class _Term {
  final String term;
  final String definition;
  final String category;
  const _Term(this.term, this.definition, this.category);
}

// ─── Base de termos ───────────────────────────────────────────────────────────

const _terms = <_Term>[

  // Fisiologia
  _Term('VO₂ Máx',
      'Volume máximo de oxigênio que o organismo consegue consumir por minuto por kg de peso corporal. '
      'É o principal indicador de capacidade aeróbica: quanto maior, melhor o desempenho em esportes de endurance.',
      'Fisiologia'),
  _Term('FC (Frequência Cardíaca)',
      'Número de batimentos do coração por minuto (bpm). '
      'Usada para monitorar a intensidade do treino em tempo real.',
      'Fisiologia'),
  _Term('FC Máx (FC Máxima)',
      'Maior frequência cardíaca que o coração pode atingir durante esforço máximo. '
      'Estimativa rápida: 220 − sua idade. Serve de base para calcular as zonas de treino.',
      'Fisiologia'),
  _Term('FC de Repouso',
      'Frequência cardíaca medida em estado de completo repouso, idealmente ao acordar. '
      'Atletas bem condicionados costumam ter FC de repouso abaixo de 50 bpm.',
      'Fisiologia'),
  _Term('Zonas de FC',
      'Faixas de intensidade baseadas em percentuais da FC Máxima:\n'
      '• Zona 1 (50–60 %): recuperação ativa\n'
      '• Zona 2 (60–70 %): base aeróbica\n'
      '• Zona 3 (70–80 %): aeróbico moderado\n'
      '• Zona 4 (80–90 %): limiar anaeróbio\n'
      '• Zona 5 (90–100 %): máxima',
      'Fisiologia'),
  _Term('Limiar Anaeróbio',
      'Intensidade de esforço a partir da qual o lactato começa a se acumular no sangue '
      'mais rápido do que o corpo consegue eliminá-lo (aprox. 80–90 % da FC Máx). '
      'Treinar nessa faixa melhora o ritmo sustentável em provas.',
      'Fisiologia'),
  _Term('Lactato',
      'Subproduto do metabolismo anaeróbio liberado quando os músculos trabalham sem '
      'oxigênio suficiente. Seu acúmulo causa a sensação de queimação e fadiga muscular.',
      'Fisiologia'),
  _Term('ATP (Adenosina Trifosfato)',
      'Principal molécula de energia das células musculares. '
      'É "reconstruída" continuamente pelos sistemas aeróbico e anaeróbio durante o exercício.',
      'Fisiologia'),
  _Term('Glicogênio',
      'Forma de armazenamento dos carboidratos nos músculos e no fígado. '
      'É o combustível preferido em treinos de intensidade moderada a alta. '
      'Quando esgotado, surge o temido "muro" nas maratonas.',
      'Fisiologia'),

  // Geral
  _Term('RPE (Percepção de Esforço)',
      'Escala subjetiva de intensidade de 0 a 10 (ou 6–20 na escala de Borg). '
      'RPE 6–7 = conversa fácil; RPE 8–9 = difícil falar; RPE 10 = esforço máximo.',
      'Geral'),
  _Term('HIIT',
      'High-Intensity Interval Training — treino intervalado de alta intensidade. '
      'Alterna blocos de esforço máximo (20 s–4 min) com períodos de recuperação. '
      'Muito eficiente para melhorar VO₂ Máx e queima calórica.',
      'Geral'),
  _Term('Periodização',
      'Planejamento estruturado do treino em ciclos progressivos:\n'
      '• Microciclo: ~1 semana\n'
      '• Mesociclo: 4–6 semanas\n'
      '• Macrociclo: temporada completa\n'
      'Objetivo: evitar estagnação e lesões, atingindo o pico na competição certa.',
      'Geral'),
  _Term('Volume de Treino',
      'Quantidade total de trabalho realizado: km percorridos, tonelagem levantada '
      'ou tempo total de exercício. Aumentar o volume gradualmente (~10 % por semana) '
      'é a regra de ouro para evitar overtraining.',
      'Geral'),
  _Term('Intensidade',
      'Grau de esforço do treino. Pode ser medida por % da FC Máx, pace, wattagem ou RPE. '
      'Nem todo treino deve ser intenso — a maioria (~80 %) deve ser em intensidade baixa a moderada.',
      'Geral'),
  _Term('Overtraining',
      'Síndrome causada por excesso de treino sem recuperação adequada. '
      'Sintomas: queda de desempenho, fadiga crônica, irritabilidade e maior risco de lesão. '
      'Solução: descanso, sono de qualidade e nutrição adequada.',
      'Geral'),
  _Term('Taper',
      'Redução programada do volume de treino nos dias/semanas que antecedem uma competição. '
      'Objetivo: chegar à prova com os músculos recuperados e os estoques de glicogênio cheios.',
      'Geral'),
  _Term('Recuperação Ativa',
      'Atividade de baixíssima intensidade (caminhada, natação leve, yoga) realizada nos dias '
      'de descanso para acelerar a remoção de lactato e reduzir a rigidez muscular.',
      'Geral'),

  // Corrida
  _Term('Pace (Corrida)',
      'Tempo necessário para percorrer 1 km. Expresso em min:ss/km.\n'
      'Exemplo: pace 5:00 = 5 minutos para correr 1 km = velocidade de 12 km/h.',
      'Corrida'),
  _Term('Cadência (Corrida)',
      'Número de passadas (contando ambos os pés) por minuto. '
      'A maioria dos corredores eficientes treina entre 170–180 spm (steps per minute). '
      'Cadência baixa tende a indicar passada longa demais e maior risco de lesão.',
      'Corrida'),
  _Term('Fartlek',
      'Palavra sueca para "jogo de velocidade". Treino que mescla ritmos diferentes '
      '(lento, moderado e rápido) de forma livre, sem intervalos fixos. '
      'Ótimo para desenvolver variação de pace e consciência de ritmo.',
      'Corrida'),
  _Term('Tempo Run',
      'Corrida contínua em ritmo "confortavelmente difícil" — aproximadamente no limiar anaeróbio. '
      'Melhora a capacidade de sustentar pace elevado por mais tempo.',
      'Corrida'),
  _Term('Long Run',
      'Corrida longa semanal realizada em ritmo fácil (Zona 1–2). '
      'Desenvolve a base aeróbica, a queima de gordura e a resistência mental.',
      'Corrida'),
  _Term('Splits',
      'Tempos parciais registrados em cada km ou cada volta de uma prova. '
      'Negative splits = a segunda metade mais rápida que a primeira, sinal de boa estratégia de prova.',
      'Corrida'),
  _Term('PR / PB',
      'Personal Record / Personal Best — melhor marca pessoal em uma determinada distância. '
      'Ex.: PR nos 10 km, PR na maratona.',
      'Corrida'),

  // Zonas de treino — natação
  _Term('Z1 (Zona 1)',
      'Zona de recuperação ativa: 50–60 % da FC Máx.\n'
      'Na natação, corresponde a nados suaves e contínuos usados no aquecimento, '
      'no desaquecimento e nos intervalos de recuperação entre séries. '
      'Sensação: esforço mínimo, respiração tranquila, conversa fácil.',
      'Natação'),
  _Term('Z2 (Zona 2)',
      'Zona aeróbica de base: 60–70 % da FC Máx.\n'
      'Base do volume de treino na natação. Desenvolve a eficiência do motor aeróbico, '
      'melhora o aproveitamento de gordura como combustível e constrói resistência '
      'sem gerar fadiga excessiva. A maior parte do treino de endurance deve ser em Z2. '
      'Sensação: respiração controlada, pace sustentável por longos períodos.',
      'Natação'),
  _Term('Z3 (Zona 3)',
      'Zona aeróbica moderada: 70–80 % da FC Máx.\n'
      'Treino de ritmo moderado que eleva o limiar aeróbico. '
      'Na natação é usada em séries longas (ex.: 4 × 400 m) para trabalhar a '
      'capacidade de nadar rápido por tempo prolongado. '
      'Sensação: respiração mais intensa, conversa possível mas difícil.',
      'Natação'),
  _Term('Z4 (Zona 4)',
      'Zona de limiar anaeróbio: 80–90 % da FC Máx.\n'
      'Trabalho de alta intensidade próximo ao limiar anaeróbio — ponto onde o '
      'lactato começa a se acumular. Na natação são séries como 8 × 100 m com '
      'intervalo curto. Melhora o pace de prova. '
      'Sensação: esforço duro, respiração pesada, difícil manter conversa.',
      'Natação'),
  _Term('Z5 (Zona 5)',
      'Zona máxima / VO₂ Máx: 90–100 % da FC Máx.\n'
      'Esforço máximo ou supramáximo. Na natação corresponde a tiros curtos '
      '(25–50 m) em velocidade máxima com recuperação completa entre repetições. '
      'Desenvolve a potência anaeróbica e o VO₂ Máx. '
      'Sensação: impossível manter conversa, ardência muscular intensa.',
      'Natação'),

  // Natação
  _Term('Pace (Natação)',
      'Tempo para percorrer 100 metros. Expresso em min:ss/100m.\n'
      'Exemplo: pace 1:45 = 1 min e 45 s por 100 metros.',
      'Natação'),
  _Term('DPS (Distância por Braçada)',
      'Metros percorridos a cada ciclo completo de braçada. '
      'DPS alto + cadência adequada = natação eficiente. '
      'Medida com SWOLF: tempo de largada + número de braçadas.',
      'Natação'),
  _Term('SWOLF',
      'Soma do tempo (em segundos) com o número de braçadas numa largada. '
      'Quanto menor o SWOLF, mais eficiente a técnica. '
      'Ex.: 30 s + 20 braçadas = SWOLF 50.',
      'Natação'),
  _Term('Puxada / Tração',
      'Fase da braçada em que a mão empurra a água para trás, gerando propulsão. '
      'É a parte mais importante da braçada em termos de potência.',
      'Natação'),

  // Ciclismo
  _Term('Pace (Ciclismo)',
      'Em ciclismo, o "pace" é normalmente expresso como velocidade média em km/h, '
      'e não como tempo por km. Também pode ser monitorado em watts (potência).',
      'Ciclismo'),
  _Term('Cadência (Ciclismo)',
      'Rotações do pedivela por minuto (rpm). '
      'Cadência ideal para ciclismo de resistência: 80–100 rpm. '
      'Cadência baixa com grande desenvolvimento sobrecarrega os joelhos.',
      'Ciclismo'),
  _Term('Watt (Potência)',
      'Unidade que mede o trabalho realizado por unidade de tempo. '
      'É a métrica mais objetiva do desempenho ciclístico, pois não depende de vento ou terreno.',
      'Ciclismo'),
  _Term('FTP (Functional Threshold Power)',
      'Potência máxima que o ciclista consegue sustentar por ~60 minutos. '
      'Base para definir zonas de treino em watts. '
      'Estimado por teste de 20 min × 95 % do resultado.',
      'Ciclismo'),
  _Term('Drafting',
      'Pedalar na esteira aerodinâmica de outro ciclista, reduzindo em até 30 % o esforço. '
      'Proibido em provas de triathlon, mas é estratégia fundamental no ciclismo de estrada.',
      'Ciclismo'),

  // Musculação
  _Term('RM (Repetição Máxima)',
      'Carga máxima que pode ser levantada corretamente em um único movimento. '
      '1RM é a referência para prescrever cargas de treino (ex.: trabalhar a 70 % do 1RM).',
      'Musculação'),
  _Term('Hipertrofia',
      'Aumento do volume das fibras musculares como adaptação ao treino de força. '
      'Requer estímulo (treino), nutrição proteica adequada e descanso suficiente.',
      'Musculação'),
  _Term('Drop Set',
      'Técnica avançada: após atingir a falha muscular, reduz-se imediatamente a carga '
      'e continua-se o exercício. Aumenta o volume de trabalho e o estímulo de hipertrofia.',
      'Musculação'),
  _Term('Superset',
      'Dois exercícios realizados em sequência sem descanso entre eles. '
      'Pode ser agonista–agonista (mesmo músculo) ou antagonista–agonista (músculos opostos).',
      'Musculação'),
  _Term('Falha Muscular',
      'Ponto em que não é possível completar mais uma repetição com técnica correta. '
      'Treinar até a falha maximiza o estímulo, mas deve ser usado com moderação para evitar overtraining.',
      'Musculação'),
  _Term('TUT (Tempo sob Tensão)',
      'Duração total em que o músculo permanece sob carga durante uma série. '
      'Aumentar o TUT (ex.: 3 s descida, 1 s pausa, 2 s subida) intensifica o estímulo sem aumentar carga.',
      'Musculação'),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  String _query    = '';
  String _category = 'Todos';

  static const _categories = [
    'Todos', 'Fisiologia', 'Geral', 'Corrida', 'Natação', 'Ciclismo', 'Musculação',
  ];

  List<_Term> get _filtered {
    final q = _query.toLowerCase();
    return _terms.where((t) {
      final matchCat = _category == 'Todos' || t.category == _category;
      final matchQ   = q.isEmpty ||
          t.term.toLowerCase().contains(q) ||
          t.definition.toLowerCase().contains(q);
      return matchCat && matchQ;
    }).toList()
      ..sort((a, b) => a.term.compareTo(b.term));
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const TreinixAppBar(
        screenTitle: 'Glossário',
        showAppMenu: true,
      ),
      body: Column(children: [

        // ── Busca + filtro por categoria ──────────────────────────────────
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(children: [
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText:    'Buscar termo…',
                prefixIcon:  const Icon(Icons.search, size: 20),
                filled:      true,
                fillColor:   AppColors.background,
                border:      OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 14),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount:       _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final cat      = _categories[i];
                  final selected = cat == _category;
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.w600,
                          color:      selected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ]),
        ),

        // ── Lista de termos ───────────────────────────────────────────────
        Expanded(
          child: results.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🔍',
                          style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('Nenhum termo encontrado',
                          style: AppTextStyles.heading3),
                      SizedBox(height: 6),
                      Text('Tente outra palavra ou categoria',
                          style: AppTextStyles.bodySm),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: results.length,
                  itemBuilder: (_, i) => _TermCard(term: results[i]),
                ),
        ),
      ]),
    );
  }
}

// ─── Card expansível de verbete ───────────────────────────────────────────────

class _TermCard extends StatefulWidget {
  final _Term term;
  const _TermCard({required this.term});

  @override
  State<_TermCard> createState() => _TermCardState();
}

class _TermCardState extends State<_TermCard> {
  bool _open = false;

  Color get _categoryColor => switch (widget.term.category) {
        'Fisiologia' => AppColors.error,
        'Corrida'    => AppColors.corrida,
        'Natação'    => AppColors.natacao,
        'Ciclismo'   => AppColors.ciclismo,
        'Musculação' => AppColors.musculacao,
        _            => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => _open = !_open),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin:   const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _open
              ? _categoryColor.withAlpha(120)
              : AppColors.border,
          width: _open ? 1.5 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Cabeçalho sempre visível
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color:  _categoryColor,
                  shape:  BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.term.term,
                        style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 1),
                    Text(widget.term.category,
                        style: AppTextStyles.caption.copyWith(
                            color: _categoryColor,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Icon(
                _open
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ]),
          ),

          // Definição — visível apenas quando expandido
          if (_open) ...[
            Divider(
                height: 0,
                color: _categoryColor.withAlpha(60)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Text(
                widget.term.definition,
                style: AppTextStyles.bodySm.copyWith(height: 1.6),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
