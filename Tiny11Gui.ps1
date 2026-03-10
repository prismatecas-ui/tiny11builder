<#
.SYNOPSIS
    Interface gráfica para o Tiny11Builder.
.DESCRIPTION
    Fornece uma GUI nativa em WPF elegante e responsiva para rodar scripts do Tiny11 (DISM) de forma limpa, permitindo seleção granular de bloatwares e idiomas dinâmicos.
#>
# Requires -RunAsAdministrator
[CmdletBinding()]
param()

# Auto-Elevação (Garante que o script rode como Administrador)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ==========================================
# 0. Sistema de Localização (i18n)
# ==========================================
$SysLang = [System.Globalization.CultureInfo]::CurrentUICulture.Name
$IsPT = $SysLang -match '^pt'

$Strings = @{
    WindowTitle      = if ($IsPT) { "Tiny11 GUI" } else { "Tiny11 GUI" }
    Subtitle         = if ($IsPT) { "Construa uma ISO do Windows 11 leve, rápida e sob medida." } else { "Build a lightweight, fast, custom Windows 11 ISO." }
    SourceDrive      = if ($IsPT) { "Drive de Origem:" } else { "Source Drive:" }
    VersionIndex     = if ($IsPT) { "Versão:" } else { "Version:" }
    Categories       = if ($IsPT) { "Categorias" } else { "Categories" }
    SysSettings      = if ($IsPT) { "Configurações Globais" } else { "Global Settings" }
    OptBypass        = if ($IsPT) { "Bypass Requisitos CPU/RAM/TPM" } else { "Bypass CPU/RAM/TPM Requirements" }
    OptTelemetry     = if ($IsPT) { "Desabilitar Telemetria MS" } else { "Disable MS Telemetry" }
    OptLocalAccount  = if ($IsPT) { "Forçar Conta Local (OOBE Offline)" } else { "Force Local Account (OOBE Offline)" }
    BtnAppCustom     = if ($IsPT) { "Personalização de Apps" } else { "App Customization" }
    ConsoleTitle     = if ($IsPT) { "Console de Processamento:" } else { "Processing Console:" }
    BtnClear         = if ($IsPT) { "LIMPAR CONSOLE" } else { "CLEAR CONSOLE" }
    BtnExit          = if ($IsPT) { "SAIR" } else { "EXIT" }
    BtnStart         = if ($IsPT) { "Otimizar ISO" } else { "Optimize ISO" }
    AdvTitle         = if ($IsPT) { "Controle de Apps" } else { "App Control" }
    AdvHint          = if ($IsPT) { "Desmarque os apps que deseja manter (Marcado = Remover)" } else { "Uncheck apps you want to keep (Checked = Remove)" }
    AdvBtnSave       = if ($IsPT) { "SALVAR E RETORNAR" } else { "SAVE AND RETURN" }
    AdvCategory      = if ($IsPT) { "Categoria:" } else { "Category:" }
    MsgGuiInit       = if ($IsPT) { "[INFO] GUI Inicializada." } else { "[INFO] GUI Initialized." }
    MsgNoDrive       = if ($IsPT) { "[ERRO] Selecione um Drive." } else { "[ERROR] Select a Drive." }
    MsgSuccess       = if ($IsPT) { "[OK] Processo Concluído com Sucesso." } else { "[OK] Process Completed Successfully." }
    MsgStarted       = if ($IsPT) { "[SUCESSO] Processo iniciado no console." } else { "[SUCCESS] Process running in console." }
    MsgNoImage       = if ($IsPT) { "[!] Imagem WIM/ESD não encontrada." } else { "[!] WIM/ESD image not found." }
    CbUnknown        = if ($IsPT) { "Desconhecido" } else { "Unknown" }
    CbDefault        = if ($IsPT) { "Padrão" } else { "Default" }
    BackendScript    = if ($IsPT) { "Script Base:" } else { "Build Script:" }
    CatAds           = if ($IsPT) { "Anúncios" } else { "Ads" }
    CatComms         = if ($IsPT) { "Comunicação" } else { "Comms" }
    CatDev           = if ($IsPT) { "Desenvolvimento" } else { "Dev" }
    CatGames         = if ($IsPT) { "Jogos" } else { "Games" }
    CatMedia         = if ($IsPT) { "Mídia" } else { "Media" }
    CatNews          = if ($IsPT) { "Notícias" } else { "News" }
    CatProd          = if ($IsPT) { "Produtividade" } else { "Prod" }
    CatSys           = if ($IsPT) { "Sistema" } else { "Sys" }
    
    AdvCoremakerOnly = if ($IsPT) { "Avançado" } else { "Advanced" }
    AdvCoremakerTip  = if ($IsPT) { "Opções exclusivas do Coremaker. Utilize apenas para testes e desenvolvimento." } else { "Coremaker exclusive options. Use only for testing and development." }
    OptDefender      = if ($IsPT) { "Remover Windows Defender" } else { "Remove Windows Defender" }
    OptWinUpdate     = if ($IsPT) { "Desativar Windows Update" } else { "Disable Windows Update" }
    OptWinRE         = if ($IsPT) { "Remover Windows Recovery (WinRE)" } else { "Remove Windows Recovery (WinRE)" }
    OptSysExtras     = if ($IsPT) { "Remover Pacotes Extras (WordPad, etc)" } else { "Remove Extra Packages (WordPad, etc)" }
}

