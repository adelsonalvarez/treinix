// =============================================================================
// Projeto  : Treinix – Treinador Digital para Atletas Amadores
// Arquivo  : functions/index.js
// Camada   : Backend – Cloud Functions (Firebase)
// Descrição: Dois prompts distintos por categoria:
//            - Musculação: plano mensal fixo com divisão A/B e sobrecarga progressiva
//            - Endurance: plano semanal variado com zonas metabólicas e tapering
// -----------------------------------------------------------------------------
// Autor    : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso    : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano      : 2026
// =============================================================================

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const Anthropic = require("@anthropic-ai/sdk");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// Cooldown mínimo entre gerações por modalidade (horas).
// Evita abuso de tokens mesmo que o usuário conclua sessões artificialmente.
const COOLDOWN_HOURS = 24;

const claudeApiKey = defineSecret("CLAUDE_API_KEY");

const LEVEL_LABELS = {
  iniciante:     "Iniciante (menos de 6 meses de prática)",
  intermediario: "Intermediário (6 meses a 2 anos de prática regular)",
  avancado:      "Avançado (mais de 2 anos, participa de competições)",
};

const GOAL_LABELS = {
  saude:         "Saúde e qualidade de vida geral",
  resistencia:   "Melhorar resistência e volume",
  forca:         "Ganhar força e massa muscular",
  emagrecimento: "Emagrecer com saúde",
  desempenho:    "Melhorar desempenho e resultado em provas",
};

const FOCUS_LABELS = {
  velocidade:   "Velocidade e ritmo (tiros, potência, cadência alta)",
  resistencia:  "Resistência e volume (base aeróbica, longão)",
  tecnica:      "Técnica e eficiência de movimento",
  regenerativo: "Regenerativo (recuperação ativa, baixa intensidade)",
  forca:        "Força e potência muscular",
};

const INTENSITY_LABELS = {
  leve:     "Leve (Z1-Z2 — conversacional, FC baixa)",
  moderado: "Moderado (Z3 — desconfortável mas sustentável)",
  intenso:  "Intenso (Z4-Z5 — acima do limiar, tiros curtos)",
};

// ─── Prompt para MUSCULAÇÃO ───────────────────────────────────────────────────
// Lógica: plano mensal fixo, divisão A/B, sobrecarga progressiva, SEM variação diária

