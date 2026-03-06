<#
.SYNOPSIS
    Interface gráfica para o Tiny11Builder.
.DESCRIPTION
    Fornece uma GUI nativa em WPF elegante e responsiva para rodar scripts do Tiny11 (DISM) de forma limpa, permitindo seleção granular de bloatwares.
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
# 0. Base de Dados Viva (Global)
# ==========================================
$Global:AppPackages = @(
    [PSCustomObject]@{ Id = 'Microsoft.GamingApp'; Desc = 'App Xbox no PC'; Cat = 'Games'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.MicrosoftSolitaireCollection'; Desc = 'Paciencia Solitaire'; Cat = 'Games'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.Xbox.TCUI'; Desc = 'Interface da Xbox Live'; Cat = 'Games'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.XboxApp'; Desc = 'App Xbox Classico'; Cat = 'Games'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.XboxGameOverlay'; Desc = 'Barra de Jogo do Xbox'; Cat = 'Games'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.XboxGamingOverlay'; Desc = 'Extensao Barra Jogo'; Cat = 'Games'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.XboxIdentityProvider'; Desc = 'Login Xbox'; Cat = 'Games'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.XboxSpeechToTextOverlay'; Desc = 'Voz para Texto Xbox'; Cat = 'Games'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.Edge.GameAssist'; Desc = 'Game Assist do Edge'; Cat = 'Games'; Remove = $true }

    [PSCustomObject]@{ Id = 'Clipchamp.Clipchamp'; Desc = 'Editor Clipchamp'; Cat = 'Media'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.Microsoft3DViewer'; Desc = 'Visualizador 3D'; Cat = 'Media'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.MixedReality.Portal'; Desc = 'Portal Realidade Mista'; Cat = 'Media'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.MSPaint'; Desc = 'Paint Classico / Antigo'; Cat = 'Media'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.Paint'; Desc = 'Paint Novo'; Cat = 'Media'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.ZuneMusic'; Desc = 'Groove Musica'; Cat = 'Media'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.ZuneVideo'; Desc = 'Filmes e TV'; Cat = 'Media'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.WindowsSoundRecorder'; Desc = 'Gravador de Som'; Cat = 'Media'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.WindowsCamera'; Desc = 'Camera Nativa'; Cat = 'Media'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.Windows.Photos'; Desc = 'Nativo de Fotos (Cuidado)'; Cat = 'Media'; Remove = $false }

    [PSCustomObject]@{ Id = 'Microsoft.BingNews'; Desc = 'Noticias Bing (MSN)'; Cat = 'News'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.BingSearch'; Desc = 'Busca Web no Iniciar'; Cat = 'News'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.BingWeather'; Desc = 'Previsao do Tempo (Widget)'; Cat = 'News'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.StartExperiencesApp'; Desc = 'Host de Widgets do MSN'; Cat = 'News'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.WindowsFeedbackHub'; Desc = 'Hub de Feedback de Win'; Cat = 'News'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.GetHelp'; Desc = 'App Obter Ajuda'; Cat = 'News'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.Getstarted'; Desc = 'Dicas Iniciais'; Cat = 'News'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.WindowsMaps'; Desc = 'Microsoft Mapas'; Cat = 'News'; Remove = $true }
    [PSCustomObject]@{ Id = 'MicrosoftWindows.Client.WebExperience'; Desc = 'Painel de Widgets (Pesado)'; Cat = 'News'; Remove = $true }

    [PSCustomObject]@{ Id = 'Microsoft.SkypeApp'; Desc = 'Aplicativo Skype'; Cat = 'Comms'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.Windows.Teams'; Desc = 'Integracao Teams Barra'; Cat = 'Comms'; Remove = $true }
    [PSCustomObject]@{ Id = 'MSTeams'; Desc = 'Teams UWP Antigo'; Cat = 'Comms'; Remove = $true }
    [PSCustomObject]@{ Id = 'MicrosoftTeams'; Desc = 'Microsoft Teams Core'; Cat = 'Comms'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.OutlookForWindows'; Desc = 'Novo Outlook'; Cat = 'Comms'; Remove = $true }
    [PSCustomObject]@{ Id = 'microsoft.windowscommunicationsapps'; Desc = 'Correio/Calendario Legado'; Cat = 'Comms'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.People'; Desc = 'App de Contatos'; Cat = 'Comms'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.YourPhone'; Desc = 'Vincular ao Celular'; Cat = 'Comms'; Remove = $true }
    [PSCustomObject]@{ Id = 'MicrosoftWindows.CrossDevice'; Desc = 'Aparelhos Conectados'; Cat = 'Comms'; Remove = $true }

    [PSCustomObject]@{ Id = 'Microsoft.Todos'; Desc = 'Tarefas (To-Do)'; Cat = 'Prod'; Remove = $false }
    [PSCustomObject]@{ Id = 'Microsoft.MicrosoftStickyNotes'; Desc = 'Notas Auto-Adesivas'; Cat = 'Prod'; Remove = $false }
    [PSCustomObject]@{ Id = 'Microsoft.Office.OneNote'; Desc = 'OneNote (Loja)'; Cat = 'Prod'; Remove = $false }
    [PSCustomObject]@{ Id = 'Microsoft.OfficePushNotificationUtility'; Desc = 'Avisos do Hub Office'; Cat = 'Prod'; Remove = $false }
    [PSCustomObject]@{ Id = 'Microsoft.MicrosoftOfficeHub'; Desc = 'Centro Microsoft 365'; Cat = 'Prod'; Remove = $false }
    [PSCustomObject]@{ Id = 'Microsoft.PowerAutomateDesktop'; Desc = 'Power Automate'; Cat = 'Prod'; Remove = $false }
    [PSCustomObject]@{ Id = 'Microsoft.WindowsCalculator'; Desc = 'Calculadora Nativa'; Cat = 'Prod'; Remove = $false }
    [PSCustomObject]@{ Id = 'Microsoft.WindowsAlarms'; Desc = 'Alarmes e Relogio'; Cat = 'Prod'; Remove = $false }
    [PSCustomObject]@{ Id = 'Microsoft.WindowsNotepad'; Desc = 'Bloco de Notas (Abas)'; Cat = 'Prod'; Remove = $false }
    [PSCustomObject]@{ Id = 'Microsoft.ScreenSketch'; Desc = 'Ferramenta de Captura'; Cat = 'Prod'; Remove = $false }

    [PSCustomObject]@{ Id = 'King.Com.CandyCrushSaga'; Desc = 'Candy Crush Saga'; Cat = 'Ads'; Remove = $true }
    [PSCustomObject]@{ Id = 'Netflix'; Desc = 'Netflix Patrocinado'; Cat = 'Ads'; Remove = $true }
    [PSCustomObject]@{ Id = 'SpotifyAB.Spotify'; Desc = 'Spotify Patrocinado'; Cat = 'Ads'; Remove = $true }
    [PSCustomObject]@{ Id = 'DolbyLaboratories.DolbyAccess'; Desc = 'Dolby Access (Trial)'; Cat = 'Ads'; Remove = $true }
    [PSCustomObject]@{ Id = 'DolbyLaboratories.DolbyDigitalPlusDecoderOEM'; Desc = 'Decodificador Dolby OEM'; Cat = 'Ads'; Remove = $true }
    [PSCustomObject]@{ Id = 'AppUp.IntelManagementandSecurityStatus'; Desc = 'App Obsoleto Intel'; Cat = 'Ads'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.Wallet'; Desc = 'Microsoft Wallet / Pay'; Cat = 'Ads'; Remove = $true }
    [PSCustomObject]@{ Id = 'MicrosoftCorporationII.MicrosoftFamily'; Desc = 'Controle de Pais'; Cat = 'Ads'; Remove = $true }

    [PSCustomObject]@{ Id = 'Microsoft.Windows.DevHome'; Desc = 'Painel Dev Home'; Cat = 'Dev'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.WindowsTerminal'; Desc = 'Terminal Moderno UWP'; Cat = 'Dev'; Remove = $true }
    [PSCustomObject]@{ Id = 'MicrosoftCorporationII.QuickAssist'; Desc = 'Assistencia Rapida MS'; Cat = 'Dev'; Remove = $true }
    [PSCustomObject]@{ Id = 'Microsoft.549981C3F5F10'; Desc = 'Cortana Obsoleta'; Cat = 'Dev'; Remove = $true }
)

# ==========================================
# 1. Definir o Design da Janela em XAML
# ==========================================
[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Tiny11Builder UI - Premium" Height="750" Width="850"
        WindowStartupLocation="CenterScreen" Background="#1E1E2E" Foreground="#CDD6F4"
        FontFamily="Segoe UI, Inter, Roboto, sans-serif">
    <Window.Resources>
        <Style TargetType="TextBlock"><Setter Property="Foreground" Value="#CDD6F4"/><Setter Property="FontSize" Value="14"/></Style>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#89B4FA"/><Setter Property="Foreground" Value="#11111B"/>
            <Setter Property="FontWeight" Value="SemiBold"/><Setter Property="Padding" Value="15,8"/>
            <Setter Property="BorderThickness" Value="0"/><Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="6"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="#B4BEFE"/></Trigger>
                <Trigger Property="IsEnabled" Value="False"><Setter Property="Background" Value="#45475A"/><Setter Property="Foreground" Value="#A6ADC8"/></Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="TextBox"><Setter Property="Background" Value="#313244"/><Setter Property="Foreground" Value="#CDD6F4"/><Setter Property="BorderBrush" Value="#45475A"/><Setter Property="BorderThickness" Value="1"/><Setter Property="Padding" Value="8"/><Setter Property="FontSize" Value="14"/></Style>
        <Style TargetType="CheckBox"><Setter Property="Foreground" Value="#CDD6F4"/><Setter Property="FontSize" Value="14"/><Setter Property="Margin" Value="0,5,0,0"/><Setter Property="Cursor" Value="Hand"/></Style>
    </Window.Resources>
    <Grid Margin="30">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Border Grid.Row="0" Margin="0,0,0,15" Padding="0,0,0,10" BorderBrush="#45475A" BorderThickness="0,0,0,1">
            <StackPanel HorizontalAlignment="Center">
                <TextBlock Text="Tiny11 GUI Builder" FontSize="28" FontWeight="Bold" Foreground="#89B4FA" HorizontalAlignment="Center"/>
                <TextBlock Text="Selecione a ISO e configure precisamente o debloat do Windows 11." Foreground="#A6ADC8" Margin="0,5,0,0" HorizontalAlignment="Center"/>
            </StackPanel>
        </Border>
        <Grid Grid.Row="1" Margin="0,0,0,15">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <TextBlock Grid.Column="0" Text="Drive de Origem:" VerticalAlignment="Center" Margin="0,0,10,0" FontWeight="SemiBold"/>
            <ComboBox Name="ComboDrives" Grid.Column="1" Width="60" HorizontalAlignment="Left" Background="#313244" Foreground="#11111B" Padding="5" FontSize="14" Margin="0,0,15,0"/>
            
            <TextBlock Grid.Column="2" Text="Vers&#227;o (Index):" VerticalAlignment="Center" Margin="0,0,10,0" FontWeight="SemiBold"/>
            <ComboBox Name="ComboIndex" Grid.Column="3" HorizontalAlignment="Stretch" Background="#313244" Foreground="#11111B" Padding="5" FontSize="14"/>
        </Grid>
        <Grid Grid.Row="2" Margin="0,0,0,15">
            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0" Margin="0,0,15,0">
                <TextBlock Text="Categorias Mestre (Marcou, remove tudo dela)" FontWeight="Bold" Foreground="#F38BA8" Margin="0,0,0,10"/>
                <CheckBox Name="ChkCatAds" Content="Remover Lixo Patrocinado (Spotify, Netflix)" IsChecked="True"/>
                <CheckBox Name="ChkCatNews" Content="Remover Not&#237;cias, Bing e Clima" IsChecked="True"/>
                <CheckBox Name="ChkCatGames" Content="Remover Integra&#231;&#227;o Xbox e Jogos" IsChecked="True"/>
                <CheckBox Name="ChkCatMedia" Content="Remover M&#237;dia Menor (3DViewer, Clipchamp)" IsChecked="True"/>
                <CheckBox Name="ChkCatComms" Content="Remover Comunica&#231;&#227;o (Teams, Skype, Mail)" IsChecked="True"/>
                <CheckBox Name="ChkCatDev" Content="Remover DevTools (Terminal, DevHome)" IsChecked="True"/>
                <TextBlock Text="Produtividade" FontWeight="SemiBold" Foreground="#F9E2AF" Margin="0,15,0,5"/>
                <CheckBox Name="ChkCatProd" Content="Remover Utilit&#225;rios (Bloco, TODO)" IsChecked="False"/>
                <CheckBox Name="ChkCatCalc" Content="Remover Calculadora Nativa" IsChecked="False"/>
                <CheckBox Name="ChkCatPhotos" Content="Remover Visualizador de Fotos" IsChecked="False"/>
                
                <Button Name="BtnListaBloatware" Content="Ajustar Softwares 1 a 1..." Width="190" HorizontalAlignment="Left" Margin="0,15,0,0" Background="#313244" Foreground="#CDD6F4" Padding="10,5"/>
            </StackPanel>
            <StackPanel Grid.Column="1">
                <TextBlock Text="Ajustes Finos do Sistema" FontWeight="Bold" Foreground="#A6E3A1" Margin="0,0,0,10"/>
                <CheckBox Name="ChkBypassReqs" Content="Bypass Requisitos CPU/RAM/TPM" IsChecked="True"/>
                <CheckBox Name="ChkRemoveCopilot" Content="Remover Microsoft Copilot (Recomendado)" IsChecked="True"/>
                <CheckBox Name="ChkRemoveEdge" Content="Remover Microsoft Edge (Navegador)" IsChecked="True"/>
                <CheckBox Name="ChkRemoveOneDrive" Content="Remover OneDrive" IsChecked="True"/>
                <CheckBox Name="ChkDisableTelemetry" Content="Desabilitar Telemetria MS" IsChecked="True"/>
                <CheckBox Name="ChkLocalAccount" Content="For&#231;ar Conta Local (OOBE Offline)" IsChecked="True"/>
            </StackPanel>
        </Grid>
        <Grid Grid.Row="3" Margin="0,0,0,15">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
            <TextBlock Text="Console de Processamento:" FontWeight="SemiBold" Margin="0,0,0,5"/>
            <TextBox Name="LogBox" Grid.Row="1" IsReadOnly="True" AcceptsReturn="True" TextWrapping="Wrap" Background="#181825" Foreground="#A6E3A1" FontFamily="Consolas" VerticalScrollBarVisibility="Auto"/>
        </Grid>
        <StackPanel Grid.Row="4" Orientation="Horizontal" HorizontalAlignment="Center">
            <Button Name="BtnClear" Background="#F38BA8" Content="LIMPAR CONSOLE" Width="220" Margin="0,0,20,0"/>
            <Button Name="BtnStart" Content="OTIMIZAR IMAGEM ISO" Width="220"/>
        </StackPanel>
    </Grid>
</Window>
"@

$Reader = (New-Object System.Xml.XmlNodeReader $xaml)
$Window = [Windows.Markup.XamlReader]::Load($Reader)

# UI Elements
$ComboDrives = $Window.FindName("ComboDrives")
$ComboIndex = $Window.FindName("ComboIndex")
$BtnStart = $Window.FindName("BtnStart")
$BtnClear = $Window.FindName("BtnClear")
$LogBox = $Window.FindName("LogBox")
$BtnListaBloatware = $Window.FindName("BtnListaBloatware")

$ChkRemoveCopilot = $Window.FindName("ChkRemoveCopilot")
$ChkRemoveEdge = $Window.FindName("ChkRemoveEdge")
$ChkRemoveOneDrive = $Window.FindName("ChkRemoveOneDrive")

$ChkCatAds = $Window.FindName("ChkCatAds")
$ChkCatNews = $Window.FindName("ChkCatNews")
$ChkCatGames = $Window.FindName("ChkCatGames")
$ChkCatMedia = $Window.FindName("ChkCatMedia")
$ChkCatComms = $Window.FindName("ChkCatComms")
$ChkCatDev = $Window.FindName("ChkCatDev")
$ChkCatProd = $Window.FindName("ChkCatProd")
$ChkCatCalc = $Window.FindName("ChkCatCalc")
$ChkCatPhotos = $Window.FindName("ChkCatPhotos")

# Helpers
function Write-Log([string]$Message) {
    $LogBox.Dispatcher.Invoke([Action] {
            $timestamp = (Get-Date).ToString("HH:mm:ss")
            $LogBox.AppendText("[$timestamp] $Message`r`n")
            $LogBox.ScrollToEnd()
        })
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
                # Formato: "1 - Windows 11 Pro"
                $ComboIndex.Items.Add("$($img.ImageIndex) - $($img.ImageName)") | Out-Null
            }
            if ($ComboIndex.Items.Count -gt 0) { $ComboIndex.SelectedIndex = 0 }
        }
        catch {
            Write-Log "[ERRO] Leitura de Indexes falhou: $_"
            $ComboIndex.Items.Add("1 - Desconhecido") | Out-Null
            $ComboIndex.SelectedIndex = 0
        }
    }
    else {
        $ComboIndex.Items.Add([System.Net.WebUtility]::HtmlDecode("1 - Padr&#227;o")) | Out-Null
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
$ChkCatProd.Add_Click({ Sync-CategoryToGlobal 'Prod' $ChkCatProd.IsChecked })
$ChkCatCalc.Add_Click({ Sync-CategoryToGlobal 'Calc' $ChkCatCalc.IsChecked })
$ChkCatPhotos.Add_Click({ Sync-CategoryToGlobal 'Photos' $ChkCatPhotos.IsChecked })

$BtnClear.Add_Click({ $LogBox.Text = ""; Write-Log "Console Limpo." })

$BtnListaBloatware.Add_Click({
        $xamlAdv = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Controle Granular de Software" Height="650" Width="600"
        WindowStartupLocation="CenterOwner" Background="#11111B" Foreground="#CDD6F4"
        FontFamily="Segoe UI, Inter">
    <Window.Resources>
        <Style TargetType="CheckBox"><Setter Property="Foreground" Value="#CDD6F4"/><Setter Property="Margin" Value="20,2,0,5"/></Style>
    </Window.Resources>
    <Grid>
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <TextBlock Text="Desmarque qualquer app individual que deseje preservar na ISO. Marcar a caixa = Remover." Margin="15,15,15,10" Foreground="#A6E3A1" TextWrapping="Wrap" FontWeight="Bold"/>
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Margin="10,0">
            <StackPanel Name="ListPanel">
"@
        $cats = $Global:AppPackages | Select-Object -ExpandProperty Cat -Unique
        foreach ($c in $cats) {
            $xamlAdv += "<TextBlock Text='Categoria: $c' FontWeight='Bold' Foreground='#89B4FA' Margin='5,10,0,5'/>`n"
            foreach ($app in $Global:AppPackages | Where-Object Cat -eq $c) {
                $ch = if ($app.Remove) { "IsChecked='True'" }else { "" }
                $cleanId = $app.Id -replace '\.', '_'
                $tooltip = "ID Tecnico: $($app.Id)"
                $xamlAdv += "<CheckBox Name='chk_$cleanId' Content='$($app.Desc)' ToolTip='$tooltip' $ch />`n"
            }
        }
        $xamlAdv += @"
            </StackPanel>
    </ScrollViewer>
        <Button Name="BtnSalvar" Grid.Row="2" Content="SALVAR E RETORNAR" Background="#89B4FA" Foreground="#11111B" Margin="15" Padding="10,10" FontWeight="Bold" Cursor="Hand" BorderThickness="0"/>
    </Grid>
</Window>
"@
        $script:WinAdv = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader ([xml]$xamlAdv)))
        $script:WinAdv.Owner = $Window
    
        $BtnSalvar = $script:WinAdv.FindName("BtnSalvar")
        $BtnSalvar.Add_Click({
                # Grava de volta na memória e reflete no painel principal
                foreach ($app in $Global:AppPackages) {
                    $cleanId = $app.Id -replace '\.', '_'
                    $chkObj = $script:WinAdv.FindName("chk_$cleanId")
                    if ($null -ne $chkObj) { $app.Remove = ($chkObj.IsChecked -eq $true) }
                }
                $script:WinAdv.Close()
                Write-Log "[INFO] Configurações de lista individual atualizadas e salvas na sessão."
            })
        $script:WinAdv.ShowDialog() | Out-Null
    })

$BtnStart.Add_Click({
        $selectedDrive = $ComboDrives.SelectedItem
        if (-not $selectedDrive) { Write-Log "[ERRO] Selecione um Drive."; return }

        $imgIndex = 1
        if ($ComboIndex.SelectedItem -match "^(\d+) -") {
            $imgIndex = [int]$matches[1]
        }

        # Sincroniza uma última vez caso o usuário não tenha clicado no avançado
        # Importante: Para não sobrescrever o Avançado, não chamamos 'Sync-CategoriesToGlobal' aqui
        # porque as Categories já se sincronizam pelo evento `Add_Click` delas na UI automaticamente.

        $isoDriveLetter = $selectedDrive.Substring(0, 1)
        $scriptArgs = "-ISO `"$isoDriveLetter`" -ImageIndex $imgIndex"

        # Checagens Extras/Básicas
        if ($ChkRemoveCopilot.IsChecked) { $scriptArgs += " -RemoveCopilot" }
        if (-not $ChkRemoveEdge.IsChecked) { $scriptArgs += " -KeepEdge" }
        if (-not $ChkRemoveOneDrive.IsChecked) { $scriptArgs += " -KeepOneDrive" }

        $BuildDir = Join-Path $ScriptDir "build"
        if (-not (Test-Path $BuildDir)) { New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null }
        
        # Gerar Lista Física de AppsX
        $removeFile = Join-Path $BuildDir "apps_to_remove.txt"
        $Global:AppPackages | Where-Object { $_.Remove } | Select-Object -ExpandProperty Id | Out-File -FilePath $removeFile -Encoding UTF8
    
        $scriptArgs += " -AppListFile `"$removeFile`""

        Write-Log "---------------------------------------------"
        Write-Log "Drive da ISO: $selectedDrive"
        if ((Test-Path "$selectedDrive\sources\install.wim") -or (Test-Path "$selectedDrive\sources\install.esd")) {
            Write-Log "[OK] Base WIM instalável encontrada. Repassando os ($($Global:AppPackages | Where-Object Remove | Measure-Object | Select-Object -ExpandProperty Count)) apps marcados para o background."
        
            $psArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptDir\tiny11maker.ps1`" $scriptArgs"
            try {
                $BtnStart.IsEnabled = $false
                Start-Process powershell.exe -ArgumentList $psArgs -Verb RunAs
                Write-Log "[SUCESSO] Tiny11Backend invocado no console root!"
            }
            catch {
                Write-Log "[ERRO] Motor Backend falhou em inicializar: $_"
            }
        }
        else {
            Write-Log "[!] WIM Inexistente. Tem certeza de que o drive selecionado é da montagem da ISO?"
        }
        $BtnStart.IsEnabled = $true
    })

$Window.Add_Loaded({ Write-Log "[INFO] GUI Inicializada."; Get-MountedDrives })
$Window.ShowDialog() | Out-Null
