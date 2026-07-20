# spxmiguel/homebrew-tap

Tap pessoal do Homebrew.

## Instalar o Task Manager

```bash
brew tap spxmiguel/tap            # adiciona este repositório como fonte de pacotes do Homebrew
brew install --cask task-manager  # baixa o código-fonte e compila o app na sua máquina
```

O que o `brew install --cask task-manager` faz, passo a passo:

1. Baixa o código-fonte do [mac-task-manager](https://github.com/spxmiguel/mac-task-manager) (não um binário pronto)
2. Confere se você tem as Command Line Tools do Xcode (gratuitas — não precisa de conta paga de desenvolvedor). Se não tiver, já dispara `xcode-select --install` e espera terminar sozinho
3. Compila o app com `swift build` assim que as ferramentas estão prontas
4. Monta o `.app`, assina localmente e copia para `/Applications`

Por ser um build feito na própria máquina (em vez de baixar um binário pronto de fora), o Gatekeeper não bloqueia o app com aviso de "desenvolvedor não identificado".

Depois é só abrir pelo Spotlight ou `/Applications/TaskManager.app` — o atalho global padrão é `⌘⎋` (Cmd+Esc), configurável dentro do app na aba Ajustes. O ícone na barra de menu abre/fecha com clique esquerdo, e tem `Sair` no clique direito.

> Primeira vez usando esta tap? O Homebrew pode pedir para confiar nela antes de instalar (trava de segurança padrão para taps de terceiros):
> ```bash
> brew trust --cask spxmiguel/tap/task-manager
> ```

Código-fonte: https://github.com/spxmiguel/mac-task-manager
