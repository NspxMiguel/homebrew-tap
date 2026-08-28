# NspxMiguel/homebrew-tap

Tap pessoal do Homebrew.

```bash
brew tap NspxMiguel/tap   # adiciona este repositório como fonte de pacotes do Homebrew
```

Todo cask daqui **baixa o código-fonte e compila na sua máquina**, em vez de puxar um binário pronto. Build local não carrega o atributo de quarentena do download, então o Gatekeeper não bloqueia com aviso de "desenvolvedor não identificado" — e ninguém precisa de conta paga de desenvolvedor pra isso.

O preço é o tempo: a instalação leva alguns minutos e exige as Command Line Tools do Xcode (gratuitas). Se você não tiver, o próprio instalador dispara o `xcode-select --install` e espera terminar.

> Primeira vez usando esta tap? O Homebrew pede pra confiar nela antes de instalar (trava padrão pra taps de terceiros):
> ```bash
> brew trust --cask NspxMiguel/tap/<nome-do-cask>
> ```

## Pacotes

| Pacote | Instalação | O que é |
| --- | --- | --- |
| [Claude Remote Control](https://github.com/NspxMiguel/claude-remote-control) | `brew install --cask claude-remote-control` | Controle o Claude Code e outros agentes pelo celular. |
| [Task Manager](https://github.com/NspxMiguel/mac-task-manager) | `brew install --cask task-manager` | Gerenciador de tarefas nativo para macOS. |
| [MacTray](https://github.com/NspxMiguel/MacTray) | `brew install --cask mactray` | Esconde os ícones que não cabem na barra de menus. |
| [MailForAI](https://github.com/NspxMiguel/MailForAI) | `brew install --cask mailforai` | Caixa de e-mail com fila de aprovação para agentes de IA. |
| [NanoBridge](https://github.com/NspxMiguel/NanoBridge) | `brew install --cask nanobridge` | Geração de imagens Gemini para CLI e MCP. |

Todos baixam o código-fonte e montam o app ou ambiente localmente.

## Claude Remote Control

Controlar o Claude Code pelo celular. Um chat PWA que fala com o seu próprio Mac pela rede local ou pelo Tailscale, aprova permissão de ferramenta à distância e espelha ao vivo as sessões do Claude Desktop. Também dirige o Antigravity e qualquer agente ACP (Cursor, Gemini CLI).

```bash
brew install --cask claude-remote-control
```

Passo a passo do que acontece:

1. Baixa o código-fonte do [claude-remote-control](https://github.com/NspxMiguel/claude-remote-control)
2. Confere (ou instala) as Command Line Tools
3. Compila o app da barra de menu com `swift build`
4. Instala as dependências do daemon com `npm install` — elas viajam dentro do `.app`
5. Monta o `.app`, assina localmente e copia pra `/Applications`

Puxa o `node` junto como dependência, porque o daemon roda em Node.

Depois abra pelo Spotlight ou por `/Applications/ClaudeRemoteControl.app` e procure o `>_` na barra de menu. Na primeira vez ele já sobe o daemon e se registra pra voltar depois de reiniciar o Mac — o painel mostra os endereços pra abrir no celular, o QR pra parear, e switches pra desligar as duas coisas.

Código-fonte: https://github.com/NspxMiguel/claude-remote-control

## Task Manager

Gerenciador de tarefas nativo pro macOS, no estilo do Windows 11.

```bash
brew install --cask task-manager
```

1. Baixa o código-fonte do [mac-task-manager](https://github.com/NspxMiguel/mac-task-manager)
2. Confere (ou instala) as Command Line Tools
3. Compila com `swift build`
4. Monta o `.app`, assina localmente e copia pra `/Applications`

Abre pelo Spotlight ou por `/Applications/TaskManager.app` — o atalho global padrão é `⌘⇧⎋` (Cmd+Shift+Esc), configurável dentro do app na aba Ajustes. O ícone na barra de menu abre/fecha com clique esquerdo, e tem `Sair` no clique direito.

Código-fonte: https://github.com/NspxMiguel/mac-task-manager

## MacTray

Esconde os ícones que não cabem na barra de menus, mantendo-os acessíveis num painel próprio.

```bash
brew install --cask mactray
```

Na primeira abertura, conceda a permissão de Acessibilidade pedida pelo macOS.

## MailForAI

Uma caixa de e-mail para agentes de IA, com revisões na barra de menus antes de qualquer ação sensível.

```bash
brew install --cask mailforai
mailforai setup
```

## NanoBridge

Expõe a geração de imagens do Gemini como CLI e servidor MCP para agentes.

```bash
brew install --cask nanobridge
nanobridge doctor
```