function buildMusclePrompt(data) {
  const { level, goal, age, daysPerWeek, focus, intensity, freeText } = data;
  const hasFreeText = freeText && freeText.trim().length > 0;

  return `Você é um personal trainer especializado em musculação para atletas amadores brasileiros.

IMPORTANTE: Musculação é um treino REPETITIVO por definição. O progresso vem da SOBRECARGA PROGRESSIVA nos mesmos exercícios ao longo de semanas, NÃO da troca constante de exercícios.

Gere um PLANO MENSAL de musculação (4 semanas) para o atleta abaixo.

${hasFreeText ? `⚠️  INSTRUÇÕES ESPECÍFICAS DO ATLETA (PRIORIDADE MÁXIMA — siga à risca):
"${freeText.trim()}"
Se o atleta especificou dias, grupos musculares, restrições ou qualquer outra instrução acima, elas SUBSTITUEM os parâmetros do perfil abaixo.

` : ""}═══ INTENÇÃO DESTA SEMANA (definida pelo atleta no app) ═══
- Foco principal: ${FOCUS_LABELS[focus] || focus}
- Intensidade desejada: ${INTENSITY_LABELS[intensity] || intensity}

═══ PERFIL DO ATLETA (contexto base) ═══
- Nível: ${LEVEL_LABELS[level] || level}
- Objetivo de longo prazo: ${GOAL_LABELS[goal] || goal}
- Idade: ${age > 0 ? age + " anos" : "não informada"}
- Dias disponíveis por semana: ${daysPerWeek}${hasFreeText ? " (ajuste se o atleta especificou diferente acima)" : ""}

═══ REGRAS DO PLANO ═══
- Crie treinos numerados: Treino 1, Treino 2, etc. (conforme os dias disponíveis)
- Cada treino deve ter 5 a 7 exercícios com séries e repetições
- Os MESMOS exercícios se repetem por todo o mês — a progressão vem da carga
- Inclua aquecimento e orientação de descanso entre séries
- Adapte volume e intensidade ao nível do atleta
- Bi-sets e tri-sets devem ter o mesmo valor no campo "group" (ex: "Bi-set A")
- Para exercícios com cargas variáveis por série, use o campo "reps" com formato "12/10/8"

═══ FORMATO DOS EXERCÍCIOS ═══
Cada exercício em "steps" deve ser um OBJETO com os campos:
- "name": nome do exercício (obrigatório)
- "sets": número de séries como inteiro (ex: 4)
- "reps": repetições por série — pode variar: "10" ou "12/10/8"
- "load": carga inicial sugerida ou progressão (ex: "Conforme capacidade", "60-80% 1RM")
- "rest": tempo de descanso entre séries (ex: "90s", "2 min")
- "group": nome do bi-set/tri-set se agrupado (ex: "Bi-set A") — omitir se isolado
- "notes": dica de execução técnica (opcional)

Responda EXCLUSIVAMENTE com JSON válido, sem markdown:

{
  "modality": "musculacao",
  "planType": "mensal",
  "title": "Plano de Musculação — [objetivo] — [nível]",
  "overview": "Descrição do plano em 2-3 frases explicando a lógica de divisão e progressão",
  "sessions": [
    {
      "label": "Treino 1",
      "focus": "Grupos musculares trabalhados",
      "description": "Objetivo desta sessão e como se encaixa no plano",
      "durationMinutes": 60,
      "steps": [
        {"name": "Aquecimento cardiovascular", "load": "10 min esteira leve", "notes": "FC < 60% FCmáx"},
        {"name": "Supino Reto", "sets": 4, "reps": "10-12", "load": "Conforme capacidade", "rest": "90s", "notes": "Desça o halter até o peito"},
        {"name": "Crucifixo", "sets": 3, "reps": "12", "rest": "60s", "group": "Bi-set A", "notes": "Leve — foco no alongamento"},
        {"name": "Peck Deck", "sets": 3, "reps": "15", "rest": "60s", "group": "Bi-set A"}
      ]
    },
    {
      "label": "Treino 2",
      "focus": "Grupos musculares trabalhados",
      "description": "Objetivo desta sessão",
      "durationMinutes": 60,
      "steps": [
        {"name": "Exemplo", "sets": 3, "reps": "10", "rest": "90s"}
      ]
    }
  ],
  "tip": "Orientação sobre progressão de carga e como evoluir ao longo do mês",
  "hasTapering": false
}`;
}

// ─── Prompt para ENDURANCE (Natação, Corrida, Ciclismo) ──────────────────────
// Lógica: plano semanal variado, zonas metabólicas, tapering se houver competição

