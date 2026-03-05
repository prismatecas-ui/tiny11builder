# Regras de Desenvolvimento - Projeto Tiny11 Interface Gráfica

Este documento define as regras fundamentais para a atualização e evolução do script `tiny11builder`, visando a criação de uma Interface Gráfica (GUI) segura e eficiente.

## Regras Fundamentais

1. **Escopo Original (Nativo)**: Não alterar a essência do script original. As modificações aplicadas na imagem do Windows (WIM/ISO) devem continuar utilizando ferramentas oficiais/nativas (como `dism`, `oscdimg`, `PowerShell cmdlets`). Não introduzir dependências de terceiros não confiáveis para a manipulação da ISO.
2. **Nenhuma Modificação Prematura**: Nenhuma linha do código original deve ser apagada ou editada até que uma análise completa do fluxo atual seja finalizada.
3. **Validação Rigorosa**: Sempre pesquisar e validar se a ferramenta a ser usada para um propósito específico é a maneira correta e segura no ecossistema atual do Windows. Evite comandos obsoletos.
4. **Preservação Funcional (Não quebrar o código)**: Qualquer refatoração feita no script em linha de comando (CLI) para adaptá-lo à Interface Gráfica deve manter sua funcionalidade intacta.
5. **Gestão de Bloatware (Aplicativos Inúteis)**:
    - O processo de limpeza deve focar apenas em componentes desnecessários que não quebrem o núcleo do sistema (Safe to Remove).
    - **Regra de Reversibilidade**: Apesar de removidos da ISO de instalação, a remoção não deve bloquear ou impedir que o usuário instale as ferramentas futuramente caso deseje (ex: via Microsoft Store ou Winget).
    - **Exceção de Remoção**: O aplicativo **Copilot** e suas dependências diretas **NÃO** devem ser inseridos na lista de remoção, pois há a necessidade de testá-lo.
6. **Idioma e Padronização**: Toda e qualquer documentação (como este arquivo), roteiro, tutorial ou manual deve ser criada dentro desta pasta `Documentacao_Tiny11` e sempre escrita em **Português Brasileiro (PT-BR)** com nomes claros.
