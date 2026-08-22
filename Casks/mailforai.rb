cask "mailforai" do
  version "0.2.0"
  sha256 "b01d725b8aedbad39eae455cabf7cafd7bfa4c0df58ae1c2076a8aa14f5b11c3"

  # Baixa o CODIGO-FONTE e compila na maquina de quem instala. Build local =
  # sem atributo de quarentena no binario final = sem aviso de Gatekeeper, e
  # sem precisar de Developer ID pago.
  url "https://github.com/NspxMiguel/MailForAI/archive/refs/tags/v#{version}.tar.gz"
  name "MailForAI"
  desc "Caixa de e-mail para agentes de IA, com fila de aprovacao na barra de menus"
  homepage "https://github.com/NspxMiguel/MailForAI"

  depends_on macos: :ventura

  # Nada pronto pra "instalar": o postflight compila o app e liga o CLI.
  stage_only true

  postflight do
    app_path = "#{appdir}/MailForAI.app"

    clt_installed = system_command("/usr/bin/xcode-select", args: ["-p"], print_stderr: false).success?

    unless clt_installed
      ohai "Command Line Tools do Xcode nao encontradas — baixando (necessario pra compilar)…"
      system_command "/usr/bin/xcode-select", args: ["--install"]

      ohai "Aguardando a instalacao terminar (clique em \"Instalar\" na janela que abriu)…"
      waited = 0
      timeout = 30 * 60 # 30 min
      until system_command("/usr/bin/xcode-select", args: ["-p"], print_stderr: false).success?
        if waited >= timeout
          odie "Tempo esgotado esperando as Command Line Tools. Rode 'xcode-select --install', " \
               "espere terminar, e rode 'brew reinstall --cask mailforai' de novo."
        end
        sleep 10
        waited += 10
      end
      ohai "Command Line Tools instaladas. Compilando o app…"
    else
      ohai "Command Line Tools encontradas. Compilando o app…"
    end

    source_dir = Dir.glob("#{staged_path}/MailForAI-*").first || staged_path.to_s

    # build_app.sh ja faz tudo: compila, gera o icone e embute o CLI em Python
    # dentro do bundle. Duplicar esses passos aqui seria manter dois roteiros.
    system_command "/bin/bash", args: ["#{source_dir}/mac/build_app.sh"], chdir: source_dir

    FileUtils.rm_rf(app_path)
    FileUtils.cp_r("#{source_dir}/mac/MailForAI.app", app_path)

    # O CLI mora dentro do app: uma instalacao so, e o app sempre conversa com
    # a mesma versao que o terminal.
    cli = "#{app_path}/Contents/Resources/mailforai/bin/mailforai"
    FileUtils.chmod 0755, cli
    FileUtils.mkdir_p HOMEBREW_PREFIX/"bin"
    FileUtils.ln_sf cli, HOMEBREW_PREFIX/"bin/mailforai"

    system_command "/usr/bin/xattr", args: ["-cr", app_path]
    system_command "/usr/bin/codesign", args: ["--force", "--deep", "--sign", "-", app_path]

    ohai "Pronto. Rode 'mailforai setup' pra configurar a caixa, e abra o MailForAI."
  end

  uninstall delete: [
    "/Applications/MailForAI.app",
    "#{HOMEBREW_PREFIX}/bin/mailforai",
  ]

  zap trash: [
    "~/.mailforai",
    "~/Library/Preferences/dev.nspx.mailforai.plist",
  ]

  caveats <<~EOS
    O MailForAI compila na sua maquina (leva ~30s) e nao guarda senha em arquivo:
    a credencial da caixa vai pro Chaveiro do macOS.

    Proximo passo:
      mailforai setup
  EOS
end