function buildEndurancePrompt(data) {
  const {
    modality, level, goal, age, daysPerWeek,
    weeksToCompetition, competitionName,
    focus, intensity, freeText, durationMinutes,
  } = data;

  const modalityNames = { natacao: "Natação", corrida: "Corrida", ciclismo: "Ciclismo" };
  const modalityName  = modalityNames[modality] || modality;
  const isCompetition = goal === "desempenho" && weeksToCompetition > 0;
  const hasFreeText   = freeText && freeText.trim().length > 0;

  const competitionBlock = isCompetition ? `
- OBJETIVO: Preparação para competição "${competitionName || "prova"}"
- Semanas até a prova: ${weeksToCompetition}
- ${weeksToCompetition <= 2
    ? "FASE DE POLIMENTO (TAPERING): Reduza o volume drasticamente. Mantenha 1-2 estímulos curtos no ritmo de prova para manter a intensidade sem acumular fadiga."
    : weeksToCompetition <= 4
    ? "FASE DE AFUNILAMENTO: Reduza levemente o volume. Aumente a especificidade (treinos no ritmo de prova)."
    : "FASE DE CONSTRUÇÃO: Foque em volume e base aeróbica. Semanas finais aproximam do ritmo de prova."
  }` : `
- OBJETIVO: Prática regular para ${GOAL_LABELS[goal] || goal} (sem competição próxima)
- Varie os estímulos semanais para manter motivação e evitar estagnação`;

  return `Você é um treinador especializado em esportes de endurance para atletas amadores brasileiros.

IMPORTANTE: Em esportes de endurance, o gesto motor é sempre o mesmo (nadar, correr, pedalar). A variação acontece no ESTÍMULO FISIOLÓGICO e nas ZONAS METABÓLICAS. NUNCA repita o mesmo tipo de sessão duas vezes na mesma semana.

Gere um PLANO SEMANAL de ${modalityName} para o atleta abaixo.

${hasFreeText ? `⚠️  INSTRUÇÕES ESPECÍFICAS DO ATLETA (PRIORIDADE MÁXIMA — siga à risca):
"${freeText.trim()}"
Se o atleta especificou dias de treino, datas de competição, quantidade de sessões ou qualquer outra instrução acima, elas SUBSTITUEM os parâmetros do perfil abaixo. Em especial:
- Se mencionou N dias de treino → gere exatamente N sessões
- Se mencionou uma data de competição → priorize tapering/preparação para essa prova
- Se mencionou um foco específico → sobreponha ao foco selecionado no app

` : ""}═══ INTENÇÃO DESTA SEMANA (definida pelo atleta no app) ═══
- Foco principal: ${FOCUS_LABELS[focus] || focus}
- Intensidade desejada: ${INTENSITY_LABELS[intensity] || intensity}

═══ PERFIL DO ATLETA (contexto base) ═══
- Modalidade: ${modalityName}
- Nível: ${LEVEL_LABELS[level] || level}
- Objetivo de longo prazo: ${GOAL_LABELS[goal] || goal}
- Idade: ${age > 0 ? age + " anos" : "não informada"}
- Dias disponíveis por semana: ${daysPerWeek}${hasFreeText ? " (ajuste se o atleta especificou diferente nas instruções acima)" : ""}
- Tempo por sessão: aproximadamente ${durationMinutes} minutos
${competitionBlock}

═══ TIPOS DE SESSÃO DISPONÍVEIS ═══
Use apenas os que couberem no número de dias disponíveis (${daysPerWeek} dias):
- BASE/Z2: Volume contínuo em ritmo conversacional (pode falar sem se ofegar)
- TIRO/INTERVALADO: Séries de alta intensidade para potência aeróbica (VO2 máx)
- LIMIAR/TEMPO: Ritmo moderado-forte sustentado (30-40 min contínuos)
- LONGÃO: Maior volume da semana, ritmo confortável, adaptação energética
- REGENERATIVO: Estímulo muito leve, apenas para recuperação ativa
${isCompetition && weeksToCompetition <= 2 ? "- RITMO DE PROVA: Estímulo curto no ritmo exato da competição" : ""}

═══ REGRAS ═══
- Cada sessão deve ter objetivo e zona metabólica DIFERENTES
- Respeite o tempo de ${durationMinutes} minutos por sessão
- Para natação: especifique metros, estilos, intervalos e pausas (ex: 4×50m crawl pausa 30s)
- Para corrida/ciclismo: especifique ritmo/pace ou zonas de FC, distância ou tempo
- Distribua as sessões respeitando recuperação (ex: tiro → recuperativo na sessão seguinte)
- NÃO atribua dias da semana específicos — use "Treino 1", "Treino 2", etc. nos labels
- O atleta decide em quais dias treinar — você define apenas a sequência de estímulos

═══ FORMATO DOS EXERCÍCIOS (BLOCOS DA SESSÃO) ═══
Cada bloco em "steps" deve ser um OBJETO com os campos:
- "name": tipo do esforço (obrigatório) — ex: "Crawl base", "Tiro 200m", "Corrida limiar"
- "sets": número de repetições do bloco como inteiro (ex: 10 para "10×200m") — omitir se contínuo
- "load": distância ou tempo do bloco (ex: "200m", "20 min", "5km") — omitir se não aplicável
- "rest": pausa/recuperação entre repetições (ex: "30s", "100m caminhada", "1 min") — omitir se contínuo
- "notes": detalhes técnicos — estilo, ritmo, zona de FC, observações (ex: "FC 65-75%", "borboleta")

Para natação com blocos compostos (ex: 2×(4×50m medley)):
  - Divida em um item por sub-bloco: sets=2 + notes="4×50m: 50B/50C/50P/50L" + rest="1 min entre séries"

Responda EXCLUSIVAMENTE com JSON válido, sem markdown:

{
  "modality": "${modality}",
  "planType": "semanal",
  "title": "Plano Semanal de ${modalityName} — [fase]",
  "overview": "Descrição do plano em 2-3 frases explicando a lógica da semana e as zonas usadas",
  "sessions": [
    {
      "label": "Treino 1 — Base Z2",
      "focus": "Zona metabólica e objetivo fisiológico",
      "description": "Por que esta sessão está aqui e o que desenvolve",
      "durationMinutes": ${durationMinutes},
      "steps": [
        {"name": "Aquecimento", "load": "400m", "notes": "Nado leve, escolha o estilo"},
        {"name": "Crawl base Z2", "sets": 4, "load": "200m", "rest": "30s", "notes": "FC 65-75% — ritmo conversacional"},
        {"name": "Volta à calma", "load": "200m", "notes": "Estilo costas, muito leve"}
      ]
    }
  ],
  "tip": "Dica específica para o perfil deste atleta",
  "hasTapering": ${isCompetition && weeksToCompetition <= 2}
}`;
}

