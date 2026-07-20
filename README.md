# spxmiguel/homebrew-tap

Tap pessoal do Homebrew.

## Instalar o Task Manager

```bash
brew tap spxmiguel/tap
brew install task-manager
```

Compila direto na sua máquina (precisa só das Command Line Tools do Xcode, grátis — `xcode-select --install` se ainda não tiver). Por ser um build local, o Gatekeeper não bloqueia como "desenvolvedor não identificado", diferente de baixar um `.app` pronto sem assinatura da Apple.

Depois é só abrir pelo Spotlight ou `/Applications/TaskManager.app` — o atalho global padrão é `⌘⎋` (Cmd+Esc), configurável dentro do app na aba Ajustes.

Código-fonte: https://github.com/spxmiguel/mac-task-manager