function Get-AppName {
    param([string]$PtName, [string]$EnName)
    if ($IsPT) { return $PtName } else { return $EnName }
}

# ==========================================
# 0.1 Base de Dados Viva (Global)
# ==========================================
$Global:AppPackages = @(
    # Games
    [PSCustomObject]@{ Id = 'Microsoft.GamingApp'; Desc = Get-AppName 'Aplicativo Xbox' 'Xbox App'; Cat = 'Games'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.MicrosoftSolitaireCollection'; Desc = Get-AppName 'Paciência (Solitaire)' 'Solitaire Collection'; Cat = 'Games'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.Xbox.TCUI'; Desc = Get-AppName 'Interface da Xbox Live' 'Xbox Live UI'; Cat = 'Games'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.XboxApp'; Desc = Get-AppName 'App Xbox Classico' 'Xbox App (Classic)'; Cat = 'Games'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.XboxGameOverlay'; Desc = Get-AppName 'Barra de Jogo do Xbox' 'Xbox Game Bar'; Cat = 'Games'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.XboxGamingOverlay'; Desc = Get-AppName 'Extensão da Barra de Jogos' 'Xbox Game Bar Extension'; Cat = 'Games'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.XboxIdentityProvider'; Desc = Get-AppName 'Sistema de Login do Xbox' 'Xbox Login System'; Cat = 'Games'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.XboxSpeechToTextOverlay'; Desc = Get-AppName 'Conversor de Fala do Xbox' 'Xbox Speech-to-Text'; Cat = 'Games'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.Edge.GameAssist'; Desc = Get-AppName 'Assistente de Jogos do Navegador Edge' 'Edge Game Assist'; Cat = 'Games'; Remove = $true }

    # Media
    [PSCustomObject]@{ Id = 'Clipchamp.Clipchamp'; Desc = Get-AppName 'Editor de Vídeos Clipchamp' 'Clipchamp Video Editor'; Cat = 'Media'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.Microsoft3DViewer'; Desc = Get-AppName 'Visualizador de Modelos 3D' '3D Model Viewer'; Cat = 'Media'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.MixedReality.Portal'; Desc = Get-AppName 'Portal de Realidade Virtual (VR)' 'Mixed Reality Portal (VR)'; Cat = 'Media'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.MSPaint'; Desc = Get-AppName 'Microsoft Paint Clássico' 'Classic Microsoft Paint'; Cat = 'Media'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.Paint'; Desc = Get-AppName 'Paint Novo' 'Paint (New)'; Cat = 'Media'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.ZuneMusic'; Desc = Get-AppName 'Reprodutor de Música Antigo (Groove)' 'Groove Music Player'; Cat = 'Media'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.ZuneVideo'; Desc = Get-AppName 'Reprodutor Filmes e TV' 'Movies & TV Player'; Cat = 'Media'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.WindowsSoundRecorder'; Desc = Get-AppName 'Gravador de Voz' 'Voice Recorder'; Cat = 'Media'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.WindowsCamera'; Desc = Get-AppName 'Câmera do Windows' 'Windows Camera'; Cat = 'Media'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.Windows.Photos'; Desc = Get-AppName 'Visualizador de Imagens (Fotos)' 'Photos Viewer'; Cat = 'Media'; Remove = $true }

    # News
    [PSCustomObject]@{ Id = 'Microsoft.BingNews'; Desc = Get-AppName 'Microsoft Notícias (MSN)' 'Microsoft News (MSN)'; Cat = 'News'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.BingSearch'; Desc = Get-AppName 'Busca Web no Iniciar' 'Start Menu Web Search'; Cat = 'News'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.BingWeather'; Desc = Get-AppName 'Aplicativo de Clima / Previsão do Tempo' 'Weather App'; Cat = 'News'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.StartExperiencesApp'; Desc = Get-AppName 'Estrutura de Ícones de Notícias' 'News Feed Widget Host'; Cat = 'News'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.WindowsFeedbackHub'; Desc = Get-AppName 'Hub de Feedback do Sistema' 'System Feedback Hub'; Cat = 'News'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.GetHelp'; Desc = Get-AppName 'Assistente de Suporte e Ajuda' 'Get Help & Support'; Cat = 'News'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.Getstarted'; Desc = Get-AppName 'Primeiros Passos / Dicas do Windows' 'Windows Tips / Get Started'; Cat = 'News'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.WindowsMaps'; Desc = Get-AppName 'Mapas do Windows' 'Windows Maps'; Cat = 'News'; Remove = $true }
    [PSCustomObject]@{ Id = 'MicrosoftWindows.Client.WebExperience'; Desc = Get-AppName 'Painel de Widgets' 'Widgets Panel'; Cat = 'News'; Remove = $true }

    # Comms
    [PSCustomObject]@{ Id = 'Microsoft.SkypeApp'; Desc = Get-AppName 'Microsoft Skype' 'Microsoft Skype'; Cat = 'Comms'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.Windows.Teams'; Desc = Get-AppName 'Bate-papo Pessoal do Microsoft Teams' 'Teams Personal Chat'; Cat = 'Comms'; Remove = $true }
    [PSCustomObject]@{ Id = 'MSTeams'; Desc = Get-AppName 'Microsoft Teams (Clássico Corporativo)' 'Microsoft Teams (Classic)'; Cat = 'Comms'; Remove = $true }
    [PSCustomObject]@{ Id = 'MicrosoftTeams'; Desc = Get-AppName 'Microsoft Teams (Novo)' 'Microsoft Teams (New)'; Cat = 'Comms'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.OutlookForWindows'; Desc = Get-AppName 'Novo Outlook' 'New Outlook'; Cat = 'Comms'; Remove = $true }
    [PSCustomObject]@{ Id = 'microsoft.windowscommunicationsapps'; Desc = Get-AppName 'Aplicativo Antigo de Email e Calendário' 'Legacy Mail & Calendar'; Cat = 'Comms'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.People'; Desc = Get-AppName 'Aplicativo de Pessoas/Contatos' 'People / Contacts App'; Cat = 'Comms'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.YourPhone'; Desc = Get-AppName 'Vincular Smarpthone ao PC' 'Phone Link'; Cat = 'Comms'; Remove = $true }
    [PSCustomObject]@{ Id = 'MicrosoftWindows.CrossDevice'; Desc = Get-AppName 'Compartilhamento entre Dispositivos' 'Cross-Device Sharing'; Cat = 'Comms'; Remove = $true }

    # Prod
    [PSCustomObject]@{ Id = 'Microsoft.Todos'; Desc = Get-AppName 'Lista de Tarefas (Microsoft To Do)' 'Microsoft To Do'; Cat = 'Prod'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.MicrosoftStickyNotes'; Desc = Get-AppName 'Bloco de Notas na Área de Trabalho' 'Sticky Notes'; Cat = 'Prod'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.Office.OneNote'; Desc = Get-AppName 'Microsoft OneNote App' 'Microsoft OneNote'; Cat = 'Prod'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.OfficePushNotificationUtility'; Desc = Get-AppName 'Serviço de Notificações do Microsoft 365' 'Microsoft 365 Notification Service'; Cat = 'Prod'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.MicrosoftOfficeHub'; Desc = Get-AppName 'Central de Aplicativos Office 365' 'Office 365 App Center'; Cat = 'Prod'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.PowerAutomateDesktop'; Desc = Get-AppName 'Criador de Robôs e Macros (Power Automate)' 'Power Automate Desktop'; Cat = 'Prod'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.WindowsCalculator'; Desc = Get-AppName 'Calculadora do Windows' 'Windows Calculator'; Cat = 'Prod'; Remove = $false }
    [PSCustomObject]@{ Id = 'Microsoft.WindowsAlarms'; Desc = Get-AppName 'Relógio, Alarmes e Cronômetro' 'Clock, Alarms & Timer'; Cat = 'Prod'; Remove = $false }
    [PSCustomObject]@{ Id = 'Microsoft.WindowsNotepad'; Desc = Get-AppName 'Novo Bloco de Notas (Notepad)' 'Notepad (New)'; Cat = 'Prod'; Remove = $false }
    [PSCustomObject]@{ Id = 'Microsoft.ScreenSketch'; Desc = Get-AppName 'Ferramenta de Captura de Tela (Print Screen)' 'Snipping Tool'; Cat = 'Prod'; Remove = $false }
    [PSCustomObject]@{ Id = 'Microsoft.Copilot'; Desc = Get-AppName 'Inteligência Artificial Copilot' 'Copilot AI'; Cat = 'Prod'; Remove = $true }

    # Sys - Moving OneDrive to its own category per user request
    [PSCustomObject]@{ Id = 'OneDriveSetup'; Desc = Get-AppName 'Microsoft OneDrive' 'Microsoft OneDrive'; Cat = 'Sys'; Remove = $true }
    [PSCustomObject]@{ Id = 'MicrosoftEdge'; Desc = Get-AppName 'Microsoft Edge (Navegador)' 'Microsoft Edge (Browser)'; Cat = 'Sys'; Remove = $true }

    # Ads
    [PSCustomObject]@{ Id = 'King.Com.CandyCrushSaga'; Desc = Get-AppName 'Candy Crush Saga' 'Candy Crush Saga'; Cat = 'Ads'; Remove = $true }
    [PSCustomObject]@{ Id = 'Netflix'; Desc = Get-AppName 'App da Netflix' 'Netflix App'; Cat = 'Ads'; Remove = $true }
    [PSCustomObject]@{ Id = 'SpotifyAB.Spotify'; Desc = Get-AppName 'App de Música Spotify' 'Spotify App'; Cat = 'Ads'; Remove = $true }
    [PSCustomObject]@{ Id = 'DolbyLaboratories.DolbyAccess'; Desc = Get-AppName 'Demo Áudio Dolby Access' 'Dolby Access Demo'; Cat = 'Ads'; Remove = $true }
    [PSCustomObject]@{ Id = 'DolbyLaboratories.DolbyDigitalPlusDecoderOEM'; Desc = Get-AppName 'Decodificador Original Dolby' 'Dolby OEM Decoder'; Cat = 'Ads'; Remove = $true }
    [PSCustomObject]@{ Id = 'AppUp.IntelManagementandSecurityStatus'; Desc = Get-AppName 'Serviço Antigo de Segurança Intel' 'Intel Legacy Security Service'; Cat = 'Ads'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.Wallet'; Desc = Get-AppName 'Carteira Digital Microsoft (Microsoft Pay)' 'Microsoft Pay (Wallet)'; Cat = 'Ads'; Remove = $true }
    [PSCustomObject]@{ Id = 'MicrosoftCorporationII.MicrosoftFamily'; Desc = Get-AppName 'Controle Parental (Configuração em Família)' 'Parental Controls (Family Setup)'; Cat = 'Ads'; Remove = $true }

    # Dev
    [PSCustomObject]@{ Id = 'Microsoft.Windows.DevHome'; Desc = Get-AppName 'Ferramentas para Programadores' 'Developer Tools (Dev Home)'; Cat = 'Dev'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.WindowsTerminal'; Desc = Get-AppName 'Novo Terminal do Windows' 'Windows Terminal (New)'; Cat = 'Dev'; Remove = $true }
    [PSCustomObject]@{ Id = 'MicrosoftCorporationII.QuickAssist'; Desc = Get-AppName 'Assistência Rápida (Acesso Remoto T.I.)' 'Quick Assist (Remote IT Access)'; Cat = 'Dev'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.549981C3F5F10'; Desc = Get-AppName 'Assistente Virtual Cortana' 'Cortana Virtual Assistant'; Cat = 'Dev'; Remove = $true }
)

# ==========================================
# 1. Definir o Design da Janela em XAML
# ==========================================
[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$($Strings.WindowTitle)" Height="750" Width="850"
        ResizeMode="NoResize"
        WindowStartupLocation="CenterScreen" Background="#202020" Foreground="#FFFFFF"
        FontFamily="Segoe UI Variable, Segoe UI, sans-serif">
    <Window.Resources>
        <Style TargetType="TextBlock"><Setter Property="Foreground" Value="#FFFFFF"/><Setter Property="FontSize" Value="14"/></Style>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#0078D4"/><Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="FontWeight" Value="SemiBold"/><Setter Property="Padding" Value="15,8"/>
            <Setter Property="BorderThickness" Value="0"/><Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="4"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="#1A8CD8"/></Trigger>
                <Trigger Property="IsEnabled" Value="False"><Setter Property="Background" Value="#404040"/><Setter Property="Foreground" Value="#808080"/></Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="TextBox"><Setter Property="Background" Value="#2D2D2D"/><Setter Property="Foreground" Value="#FFFFFF"/><Setter Property="BorderBrush" Value="#383838"/><Setter Property="BorderThickness" Value="1"/><Setter Property="Padding" Value="8"/><Setter Property="FontSize" Value="14"/></Style>
        <Style TargetType="CheckBox"><Setter Property="Foreground" Value="#FFFFFF"/><Setter Property="FontSize" Value="13"/><Setter Property="Margin" Value="0,4,0,0"/><Setter Property="Cursor" Value="Hand"/><Style.Triggers><Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.35"/><Setter Property="Cursor" Value="Arrow"/></Trigger></Style.Triggers></Style>
    </Window.Resources>
    <Grid Margin="30">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Border Grid.Row="0" Margin="0,0,0,15" Padding="0,0,0,10" BorderBrush="#383838" BorderThickness="0,0,0,1">
            <StackPanel HorizontalAlignment="Center">
                <TextBlock Text="$($Strings.WindowTitle)" FontSize="26" FontWeight="Bold" Foreground="#60CDFF" HorizontalAlignment="Center"/>
                <TextBlock Text="$($Strings.Subtitle)" Foreground="#9E9E9E" Margin="0,4,0,0" HorizontalAlignment="Center" FontSize="13"/>
            </StackPanel>
        </Border>
        <Grid Grid.Row="1" Margin="0,0,0,15">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            
            <TextBlock Grid.Column="0" Text="$($Strings.BackendScript)" VerticalAlignment="Center" Margin="0,0,10,0" FontWeight="SemiBold"/>
            <ComboBox Name="ComboScript" Grid.Column="1" Width="150" HorizontalAlignment="Left" Background="#2D2D2D" Foreground="#11111B" Padding="5" FontSize="13" Margin="0,0,15,0">
                <ComboBoxItem Content="tiny11maker.ps1" IsSelected="True"/>
                <ComboBoxItem Content="tiny11Coremaker.ps1"/>
            </ComboBox>

            <TextBlock Grid.Column="2" Text="$($Strings.SourceDrive)" VerticalAlignment="Center" Margin="0,0,10,0" FontWeight="SemiBold"/>
            <ComboBox Name="ComboDrives" Grid.Column="3" Width="60" HorizontalAlignment="Left" Background="#2D2D2D" Foreground="#11111B" Padding="5" FontSize="13" Margin="0,0,15,0"/>
            
            <TextBlock Grid.Column="4" Text="$($Strings.VersionIndex)" VerticalAlignment="Center" Margin="0,0,10,0" FontWeight="SemiBold"/>
            <ComboBox Name="ComboIndex" Grid.Column="5" MinWidth="120" MaxWidth="320" HorizontalAlignment="Left" Background="#2D2D2D" Foreground="#11111B" Padding="5" FontSize="13"/>
        </Grid>
        <Grid Grid.Row="2" Margin="0,0,0,15">
            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <StackPanel Name="PanelCategories" Grid.Column="0" Margin="0,0,15,0">
                <TextBlock Text="$($Strings.Categories)" FontWeight="Bold" Foreground="#60CDFF" Margin="0,0,0,10"/>
                <CheckBox Name="ChkCatAds" Content="$($Strings.CatAds)" IsChecked="True"/>
                <CheckBox Name="ChkCatComms" Content="$($Strings.CatComms)" IsChecked="True"/>
                <CheckBox Name="ChkCatDev" Content="$($Strings.CatDev)" IsChecked="True"/>
                <CheckBox Name="ChkCatGames" Content="$($Strings.CatGames)" IsChecked="True"/>
                <CheckBox Name="ChkCatMedia" Content="$($Strings.CatMedia)" IsChecked="True"/>
                <CheckBox Name="ChkCatNews" Content="$($Strings.CatNews)" IsChecked="True"/>
                <CheckBox Name="ChkCatProd" Content="$($Strings.CatProd)" IsChecked="True"/>
                <CheckBox Name="ChkCatSys" Content="$($Strings.CatSys)" IsChecked="True"/>
                
                <Button Name="BtnListaBloatware" Content="$($Strings.BtnAppCustom)" ToolTip="$($Strings.AdvHint)" Width="190" HorizontalAlignment="Left" Margin="0,15,0,0" Background="#2D2D2D" Foreground="#FFFFFF" Padding="10,5"/>
            </StackPanel>
            <StackPanel Grid.Column="1">
                <StackPanel Name="PanelSysSettings">
                    <TextBlock Text="$($Strings.SysSettings)" FontWeight="Bold" Foreground="#6CCB5F" Margin="0,0,0,10"/>
                    <CheckBox Name="ChkBypassReqs" Content="$($Strings.OptBypass)" IsChecked="True"/>
                    <CheckBox Name="ChkDisableTelemetry" Content="$($Strings.OptTelemetry)" IsChecked="True"/>
                    <CheckBox Name="ChkLocalAccount" Content="$($Strings.OptLocalAccount)" IsChecked="True"/>
                </StackPanel>
                
                <StackPanel Name="PanelAdvSettings" Margin="0,20,0,0">
                    <TextBlock Text="$($Strings.AdvCoremakerOnly)" FontWeight="Bold" Foreground="#FFAA44" Margin="0,0,0,10" ToolTip="$($Strings.AdvCoremakerTip)"/>
                    <CheckBox Name="ChkRemoveDefender" Content="$($Strings.OptDefender)" IsChecked="False" IsEnabled="False"/>
                    <CheckBox Name="ChkDisableUpdate" Content="$($Strings.OptWinUpdate)" IsChecked="False" IsEnabled="False"/>
                    <CheckBox Name="ChkRemoveWinRE" Content="$($Strings.OptWinRE)" IsChecked="False" IsEnabled="False"/>
                    <CheckBox Name="ChkRemoveExtras" Content="$($Strings.OptSysExtras)" IsChecked="False" IsEnabled="False"/>
                </StackPanel>
            </StackPanel>
        </Grid>
        <Grid Grid.Row="3" Margin="0,0,0,15">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
            <TextBlock Text="$($Strings.ConsoleTitle)" FontWeight="SemiBold" Margin="0,0,0,5"/>
            <TextBox Name="LogBox" Grid.Row="1" IsReadOnly="True" AcceptsReturn="True" TextWrapping="Wrap" Background="#0C0C0C" Foreground="#00CC6A" FontFamily="Cascadia Mono, Consolas" FontSize="12" VerticalScrollBarVisibility="Auto" BorderBrush="#383838"/>
        </Grid>
        <StackPanel Grid.Row="4" Orientation="Horizontal" HorizontalAlignment="Center">
            <Button Name="BtnExit" Background="#4a4a4a" Content="$($Strings.BtnExit)" Width="120" Margin="0,0,20,0"/>
            <Button Name="BtnClear" Background="#FF4343" Content="$($Strings.BtnClear)" Width="220" Margin="0,0,20,0"/>
            <Button Name="BtnStart" Content="$($Strings.BtnStart)" Width="220"/>
        </StackPanel>
    </Grid>
</Window>
"@

$Reader = (New-Object System.Xml.XmlNodeReader $xaml)
$Window = [Windows.Markup.XamlReader]::Load($Reader)

# UI Elements
$ComboScript = $Window.FindName("ComboScript")
$ComboDrives = $Window.FindName("ComboDrives")
$ComboIndex = $Window.FindName("ComboIndex")
$BtnStart = $Window.FindName("BtnStart")
$BtnClear = $Window.FindName("BtnClear")
$BtnExit = $Window.FindName("BtnExit")
$LogBox = $Window.FindName("LogBox")
$BtnListaBloatware = $Window.FindName("BtnListaBloatware")

$ChkCatAds = $Window.FindName("ChkCatAds")
$ChkCatNews = $Window.FindName("ChkCatNews")
$ChkCatGames = $Window.FindName("ChkCatGames")
$ChkCatMedia = $Window.FindName("ChkCatMedia")
$ChkCatComms = $Window.FindName("ChkCatComms")
$ChkCatDev = $Window.FindName("ChkCatDev")
$ChkCatSys = $Window.FindName("ChkCatSys")
$ChkCatProd = $Window.FindName("ChkCatProd")

$ChkRemoveDefender = $Window.FindName("ChkRemoveDefender")
$ChkDisableUpdate = $Window.FindName("ChkDisableUpdate")
$ChkRemoveWinRE = $Window.FindName("ChkRemoveWinRE")
$ChkRemoveExtras = $Window.FindName("ChkRemoveExtras")

# Sort UI Checkboxes Alphabetically based on Language
$PanelCategories = $Window.FindName("PanelCategories")
if ($PanelCategories) {
    $catCheckboxes = @($PanelCategories.Children | Where-Object { $_ -is [System.Windows.Controls.CheckBox] } | Sort-Object Content)
    foreach ($chk in $catCheckboxes) {
        $PanelCategories.Children.Remove($chk) | Out-Null
        $PanelCategories.Children.Insert($PanelCategories.Children.Count - 1, $chk)
    }
}

$PanelSysSettings = $Window.FindName("PanelSysSettings")
if ($PanelSysSettings) {
    $sysCheckboxes = @($PanelSysSettings.Children | Where-Object { $_ -is [System.Windows.Controls.CheckBox] } | Sort-Object Content)
    foreach ($chk in $sysCheckboxes) {
        $PanelSysSettings.Children.Remove($chk) | Out-Null
        $PanelSysSettings.Children.Add($chk) | Out-Null
    }
}

$PanelAdvSettings = $Window.FindName("PanelAdvSettings")
if ($PanelAdvSettings) {
    $advCheckboxes = @($PanelAdvSettings.Children | Where-Object { $_ -is [System.Windows.Controls.CheckBox] } | Sort-Object Content)
    foreach ($chk in $advCheckboxes) {
        $PanelAdvSettings.Children.Remove($chk) | Out-Null
        $PanelAdvSettings.Children.Add($chk) | Out-Null
    }
}

# Helpers
function Write-Log([string]$Message) {
    if ($LogBox.Dispatcher.CheckAccess()) {
        $timestamp = (Get-Date).ToString("HH:mm:ss")
        $LogBox.AppendText("[$timestamp] $Message`r`n")
        $LogBox.ScrollToEnd()
    }
    else {
        $LogBox.Dispatcher.Invoke([Action] {
                $timestamp = (Get-Date).ToString("HH:mm:ss")
                $LogBox.AppendText("[$timestamp] $Message`r`n")
                $LogBox.ScrollToEnd()
            })
    }
}

function Get-ImageIndexes {
    $ComboIndex.Items.Clear()
    $selectedDrive = $ComboDrives.SelectedItem
    if (-not $selectedDrive) { return }
    
    $wimPath = "$selectedDrive\sources\install.wim"
    $esdPath = "$selectedDrive\sources\install.esd"
    
    $imagePath = $null
    if (Test-Path $wimPath) { $imagePath = $wimPath }
    elseif (Test-Path $esdPath) { $imagePath = $esdPath }
    
    if ($imagePath) {
        try {
            $images = Get-WindowsImage -ImagePath $imagePath -ErrorAction Stop
            foreach ($img in $images) {
                $ComboIndex.Items.Add("$($img.ImageIndex) - $($img.ImageName)") | Out-Null
            }
            if ($ComboIndex.Items.Count -gt 0) { $ComboIndex.SelectedIndex = 0 }
        }
        catch {
            $ComboIndex.Items.Add("1 - $($Strings.CbUnknown)") | Out-Null
            $ComboIndex.SelectedIndex = 0
        }
    }
    else {
        $ComboIndex.Items.Add("1 - $($Strings.CbDefault)") | Out-Null
        $ComboIndex.SelectedIndex = 0
    }
}

function Get-MountedDrives {
    $drives = Get-Volume | Where-Object DriveLetter | Select-Object -ExpandProperty DriveLetter
    $ComboDrives.Items.Clear()
    foreach ($drive in $drives) { $ComboDrives.Items.Add("$drive`:") | Out-Null }
    if ($ComboDrives.Items.Count -gt 0) { 
        $ComboDrives.SelectedIndex = 0 
        Get-ImageIndexes
    }
}

$ComboDrives.Add_SelectionChanged({ Get-ImageIndexes })

$ComboScript.Add_SelectionChanged({
        $isCoremaker = ($ComboScript.SelectedItem.Content -match "tiny11Coremaker.ps1")
        $ChkRemoveDefender.IsEnabled = $isCoremaker
        $ChkDisableUpdate.IsEnabled = $isCoremaker
        $ChkRemoveWinRE.IsEnabled = $isCoremaker
        $ChkRemoveExtras.IsEnabled = $isCoremaker
    })

# Master Sync (Main UI To Global Array)
function Sync-CategoryToGlobal($Cat, $State) {
    $boolState = ($State -eq $true)
    $Global:AppPackages | Where-Object Cat -eq $Cat | ForEach-Object { $_.Remove = $boolState }
}

# Events
$ChkCatAds.Add_Click({ Sync-CategoryToGlobal 'Ads' $ChkCatAds.IsChecked })
$ChkCatNews.Add_Click({ Sync-CategoryToGlobal 'News' $ChkCatNews.IsChecked })
$ChkCatGames.Add_Click({ Sync-CategoryToGlobal 'Games' $ChkCatGames.IsChecked })
$ChkCatMedia.Add_Click({ Sync-CategoryToGlobal 'Media' $ChkCatMedia.IsChecked })
$ChkCatComms.Add_Click({ Sync-CategoryToGlobal 'Comms' $ChkCatComms.IsChecked })
$ChkCatDev.Add_Click({ Sync-CategoryToGlobal 'Dev' $ChkCatDev.IsChecked })
$ChkCatSys.Add_Click({ Sync-CategoryToGlobal 'Sys' $ChkCatSys.IsChecked })
$ChkCatProd.Add_Click({ Sync-CategoryToGlobal 'Prod' $ChkCatProd.IsChecked })

$BtnClear.Add_Click({ $LogBox.Text = ""; Write-Log "Console Limpo." })
$BtnExit.Add_Click({ $Window.Close() })

$BtnListaBloatware.Add_Click({
        $xamlAdv = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="$($Strings.AdvTitle)" Height="650" Width="600"
        WindowStartupLocation="CenterOwner" Background="#11111B" Foreground="#CDD6F4"
        FontFamily="Segoe UI, Inter">
    <Window.Resources>
        <Style TargetType="CheckBox"><Setter Property="Foreground" Value="#CDD6F4"/><Setter Property="Margin" Value="20,2,0,5"/></Style>
    </Window.Resources>
    <Grid>
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <TextBlock Text="$($Strings.AdvHint)" Margin="15,15,15,10" Foreground="#A6E3A1" TextWrapping="Wrap" FontWeight="Bold"/>
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Margin="10,0">
            <StackPanel Name="ListPanel">
"@
        $sortedCats = $Global:AppPackages | Group-Object Cat | Sort-Object { $Strings["Cat$($_.Name)"] } | Select-Object -ExpandProperty Name
        foreach ($c in $sortedCats) {
            $catLabel = $Strings["Cat$c"]
            $xamlAdv += "<TextBlock Text='$($Strings.AdvCategory) $catLabel' FontWeight='Bold' Foreground='#89B4FA' Margin='5,10,0,5'/>`n"
            $appsInCat = $Global:AppPackages | Where-Object Cat -eq $c | Sort-Object Desc
            foreach ($app in $appsInCat) {
                $ch = if ($app.Remove) { "IsChecked='True'" } else { "" }
                $cleanId = $app.Id -replace '\.', '_'
                $tooltip = "ID: $($app.Id)"
                $xamlAdv += "<CheckBox Name='chk_$cleanId' Content='$($app.Desc)' ToolTip='$tooltip' $ch />`n"
            }
        }
        $xamlAdv += @"
            </StackPanel>
    </ScrollViewer>
        <Button Name="BtnSalvar" Grid.Row="2" Content="$($Strings.AdvBtnSave)" Background="#89B4FA" Foreground="#11111B" Margin="15" Padding="10,10" FontWeight="Bold" Cursor="Hand" BorderThickness="0"/>
    </Grid>
</Window>
"@
        $script:WinAdv = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader ([xml]$xamlAdv)))
        $script:WinAdv.Owner = $Window
    
        $BtnSalvar = $script:WinAdv.FindName("BtnSalvar")
        $BtnSalvar.Add_Click({
                foreach ($app in $Global:AppPackages) {
                    $cleanId = $app.Id -replace '\.', '_'
                    $chkObj = $script:WinAdv.FindName("chk_$cleanId")
                    if ($null -ne $chkObj) { $app.Remove = ($chkObj.IsChecked -eq $true) }
                }
                $script:WinAdv.Close()
            })
        $script:WinAdv.ShowDialog() | Out-Null
    })

$BtnStart.Add_Click({
        $selectedDrive = $ComboDrives.SelectedItem
        if (-not $selectedDrive) { Write-Log $Strings.MsgNoDrive; return }

        $imgIndex = 1
        if ($ComboIndex.SelectedItem -match "^(\d+) -") {
            $imgIndex = [int]$matches[1]
        }

        $isoDriveLetter = $selectedDrive.Substring(0, 1)
        $scriptArgs = "-ISO `"$isoDriveLetter`" -ImageIndex $imgIndex"

        # Check options
        if ($Global:AppPackages | Where-Object { $_.Id -eq 'Microsoft.Copilot' -and $_.Remove }) { $scriptArgs += " -RemoveCopilot" }
        if ($Global:AppPackages | Where-Object { $_.Id -eq 'MicrosoftEdge' -and $_.Remove -eq $false }) { $scriptArgs += " -KeepEdge" }
        if ($Global:AppPackages | Where-Object { $_.Id -eq 'OneDriveSetup' -and $_.Remove -eq $false }) { $scriptArgs += " -KeepOneDrive" } # logic inverted for keep flag

        $isCoremakerTarget = ($ComboScript.Text -match "tiny11Coremaker.ps1")
        if ($isCoremakerTarget) {
            if ($ChkRemoveDefender.IsChecked) { $scriptArgs += " -RemoveDefender" }
            if ($ChkDisableUpdate.IsChecked) { $scriptArgs += " -DisableUpdate" }
            if ($ChkRemoveWinRE.IsChecked) { $scriptArgs += " -RemoveWinRE" }
            if ($ChkRemoveExtras.IsChecked) { $scriptArgs += " -RemoveExtras" }
        }

        $BuildDir = Join-Path $ScriptDir "build"
        if (-not (Test-Path $BuildDir)) { New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null }
        
        # Generation apps_to_remove.txt
        $removeFile = Join-Path $BuildDir "apps_to_remove.txt"
        $Global:AppPackages | Where-Object { $_.Remove } | Select-Object -ExpandProperty Id | Out-File -FilePath $removeFile -Encoding UTF8
    
        $scriptArgs += " -AppListFile `"$removeFile`""

        Write-Log "---------------------------------------------"
        Write-Log "[INFO] Limpando pasta de compilação anterior ($PSScriptRoot\build) se existir..."
        Remove-Item -Path "$PSScriptRoot\build" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "ISO Drive: $selectedDrive"
        if ((Test-Path "$selectedDrive\sources\install.wim") -or (Test-Path "$selectedDrive\sources\install.esd")) {
            
            $TargetScript = $ComboScript.Text
            if (-not $TargetScript) { $TargetScript = "tiny11maker.ps1" }

            Write-Log "Build Engine: $TargetScript"
            
            $scriptFullPath = Join-Path $ScriptDir $TargetScript
            $psArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptFullPath`" $scriptArgs"
            try {
                $BtnStart.IsEnabled = $false

                $psi = New-Object System.Diagnostics.ProcessStartInfo
                $psi.FileName = "powershell.exe"
                $psi.Arguments = $psArgs
                $psi.UseShellExecute = $false
                $psi.RedirectStandardOutput = $true
                $psi.RedirectStandardError = $true
                $psi.CreateNoWindow = $true

                $script:BuildProcess = New-Object System.Diagnostics.Process
                $script:BuildProcess.StartInfo = $psi
                
                $script:BuildProcess.Start() | Out-Null
                $script:OutTask = $script:BuildProcess.StandardOutput.ReadLineAsync()
                $script:ErrTask = $script:BuildProcess.StandardError.ReadLineAsync()
                
                $script:LogTimer = New-Object System.Windows.Threading.DispatcherTimer
                $script:LogTimer.Interval = [TimeSpan]::FromMilliseconds(100)
                $script:LogTimer.Add_Tick({
                        if ($script:OutTask -and $script:OutTask.IsCompleted) {
                            $line = $script:OutTask.Result
                            if ($null -ne $line) {
                                $timestamp = (Get-Date).ToString("HH:mm:ss")
                                $LogBox.AppendText("[$timestamp] $line`r`n")
                                $LogBox.ScrollToEnd()
                                $script:OutTask = $script:BuildProcess.StandardOutput.ReadLineAsync()
                            }
                            else {
                                $script:OutTask = $null
                            }
                        }
                        if ($script:ErrTask -and $script:ErrTask.IsCompleted) {
                            $line = $script:ErrTask.Result
                            if ($null -ne $line) {
                                $timestamp = (Get-Date).ToString("HH:mm:ss")
                                $LogBox.AppendText("[$timestamp] [!] $line`r`n")
                                $LogBox.ScrollToEnd()
                                $script:ErrTask = $script:BuildProcess.StandardError.ReadLineAsync()
                            }
                            else {
                                $script:ErrTask = $null
                            }
                        }
                    
                        if ($script:BuildProcess.HasExited) {
                            # Add one last check just in case IsCompleted wasn't caught in the last tick
                            if ($script:OutTask -and $script:OutTask.IsCompleted) {
                                $line = $script:OutTask.Result
                                if ($null -ne $line) {
                                    $timestamp = (Get-Date).ToString("HH:mm:ss")
                                    $LogBox.AppendText("[$timestamp] $line`r`n")
                                    $LogBox.ScrollToEnd()
                                }
                            }
                            if ($script:ErrTask -and $script:ErrTask.IsCompleted) {
                                $line = $script:ErrTask.Result
                                if ($null -ne $line) {
                                    $timestamp = (Get-Date).ToString("HH:mm:ss")
                                    $LogBox.AppendText("[$timestamp] [!] $line`r`n")
                                    $LogBox.ScrollToEnd()
                                }
                            }

                            $script:LogTimer.Stop()
                            $code = $script:BuildProcess.ExitCode
                            $timestamp = (Get-Date).ToString("HH:mm:ss")
                            if ($code -eq 0) {
                                $LogBox.AppendText("[$timestamp] [OK] $($Strings.MsgSuccess)`r`n")
                            }
                            else {
                                $LogBox.AppendText("[$timestamp] [FAIL] Exit code: $code`r`n")
                            }
                            $LogBox.ScrollToEnd()
                            $BtnStart.IsEnabled = $true
                        }
                    })
                $script:LogTimer.Start()
                Write-Log $Strings.MsgStarted
            }
            catch {
                Write-Log "[ERRO/ERROR] $TargetScript failed to start: $_"
                $BtnStart.IsEnabled = $true
            }
        }
        else {
            Write-Log $Strings.MsgNoImage
        }
    })

$Window.Add_Loaded({ Write-Log $Strings.MsgGuiInit; Get-MountedDrives })
$Window.ShowDialog() | Out-Null