// ─── Cloud Function principal ─────────────────────────────────────────────────

exports.generateTrainingSuggestion = onCall(
  {
    secrets: [claudeApiKey],
    region: "us-central1",
    timeoutSeconds: 90,
    memory: "256MiB",
    cors: true,
  },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Não autenticado.");

    const {
      modality           = "corrida",
      level              = "iniciante",
      goal               = "resistencia",
      age                = 0,
      sessionsCount      = 3,
      daysPerWeek        = sessionsCount,   // Flutter envia sessionsCount
      weeksToCompetition = 0,
      competitionName    = "",
      focus              = "resistencia",
      intensity          = "moderado",
      durationMinutes    = 45,
      freeText           = "",
    } = request.data || {};

    const validModalities = ["corrida", "natacao", "ciclismo", "musculacao"];
    if (!validModalities.includes(modality))
      throw new HttpsError("invalid-argument", "Modalidade inválida.");

    // ── Cooldown por modalidade ───────────────────────────────────────────────
    // Verifica no backend se o usuário gerou um plano desta modalidade
    // nas últimas COOLDOWN_HOURS horas. Impede abuso de tokens mesmo que
    // alguém conclua sessões artificialmente para desbloquear nova geração.
    const uid         = request.auth.uid;
    const cooldownRef = db.collection("generationCooldowns").doc(uid);
    const cooldownDoc = await cooldownRef.get();

    if (cooldownDoc.exists) {
      const lastTs = cooldownDoc.data()[modality];
      if (lastTs) {
        const hoursSince = (Date.now() - lastTs.toDate().getTime()) / 3_600_000;
        if (hoursSince < COOLDOWN_HOURS) {
          const hoursLeft = Math.ceil(COOLDOWN_HOURS - hoursSince);
          throw new HttpsError(
            "resource-exhausted",
            `Aguarde ${hoursLeft}h para gerar um novo plano de ${modality}.`
          );
        }
      }
    }

    // Seleciona o prompt correto baseado na categoria da modalidade
    const isMusculacao = modality === "musculacao";
    const prompt = isMusculacao
      ? buildMusclePrompt({ level, goal, age, daysPerWeek, focus, intensity, freeText })
      : buildEndurancePrompt({
          modality, level, goal, age, daysPerWeek,
          weeksToCompetition, competitionName,
          focus, intensity, freeText, durationMinutes,
        });

    const apiKey = claudeApiKey.value().replace(/^﻿/, "");
    const client = new Anthropic.default({ apiKey });

    let rawText = "";
    try {
      const message = await client.messages.create({
        model:      "claude-sonnet-4-6",
        max_tokens: 8192,
        messages:   [{ role: "user", content: prompt }],
      });
      rawText = message.content[0]?.text || "";
    } catch (err) {
      console.error("[Treinix] Erro Claude API:", err.message);
      throw new HttpsError("internal", "Falha ao chamar a IA.");
    }

    let plan;
    try {
      const clean = rawText.replace(/```json/gi, "").replace(/```/g, "").trim();
      plan = JSON.parse(clean);
    } catch (err) {
      console.error("[Treinix] JSON inválido:", rawText);
      throw new HttpsError("internal", "Resposta em formato inesperado.");
    }

    // Registra timestamp desta geração — reinicia o cooldown da modalidade
    await cooldownRef.set(
      { [modality]: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true }
    );

    // Calcula validade do plano
    const now      = new Date();
    const validDays = isMusculacao ? 30 : 7;
    const validUntil = new Date(now.getTime() + validDays * 24 * 60 * 60 * 1000);

    return {
      modality:           plan.modality        ?? modality,
      planType:           plan.planType        ?? (isMusculacao ? "mensal" : "semanal"),
      title:              plan.title           ?? "Plano de treino",
      overview:           plan.overview        ?? "",
      sessions:           Array.isArray(plan.sessions) ? plan.sessions : [],
      tip:                plan.tip             ?? "",
      hasTapering:        plan.hasTapering     ?? false,
      weeksToCompetition: weeksToCompetition   ?? null,
      validUntil:         validUntil.toISOString(),
    };
  }
);
