cask "task-manager" do
  version "1.0.1"
  sha256 "33aee80140741ac97cfe7e2d9bc64f6dcf718721c747c83c46c144d214fddca6"

  url "https://github.com/spxmiguel/mac-task-manager/releases/download/v#{version}/TaskManager-#{version}-macos.zip"
  name "Task Manager"
  desc "Gerenciador de tarefas nativo para macOS, estilo Windows 11"
  homepage "https://github.com/spxmiguel/mac-task-manager"

  depends_on macos: :ventura

  app "TaskManager.app"

  # O app e assinado ad-hoc (sem Developer ID / notarizacao, ja que nao
  # exigimos licenca paga de Xcode). Sem isso, o macOS marca o .app baixado
  # com o atributo de "quarantine" e o Gatekeeper bloqueia a abertura com um
  # aviso de "desenvolvedor nao identificado" / software malicioso. Como o
  # postflight roda fora do sandbox de build do Homebrew, aqui a gente
  # remove a quarentena e reassina localmente, do mesmo jeito que aconteceria
  # se a pessoa tivesse compilado o app na propria maquina.
  postflight do
    app_path = "#{appdir}/TaskManager.app"
    system_command "/usr/bin/xattr", args: ["-cr", app_path]
    system_command "/usr/bin/codesign", args: ["--force", "--deep", "-s", "-", app_path]
  end

  zap trash: [
    "~/Library/Preferences/com.miguel.taskmanager.plist",
  ]
end
