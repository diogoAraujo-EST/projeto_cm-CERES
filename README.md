# 🌿 CERES - A rega certa, na altura certa.

A **CERES** é uma aplicação mobile interativa e robusta, desenvolvida em **Flutter**, com o objetivo de auxiliar os utilizadores a manterem as suas plantas saudáveis. Inspirada na mitologia romana (Ceres, a deusa das plantas e protetora das colheitas), a aplicação combina tecnologia, automação e bem-estar num formato acessível e intuitivo.

**Projeto Prático - Computação Móvel (2025/2026)**
Licenciatura em Engenharia Informática - Escola Superior de Tecnologia de Setúbal (IPS)


## 🌟 Funcionalidades Principais e Inovação


A CERES vai muito além de um simples bloco de notas (CRUD), assumindo-se como um assistente botânico proativo:

*   📱 **Dashboard Inteligente:** Divide automaticamente as plantas em "Tarefas para Hoje" (urgentes) e "Próximas Regas", incluindo um banner meteorológico que reage ao clima atual em tempo real.
*   🪴 **Gestão Botânica Completa:** Permite adicionar plantas associando-as a divisões específicas da casa, tirar fotografias com a câmara do telemóvel e registar regas com um clique.
*   📅 **Calendário Customizado (Nativo):** Motor de grelha de datas programado de raiz (sem bibliotecas de terceiros) que calcula e projeta visualmente os dias futuros de rega.
*   📊 **Motor de Estatísticas:** Processa o histórico de regas para gerar gráficos dinâmicos, identificar a planta "mais regada" e calcular a "Consistência de Rega" do utilizador.
*   🧠 **Inovação - Algoritmo de Ajuste Dinâmico:** A aplicação cruza a informação da biologia ideal da planta (via API) com a exposição solar real e localização da divisão da casa, recalculando e ajustando automaticamente os dias da próxima rega.



## 🏗️ Arquitetura e Estruturação de Código

O projeto foi estruturado seguindo o princípio de **Separação de Responsabilidades (Clean Architecture)**, resultando num código modular, escalável e livre de bugs:

*   📂 **Models (`/models`):** Estruturas de dados com *Strong Typing* (`plant_species`, `room`, `user_plant`).
*   ⚙️ **Services (`/services`):** Lógica de negócio isolada. Inclui `firestore_service` (para Streams real-time e CRUD), `auth_service` (gestão de identidade), `weather_service` e `plant_api_service`.
*   🖥️ **Screens (`/screens`):** Interface visual isolada, focada em UX. A navegação é gerida centralmente pelo `main_nav_screen` utilizando a `StatefulShellRoute` do **GoRouter** para persistir o estado das tabs inferiores.
*   🎨 **Constants (`/constants`):** Design System centralizado (`CERESColors`).



## ⚡ Desempenho e Qualidade de Código

A aplicação foi rigorosamente otimizada para garantir alta performance e resiliência:

*   **Otimização de Memória:** Uso extensivo de `ListView.builder` para renderização *Lazy* de listas e modificadores `const` para poupar a CPU no redesenho de *frames*.
*   **Debouncing em Pesquisas:** Implementação de temporizadores (400ms) no consumo da API Botânica para evitar sobrecarga de pedidos HTTP durante a digitação.
*   **Compressão de Imagens:** Fotografias otimizadas na fonte (`imageQuality: 70`, `maxWidth: 800`) antes do upload para o Firebase Storage.
*   **Resiliência (Crash-Free):** Proteção global com verificações `if (!mounted)` após chamadas assíncronas para evitar *crashes* durante transições de ecrã, e encapsulamento em blocos `try/catch` para interrupções de GPS ou Internet.
*   **UI/UX Suave:** Uso de transições por gavetas dinâmicas (*Bottom Sheets*), *Empty States* positivos quando não existem dados, e *Feedback Visual* (Spinners) durante latências de rede.


## ✅ Cumprimento de Requisitos Mínimos

A aplicação cumpre integralmente os requisitos da unidade curricular:

- [x] **Autenticação:** Integração com Firebase Auth suportando Registo/Login por Email, OAuth (Google Sign-In) e Modo Convidado (Anonymous).
- [x] **Sistema de Notificações:** Alertas locais nativos integrados via `flutter_local_notifications`.
- [x] **Integração Múltipla de APIs Externas:** 
  - *Open-Meteo API:* Cruzada de forma híbrida com o Hardware de localização (GPS via `geolocator`).
  - *GitHub Gist REST API:* Para o catálogo JSON botânico.
- [x] **Base de Dados Remota:** Integração profunda com `Firebase Cloud Firestore` (NoSQL em tempo real via Streams) e `Firebase Cloud Storage` (Imagens).


## 🛠️ Como Executar e Testar o Projeto

Para testar o código fonte na sua máquina local, certifique-se de que tem o Flutter SDK instalado e siga estes passos:

1. Clone o repositório:
   ```bash
   git clone https://github.com/diogoAraujo-EST/projeto_cm-CERES
   ```
2. Entre na pasta do projeto:
   ```bash
   cd projeto_cm
   ```
3. Instale as dependências:
   ```bash
   flutter pub get
   ```
4. Execute a aplicação (num emulador ou dispositivo físico):
   ```bash
   flutter run
   ```

##### ⚠️ **Nota de Segurança (Google Sign-In):** 
O sistema de segurança da Google exige que a chave `SHA-1` da máquina que compila o código esteja registada na consola do Firebase. Caso corra a aplicação a partir de uma máquina não registada na nossa consola (ex: PC do professor), o método *Google Sign-In* será bloqueado por segurança.

##### 🔒 **Nota de Segurança (Repositório Privado):**
Por questões de cibersegurança e de forma a evitar a exposição não intencional de credenciais na nuvem, o repositório deste projeto foi configurado como **Privado**. O código-fonte integra o ficheiro `google-services.json`, o qual contém as chaves e os identificadores que ligam a aplicação local diretamente à infraestrutura *Premium* (Plano Blaze) da nossa base de dados Firebase. 

De forma a garantir a compilação fluida do projeto na máquina de avaliação (evitando a necessidade de injeção manual de variáveis de ambiente por parte do corpo docente), as credenciais foram mantidas no código-fonte seguro. O acesso ao repositório para consulta e download do projeto é feito em regime de acesso concedido (como *Collaborator*).


## 👨‍💻 Equipa de Desenvolvimento

*   **Diogo Araújo** - Nº 2024149587
*   **Gonçalo França** - Nº 2024118775
*   **Jaime Rosado** - Nº 2024149620

*(Orientação: Prof. Paula Miranda & Prof. David Sanguinetti)*
