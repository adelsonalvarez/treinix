// =============================================================================
// Projeto    : Treinix – Treinador Digital para Atletas Amadores
// Arquivo    : lib/core/constants/app_strings.dart
// Camada     : Constantes – Textos
// Descrição  : Centralização dos textos da interface (base para i18n futuro)
// -----------------------------------------------------------------------------
// Autor      : Adelson Fernando Alvarez Oliveira
// Instituição: Pontifícia Universidade Católica do Paraná – PUC/PR
// Curso      : Pós-graduação em Desenvolvimento de Aplicativos Móveis
// Ano        : 2026
// =============================================================================

class AppStrings {
  AppStrings._();

  static const appName = 'Treinix';
  static const tagline = 'Seu treinador digital';

  // Auth
  static const login = 'Entrar';
  static const register = 'Criar conta';
  static const email = 'E-mail';
  static const password = 'Senha';
  static const forgotPassword = 'Esqueci minha senha';
  static const logout = 'Sair';

  // Onboarding
  static const onboardingTitle = 'Vamos montar seu perfil';
  static const onboardingSub = 'Responda algumas perguntas para receber treinos personalizados';
  static const chooseModality = 'Qual modalidade você pratica?';
  static const chooseLevel = 'Qual é seu nível atual?';
  static const chooseDays = 'Quantos dias por semana você pode treinar?';
  static const chooseGoal = 'Qual é seu objetivo principal?';

  // Modalidades
  static const corrida = 'Corrida';
  static const natacao = 'Natação';
  static const ciclismo = 'Ciclismo';
  static const musculacao = 'Musculação';

  // Níveis
  static const iniciante = 'Iniciante';
  static const intermediario = 'Intermediário';
  static const avancado = 'Avançado';

  // Objetivos
  static const resistencia = 'Resistência';
  static const velocidade = 'Velocidade';
  static const forca = 'Força';
  static const emagrecimento = 'Emagrecimento';

  // Home
  static const treinoDoDia = 'Treino do dia';
  static const sugestaoIA = 'Sugestão da IA';
  static const gerarSugestao = 'Gerar sugestão de treino';
  static const registrarTreino = 'Registrar treino';
  static const historicoTreinos = 'Histórico';

  // Erros
  static const errorGeneric = 'Algo deu errado. Tente novamente.';
  static const errorNetwork = 'Verifique sua conexão com a internet.';
  static const errorAuth = 'E-mail ou senha incorretos.';
  static const errorRequired = 'Campo obrigatório.';
}