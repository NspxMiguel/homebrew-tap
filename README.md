# spxmiguel/homebrew-tap

Tap pessoal do Homebrew.

## Instalar o Task Manager

```bash
brew tap spxmiguel/tap
brew install --cask task-manager
```

Depois é só abrir pelo Spotlight ou `/Applications/TaskManager.app` — o atalho global padrão é `⌘⎋` (Cmd+Esc), configurável dentro do app na aba Ajustes.

O app não tem assinatura paga da Apple (sem custo de licença de desenvolvedor). O cask já cuida de remover a quarentena e reassinar localmente depois de instalar, então não deve aparecer aviso de "desenvolvedor não identificado" do Gatekeeper.

Código-fonte: https://github.com/spxmiguel/mac-task-manager
