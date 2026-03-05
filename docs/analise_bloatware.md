# Documentação Completa e Analítica de Bloatwares (Windows 11)

Esta lista contém TODOS os aplicativos embutidos na ISO do Windows 11 (AppX Packages) que o Tiny11Builder possui a capacidade de remover, sem causar dados irrecuperáveis ao núcleo do sistema. 

Ao lado de cada um, há uma descrição exata de sua função técnica para auxiliar o usuário final a decidir se vale a pena **manter** ou **remover** durante a criação da sua ISO customizada.

## 1. Jogos e Xbox (Games & Xbox)
*Geralmente seguros de remover, a menos que o PC seja destinado intensamente para jogar os jogos pelo aplicativo da Xbox Store.*
- `Microsoft.GamingApp` : Aplicativo Xbox principal para PC (Pode ser baixado depois).
- `Microsoft.MicrosoftSolitaireCollection` : Paciência e jogos de cartas clássicos pré-instalados.
- `Microsoft.Xbox.TCUI` : Painel de interface de interface da comunidade Xbox Live.
- `Microsoft.XboxApp` : Aplicativo complementar clássico e Cloud Gaming Xbox.
- `Microsoft.XboxGameOverlay` : A barra de jogos original (Win+G) para gravar a tela.
- `Microsoft.XboxGamingOverlay` : Extensão subjacente da barra de jogo (Widgets).
- `Microsoft.XboxIdentityProvider` : Sistema silencioso responsável pelo Login na Xbox Live.
- `Microsoft.XboxSpeechToTextOverlay` : Sistema de transcrição em voice-chat nos grupos (Parties) Xbox.
- `Microsoft.Edge.GameAssist` : Barra superior de navegação para jogos acionada pela engine do Edge.

## 2. Aplicativos de Mídia e Criação (Media & Creativity)
*Muitos preferem removedores de PDF ou reprodutores como o VLC, mas ferramentas básicas podem faltar.*
- `Clipchamp.Clipchamp` : Editor de vídeo super-básico e pesado, baseado na nuvem.
- `Microsoft.Microsoft3DViewer` : Exibidor de malhas e modelos 3D que quase ninguém usa no Explorer.
- `Microsoft.MixedReality.Portal` : Portal oficial para óculos e sistemas de Realidade Mista (VR) da Microsoft.
- `Microsoft.MSPaint` : Núcleo do motor antigo do clássico Paint.
- `Microsoft.Paint` : Interface da nova versão UWP do Paint com camadas.
- `Microsoft.ZuneMusic` (Groove) : Último resquício do finado Groove Música (player offline de áudio).
- `Microsoft.ZuneVideo` (Filmes e TV) : O reprodutor de vídeo Offline nativo padrão.  
- `Microsoft.WindowsSoundRecorder` : Gravador Padrão de Voz embutido.
- `Microsoft.WindowsCamera` : Permite testar/fotografar usando sua Webcam.
- `Microsoft.Windows.Photos` : **Atenção** - Visualizador nativo de fotos. Remove a abertura de duplo clique em .JPG e .PNG até que você instale outro visualizador.

## 3. Notícias, Clima e Serviços Web (News & Services)
*Excelente candidato a remoção. São essencialmente "favoritos web" vestidos como aplicativos gulosos.*
- `Microsoft.BingNews` : Abre um painel puxando feeds massivos de mídias globais (MSN).
- `Microsoft.BingSearch` : Plugin do menu iniciar responsável por forçar empurrar resultados da Web (Bing) quando você busca algo local.
- `Microsoft.BingWeather` : Fornece as informações climáticas ao widget da barra de tarefas.
- `Microsoft.StartExperiencesApp` : Wrapper sub-liminar no sistema alimentando o painel de widgets do MSN.
- `Microsoft.WindowsFeedbackHub` : Permite buscar/enviar logs de problemas a MS (Telemetria).
- `Microsoft.GetHelp` : Robô do "Obter Ajuda" que sempre manda abrir um artigo online para troubleshoots básicos.
- `Microsoft.Getstarted` : Janelas pop-up de dica "Dê uma olhada no que há de novo no W11".
- `Microsoft.WindowsMaps` : Cliente rudimentar inativo do Bing Mapas embutido no SO.

