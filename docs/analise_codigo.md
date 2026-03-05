# Análise do Código: tiny11maker.ps1

O script `tiny11maker.ps1` original atua como o motor de automação que processa a ISO. Abaixo os principais passos executados por ele:

## Fluxo Principal
1. **Verificação de Permissões**: Garante que o script está rodando em uma sessão de Administrador do PowerShell (necessário para montar imagens usando o DISM).
2. **Cópia e Montagem**: Copia o conteúdo da ISO (apontada pela letra do drive) e usa comandos DISM nativos para montar o arquivo `install.wim` no disco.
3. **Limpeza de Bloatware**: Filtra a lista de provisão de aplicativos (Appx Packages) baseada em uma array hardcoded (`$packagePrefixes`) e os remove usando `Remove-ProvisionedAppxPackage`.  
4. **Aplicação de Tweaks no Registro**: Carrega colmeias offline do registro para desativar telemetria, anúncios em apps, integração com Teams/OneDrive, desativação do Copilot, Edge, entre outros. Além de pular requisitos de CPU/TPM/RAM.
5. **Remoção de Tarefas Agendadas**: Apaga gatilhos de telemetria da raiz do sistema.
6. **Otimização**: Executa `StartComponentCleanup /ResetBase` para expurgar arquivos órfãos da base da imagem, reduzindo o tamanho severamente.
7. **Empacotamento**: Faz um `Export-Image` com compressão alta (recovery), e em seguida repete os bypasses também na imagem de Boot (`boot.wim`).
8. **Geração da ISO**: Usa o executável oficial da Microsoft `oscdimg.exe` para criar a mídia bootável final.

## Conclusões para o Refatoramento e GUI
* O processo atual é um terminal interativo (`Read-Host` para inputs).
* **Para a nossa GUI**, a melhor abordagem é manter o PowerShell como "backend", mas separar os fluxos. A GUI coletará as configurações do usuário (quais apps manter/remover, diretórios de ISO/Destino) e passará essas opções como parâmetros para o script modificado, ou a própria GUI em PowerShell (via XAML/WPF) fará as chamadas nativas enviando logs para uma caixa de texto visual.
* **Sobre o Copilot:** No código original, encontramos as linhas:
  `Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 'REG_DWORD' '1'`
  Para o novo escopo, precisaremos **remover** ou adicionar um condicional nessa linha.
* **Modularidade:** Precisaremos injetar os resultados da nossa `lista_remocao_apps.md` no bloco das variáveis `$packagePrefixes`.
