# Treinix — Treinador Digital para Atletas Amadores

> Trabalho de Conclusão de Curso (TCC) · Pós-graduação em Desenvolvimento de Aplicativos Móveis  
> Pontifícia Universidade Católica do Paraná – PUC/PR · 2026  
> Autor: **Adelson Fernando Alvarez Oliveira**

---

## Sumário

1. [Sobre o Projeto](#sobre-o-projeto)
2. [Tecnologias Utilizadas](#tecnologias-utilizadas)
3. [Arquitetura](#arquitetura)
4. [Funcionalidades](#funcionalidades)
5. [Telas do Aplicativo](#telas-do-aplicativo)
6. [Estrutura de Pastas](#estrutura-de-pastas)
7. [Configuração e Execução](#configuração-e-execução)
8. [Deploy](#deploy)
9. [Privacidade e LGPD](#privacidade-e-lgpd)
10. [Licença](#licença)

---

## Sobre o Projeto

O **Treinix** é um aplicativo mobile e web desenvolvido como Projeto de Conclusão de Curso da pós-graduação em Desenvolvimento de Aplicativos Móveis da PUC/PR. O objetivo central é oferecer a atletas amadores — praticantes de corrida, natação, ciclismo e musculação — uma ferramenta digital inteligente para organização, personalização e acompanhamento de treinos.

O diferencial do Treinix está na integração com **Inteligência Artificial** (Claude, da Anthropic) para geração de planos de treino personalizados com base no perfil do atleta: modalidade, nível de condicionamento físico, objetivo, intensidade desejada e preferências livres de treino.

### Motivação

Atletas amadores enfrentam duas realidades comuns: a dificuldade de organizar treinos sem orientação profissional e a falta de ferramentas acessíveis que combinem personalização e inteligência. O Treinix busca preencher essa lacuna oferecendo planejamento adaptado sem a necessidade de um treinador presencial.

---

## Tecnologias Utilizadas

| Tecnologia | Função |
|---|---|
| **Flutter 3.x** | Framework multiplataforma (Android + Web) |
| **Dart** | Linguagem de programação |
| **Firebase Authentication** | Autenticação via e-mail/senha e Google |
| **Cloud Firestore** | Banco de dados NoSQL em tempo real |
| **Firebase Cloud Functions** | Backend serverless para chamadas à API de IA |
| **Firebase Hosting** | Hospedagem da versão web |
| **Claude AI (Anthropic)** | Geração de planos de treino com IA |
| **Provider** | Gerenciamento de estado (MVVM) |
| **GoRouter** | Navegação declarativa |
| **Google Fonts** | Tipografia |
| **flutter_native_splash** | Splash screen nativa |
| **flutter_launcher_icons** | Ícones do aplicativo |
| **intl** | Internacionalização e formatação de datas em pt-BR |

---

## Arquitetura

O projeto adota o padrão **MVVM (Model-View-ViewModel)** com separação clara de responsabilidades:

```
lib/
├── core/               # Constantes, temas, configurações globais
├── data/
│   ├── models/         # Modelos de dados (UserModel, TrainingModel…)
│   └── repositories/   # Acesso ao Firestore e Firebase Auth
├── viewmodels/         # Lógica de negócio + estado (Provider)
└── ui/
    ├── auth/           # Telas de autenticação
    ├── home/           # Dashboard principal
    ├── onboarding/     # Fluxo de cadastro inicial
    ├── profile/        # Perfil e privacidade
    ├── settings/       # Configurações
    ├── stats/          # Estatísticas
    ├── suggestion/     # Geração de planos por IA
    ├── training/       # Sessões, histórico e execução de treinos
    ├── misc/           # Glossário, calculadora de pace, sobre
    └── widgets/        # Componentes reutilizáveis
```

### Fluxo de geração de treino com IA

```
App (Flutter)
    │
    ▼
Cloud Function (Node.js)
    │  Recebe perfil do atleta + parâmetros do treino
    │  Monta prompt estruturado
    ▼
Claude API (Anthropic)
    │  Gera plano de treino em JSON
    ▼
Firestore
    │  Plano salvo vinculado ao usuário
    ▼
App (Flutter)
    │  Exibe plano de treino sessão a sessão
```

---

## Funcionalidades

- **Autenticação** — Cadastro e login com e-mail/senha ou conta Google; recuperação de senha por e-mail
- **Onboarding personalizado** — Fluxo de 4 etapas para configurar modalidades, nível, objetivo e idade
- **Dashboard** — Streak semanal, próximo treino por modalidade e últimos treinos registrados
- **Geração de planos por IA** — Plano de treino criado pelo Claude AI com base no perfil e nos parâmetros informados (modalidade, foco, intensidade, duração, número de sessões e diretrizes livres)
- **Execução de treinos** — Player passo a passo com deslize entre blocos; modo musculação com contador de séries, cronômetro de descanso e campo de carga; modo endurance com confirmação de bloco
- **Registro manual de treinos** — Lançamento avulso de treinos por modalidade
- **Histórico de treinos** — Lista cronológica de todos os treinos realizados com detalhes
- **Estatísticas** — Frequência semanal (últimas 8 semanas), distribuição por modalidade e indicadores de consistência
- **Perfil do atleta** — Visualização e edição de dados pessoais, modalidades praticadas e objetivos
- **Calculadora de pace** — Cálculo de pace e tempo de prova para corrida, natação e ciclismo; dois modos: Tempo → Pace e Pace → Tempo
- **Glossário esportivo** — Termos técnicos de corrida, natação, ciclismo e musculação com filtro por modalidade, incluindo zonas de treinamento Z1–Z5
- **Configurações** — Encerramento de sessão, acesso à política de privacidade e informações do app

---

## Telas do Aplicativo

### 1. Splash Screen

**Arquivo:** `lib/main.dart` (flutter_native_splash)

Tela de inicialização nativa exibida durante o carregamento do Firebase e das configurações iniciais. Fundo laranja (#E8593C) com o logo do Treinix centralizado. Implementada com o pacote `flutter_native_splash` para integração com o sistema operacional (Android e iOS), garantindo uma transição suave entre o boot nativo e o primeiro frame Flutter.

> 📸 _[inserir print da splash screen]_

---

### 2. Tela de Login

**Arquivo:** `lib/ui/auth/login_screen.dart`

Primeira tela exibida ao usuário não autenticado. Apresenta o logo do Treinix com gradiente laranja na parte superior, campos de e-mail e senha, botão de acesso com Google (OAuth), link para cadastro e opção de recuperação de senha. O gradiente laranja reforça a identidade visual da marca desde o primeiro contato.

**Elementos:**
- Logo + gradiente laranja (identidade visual)
- Campo de e-mail
- Campo de senha (com toggle de visibilidade)
- Botão "Entrar"
- Botão "Entrar com Google"
- Link "Esqueci minha senha"
- Link "Criar conta"

> 📸 _[inserir print da tela de login]_

---

### 3. Tela de Cadastro

**Arquivo:** `lib/ui/auth/register_screen.dart`

Formulário de criação de conta com campos de nome, e-mail, senha e confirmação de senha. Mesmo padrão visual da tela de login (gradiente laranja + logo) para consistência na experiência de autenticação. Após o cadastro bem-sucedido, o usuário é direcionado ao onboarding.

**Elementos:**
- Logo + gradiente laranja
- Campo de nome
- Campo de e-mail
- Campo de senha
- Campo de confirmação de senha
- Botão "Criar conta"
- Link "Já tenho conta"

> 📸 _[inserir print da tela de cadastro]_

---

### 4. Recuperação de Senha

**Arquivo:** `lib/ui/auth/reset_password_screen.dart`

Permite que usuários cadastrados com e-mail e senha redefinam o acesso em caso de esquecimento. O usuário informa o e-mail cadastrado e recebe um link de redefinição via Firebase Authentication. Após o envio, uma tela de confirmação exibe uma mensagem de sucesso com ícone visual.

**Elementos:**
- Campo de e-mail
- Botão "Enviar link"
- Tela de confirmação com ícone de sucesso
- Botão "Voltar ao login"

> 📸 _[inserir print da tela de recuperação de senha]_

---

### 5. Onboarding — Configuração Inicial

**Arquivo:** `lib/ui/onboarding/onboarding_screen.dart`

Fluxo exibido uma única vez após o primeiro cadastro. Composto por 4 etapas com navegação por `PageView`:

- **Etapa 1 — Modalidades:** Seleção das modalidades praticadas (Corrida, Natação, Ciclismo, Musculação). Múltipla escolha com chips animados.
- **Etapa 2 — Nível:** Iniciante, Intermediário ou Avançado.
- **Etapa 3 — Objetivo:** Resistência, Emagrecimento, Performance ou Saúde.
- **Etapa 4 — Idade:** Campo numérico opcional para personalização dos planos.

Os dados são salvos no Firestore e utilizados como contexto na geração dos planos de treino por IA.

> 📸 _[inserir prints das 4 etapas do onboarding]_

---

### 6. Home / Dashboard

**Arquivo:** `lib/ui/home/home_screen.dart`

Tela principal do aplicativo. Exibe um resumo completo da semana do atleta em tempo real, consultando o Firestore a cada acesso.

**Seções:**
- **Streak semanal** — Contador de semanas consecutivas com pelo menos um treino registrado
- **Próximo treino** — Card com o próximo treino agendado por modalidade (modalidade, tipo de sessão, duração estimada)
- **Últimos treinos** — Lista dos treinos mais recentes com data, modalidade e duração

> 📸 _[inserir print da tela home]_

---

### 7. Geração de Plano por IA

**Arquivo:** `lib/ui/suggestion/suggestion_screen.dart`

Tela central do diferencial do Treinix. O usuário configura os parâmetros do plano e a IA (Claude) gera um plano estruturado com múltiplas sessões de treino.

**Parâmetros configuráveis:**
- Modalidade (Corrida, Natação, Ciclismo, Musculação)
- Foco do treino (Resistência, Força, Velocidade, Técnica, Recuperação)
- Intensidade desejada (Leve, Moderado, Intenso)
- Duração da sessão (em minutos)
- Número de sessões no plano
- Diretrizes livres (campo de texto aberto para instruções específicas)

Após a geração, o plano ativo é exibido com progresso (ex.: "Sessão 2 de 4"), rotação automática de sessões A→B→C→D ao concluir cada treino e animação de personagem com a modalidade escolhida.

> 📸 _[inserir print da tela de configuração + print do plano gerado]_

---

### 8. Sessão de Treino

**Arquivo:** `lib/ui/training/training_session_screen.dart`

Exibe os detalhes da próxima sessão do plano ativo. O usuário pode visualizar o treino completo ou iniciar a execução guiada. Ao concluir, o progresso do plano é atualizado automaticamente no Firestore e a rotação de sessões avança.

**Elementos:**
- Nome e descrição da sessão
- Lista de blocos/exercícios
- Botão "Iniciar treino" → direciona para o player de execução
- Botão "Concluí o treino" → registra no histórico

> 📸 _[inserir print da tela de sessão de treino]_

---

### 9. Execução de Treino (Workout Player)

**Arquivo:** `lib/ui/training/workout_execution_screen.dart`

Player passo a passo para execução guiada do treino. O atleta desliza entre os blocos/exercícios do plano.

**Modo Musculação:**
- Contador de séries (ex.: "Série 2 de 4")
- Cronômetro de descanso entre séries
- Campo para registro de carga utilizada

**Modo Endurance (Corrida, Natação, Ciclismo):**
- Descrição de cada bloco (aquecimento, principal, descanso, volta à calma)
- Confirmação manual de conclusão por bloco

> 📸 _[inserir print do workout player — modo musculação e modo endurance]_

---

### 10. Detalhes do Plano de Treino

**Arquivo:** `lib/ui/training/plan_detail_screen.dart`

Visão expandida de um plano de treino completo. Lista todas as sessões geradas pela IA com seus respectivos blocos, exercícios e descrições. Útil para revisão prévia de todo o plano antes de iniciar.

> 📸 _[inserir print dos detalhes do plano]_

---

### 11. Registro Manual de Treino

**Arquivo:** `lib/ui/training/log_training_screen.dart`

Permite o lançamento manual de um treino avulso, sem necessidade de plano gerado por IA. O usuário informa modalidade, duração e observações. O registro é salvo no histórico do Firestore.

**Elementos:**
- Seleção de modalidade (chips)
- Campo de duração (em minutos)
- Campo de observações
- Botão "Registrar treino"

> 📸 _[inserir print da tela de registro manual]_

---

### 12. Histórico de Treinos

**Arquivo:** `lib/ui/training/training_history_screen.dart`

Lista cronológica de todos os treinos realizados pelo atleta — sejam planos concluídos ou registros manuais. Cada item exibe modalidade, data, duração e tipo de treino.

> 📸 _[inserir print do histórico de treinos]_

---

### 13. Log Detalhado de Treino

**Arquivo:** `lib/ui/training/history_log_screen.dart`

Detalhe de um treino específico do histórico. Exibe todas as informações registradas: data, duração, modalidade, blocos executados e observações.

> 📸 _[inserir print do log detalhado]_

---

### 14. Estatísticas

**Arquivo:** `lib/ui/stats/stats_screen.dart`

Dashboard de acompanhamento de progresso com visualizações gráficas baseadas no histórico do atleta.

**Indicadores:**
- **Frequência semanal** — Gráfico de barras com as últimas 8 semanas de treino
- **Distribuição por modalidade** — Percentual de treinos por modalidade praticada
- **Consistência** — Indicador de semanas ativas com streak de semanas consecutivas

> 📸 _[inserir print da tela de estatísticas]_

---

### 15. Perfil do Atleta

**Arquivo:** `lib/ui/profile/profile_screen.dart`

Tela de perfil do usuário com visualização e edição dos dados cadastrais e informações esportivas.

**Informações exibidas:**
- Nome e e-mail
- Total de treinos registrados e semanas ativas
- Modalidades praticadas
- Nível de condicionamento
- Objetivo esportivo

> 📸 _[inserir print da tela de perfil]_

---

### 16. Configurações

**Arquivo:** `lib/ui/settings/settings_screen.dart`

Central de configurações do aplicativo.

**Opções disponíveis:**
- Política de privacidade
- Sobre o Treinix
- Encerrar sessão (com confirmação por diálogo)

> 📸 _[inserir print das configurações]_

---

### 17. Calculadora de Pace

**Arquivo:** `lib/ui/misc/pace_calculator_screen.dart`

Ferramenta utilitária para atletas de corrida, natação e ciclismo calcularem pace e tempo de prova.

**Dois modos de cálculo:**
- **Tempo → Pace:** informa distância e tempo total, obtém o pace por km/m
- **Pace → Tempo:** informa distância e pace, obtém o tempo total estimado

**Modalidades suportadas:**
- Corrida (km/h e min/km)
- Natação (metros e min/100m)
- Ciclismo (km/h e min/km)

> 📸 _[inserir print da calculadora de pace]_

---

### 18. Glossário Esportivo

**Arquivo:** `lib/ui/misc/glossary_screen.dart`

Dicionário de termos técnicos do esporte com filtro por modalidade. Útil para atletas iniciantes compreenderem a terminologia utilizada nos planos de treino gerados pela IA.

**Modalidades cobertas:**
- Corrida
- Natação (incluindo Zonas Z1 a Z5)
- Ciclismo
- Musculação

> 📸 _[inserir print do glossário]_

---

### 19. Sobre o Treinix

**Arquivo:** `lib/ui/misc/about_screen.dart`

Tela informativa com o propósito do aplicativo, contexto acadêmico, tecnologias utilizadas, funcionalidades oferecidas e link para a política de privacidade.

**Seções:**
- Identidade visual (logo + nome + versão)
- Propósito do app
- Contexto acadêmico (TCC, curso, instituição, autor, ano)
- Tecnologias utilizadas
- O que o Treinix oferece
- Privacidade e LGPD

> 📸 _[inserir print da tela sobre]_

---

### 20. Política de Privacidade

**Arquivo:** `lib/ui/profile/privacy_screen.dart`

Documento completo de política de privacidade em conformidade com a **Lei Geral de Proteção de Dados (LGPD — Lei 13.709/2018)**. Detalha quais dados são coletados, como são utilizados, por quanto tempo são armazenados e os direitos do titular.

> 📸 _[inserir print da política de privacidade]_

---

## Estrutura de Pastas

```
treinix/
├── android/                    # Projeto Android nativo
│   └── app/src/main/res/       # Ícones adaptivos por densidade
├── assets/
│   ├── images/                 # Logo e imagens do app
│   └── icons/                  # Ícones SVG
├── functions/                  # Firebase Cloud Functions (Node.js)
│   └── index.js                # Função generateTrainingSuggestion
├── lib/
│   ├── core/
│   │   ├── constants/          # AppColors, AppTextStyles, AppStrings
│   │   └── routes/             # GoRouter — app_router.dart
│   ├── data/
│   │   ├── models/             # UserModel, TrainingModel, TrainingPlanModel…
│   │   └── repositories/       # AuthRepository, PlanRepository, TrainingRepository
│   ├── viewmodels/             # AuthViewModel, HomeViewModel, TrainingViewModel…
│   └── ui/                     # Telas e widgets (ver seção Telas)
├── web/                        # Build web (Flutter Web)
│   ├── icons/                  # Ícones PWA
│   └── manifest.json           # Manifesto PWA
├── pubspec.yaml                # Dependências e configuração Flutter
└── firebase.json               # Configuração do Firebase CLI
```

---

## Configuração e Execução

### Pré-requisitos

- Flutter SDK `>=3.2.0`
- Dart SDK (incluído no Flutter)
- Node.js `>=18` (para Cloud Functions)
- Firebase CLI (`npm install -g firebase-tools`)
- Conta Google com projeto Firebase configurado

### Variáveis de ambiente (Cloud Functions)

A chave da API do Claude é armazenada como **Firebase Secret** (Google Secret Manager):

```bash
firebase functions:secrets:set CLAUDE_API_KEY
```

### Instalação

```bash
# Clone o repositório
git clone <url-do-repositorio>
cd treinix

# Instale as dependências Flutter
flutter pub get

# Instale as dependências das Cloud Functions
cd functions && npm install && cd ..
```

### Execução local

```bash
# Android (dispositivo ou emulador conectado)
flutter run

# Web
flutter run -d chrome
```

### Regenerar splash screen e ícones

```bash
# Splash screen nativa
dart run flutter_native_splash:create

# Ícones do app
dart run flutter_launcher_icons
```

---

## Deploy

### Web (Firebase Hosting)

```bash
flutter build web --release
firebase deploy --only hosting
```

### Cloud Functions

```bash
firebase deploy --only functions
```

### Deploy completo

```bash
flutter build web --release
firebase deploy
```

---

## Privacidade e LGPD

O Treinix foi desenvolvido em conformidade com a **Lei Geral de Proteção de Dados (LGPD — Lei 13.709/2018)**. Os dados coletados são utilizados exclusivamente para personalizar a experiência de treino do usuário. O armazenamento é realizado no Google Firebase (infraestrutura com certificações de segurança SOC 2 e ISO 27001).

O usuário tem controle total sobre seus dados diretamente pelo aplicativo:
- **Exclusão de perfil** — pode excluir sua conta e todos os dados associados a qualquer momento
- **Exportação de dados** — pode exportar seu perfil e histórico de treinos a qualquer momento

A política de privacidade completa está disponível dentro do próprio aplicativo em **Configurações → Política de privacidade**.

---

## Licença

Este projeto foi desenvolvido exclusivamente para fins acadêmicos como Trabalho de Conclusão de Curso da Pós-graduação em Desenvolvimento de Aplicativos Móveis da PUC/PR. Todos os direitos reservados ao autor.

---

> Desenvolvido por **Adelson Fernando Alvarez Oliveira** · PUC/PR · 2026