## 4. Comunicação e E-mail (Comms)
*Remova caso não precise da integração total; o cliente Web pelo navegador geramente supre a mesma funcionalidade.*
- `Microsoft.SkypeApp` : Resquício do cliente moderno do Skype, ainda enviado com certas compilações.
- `Microsoft.Windows.Teams` : O botão de Chat padronizado na Taskbar com interface Teams "pessoal".
- `MSTeams` / `MicrosoftTeams` : O próprio programa UWP massivo do Microsoft Teams.
- `Microsoft.OutlookForWindows` : Novo Outlook de navegador pesado que recém substituiu o clássico.
- `microsoft.windowscommunicationsapps` : Aplicativos puros nativos antigos (Correio / Calendário).
- `Microsoft.People` : Gerenciador invisível de agenda de contatos embutida (Contatos).
- `Microsoft.YourPhone` : Conector nativo de celular ("Phone Link"), compartilha tela e ligações.
- `Microsoft.Windows.CrossDevice` : Componente de compartilhamento de área de transferência cloud do Windows.

## 5. Produtividade Menor (Productivity)
*Recomenda-se tratar esta categoria com cuidado, já que abriga ferramentas historicamente vitais.*
- `Microsoft.Todos` : Substituiu a cortana como lidador de tarefas tipo checklist (Microsoft To-Do).
- `Microsoft.MicrosoftStickyNotes` : As notas auto-adesivas coloridas na área de trabalho.
- `Microsoft.Office.OneNote` : Aplicativo restrito OneNote na Store (não é o Microsoft 365 Pro).
- `Microsoft.OfficePushNotificationUtility` : Serviço de segundo plano caçando notificações de e-mails em silêncio.
- `Microsoft.MicrosoftOfficeHub` : Painel central embutido promovendo a assinatura do M365 (O App laranja do Office).
- `Microsoft.PowerAutomateDesktop` : Motor de scripts e fluxos automáticos complexos em background.
- `Microsoft.WindowsAlarms` : Despertador universal, relógio cronômetro focado da MS.
- `Microsoft.WindowsCalculator` : **Atenção** - É a própria Calculadora embutida clássica do Win11.

## 6. Lixo Patrocinado de Terceiros e OEM (Ads/Bloatware)
*Remoção Altamente Recomendada (Bloatware puro injetado na Imagem, varia por edição/região).*
- `King.Com.CandyCrushSaga` e Variantes : Links patrocinados disfarçados de pré-instalação no Menu Iniciar.
- `Netflix` : Falso ícone da Netflix patrocinado pronto pra baixar o executável da loja.
- `SpotifyAB.Spotify` : Mesma dinâmica que a Netflix.
- `DolbyLaboratories.DolbyAccess` / `DolbyDigitalPlusDecoder` : Componentes sonoros de licença paga OEM pre-adicionados visando compra na store.
- `AppUp.IntelManagementandSecurityStatus` : Utente passivo da Intel abandonado, consumindo resíduo ativo.
- `Microsoft.Wallet` : Hub central focado em amarrar seu PC e dados a uma Microsoft Account pagante via Microsoft Pay.
- `MicrosoftCorporationII.MicrosoftFamily` : Limitador rígido de proteção online para adolescentes do "MS Family".

## 7. Desenvolvimento Avançado e Ferramentas Complexas (Dev Tools & AI)
*Serviços técnicos úteis apenas para administradores, DevOps ou usuários de Inteligência Artificial.*
- `Microsoft.Windows.DevHome` : Hub "Dev Home" pesado introduzindo suporte profundo a GitHub em tela cheia.
- `Microsoft.WindowsTerminal` : O Novo "Bash" colorido e em abas do Windows (O CMD e PowerShell legados azuis velhos *não* saem, então é seguro remover se você curte os velhos).
- `MicrosoftCorporationII.QuickAssist` : "Assistência Rápida" usada para dar permissão remota a algum técnico consertar seu computador.
- `Microsoft.549981C3F5F10` : A velha casca obsoleto da finada Cortana UWP ainda enterrada na ISO instalando silenciosamente.
- `Microsoft.Copilot` / `Microsoft.Windows.Copilot` : O novo assistente nativo de Inteligência Artificial Generativo (Integrações com Bing GPT).
