cask "mymailforai" do
  version "0.3.0"
  sha256 "f7669c04db24bb601c5bb4c3e8daf45e1179245f7175a48de332c23dec001631"

  # Baixa o CODIGO-FONTE e compila na maquina de quem instala. Build local =
  # sem atributo de quarentena no binario final = sem aviso de Gatekeeper, e
  # sem precisar de Developer ID pago.
  url "https://github.com/NspxMiguel/MyMailForAI/archive/refs/tags/v#{version}.tar.gz"
  name "MyMailForAI"
  desc "Sua propria caixa de e-mail, com acesso total pra IA e o freio na barra de menus"
  homepage "https://github.com/NspxMiguel/MyMailForAI"

  depends_on macos: :ventura

  # Nada pronto pra "instalar": o postflight compila o app e liga o CLI.
  stage_only true

  postflight do
    app_path = "#{appdir}/MyMailForAI.app"

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
               "espere terminar, e rode 'brew reinstall --cask mymailforai' de novo."
        end
        sleep 10
        waited += 10
      end
      ohai "Command Line Tools instaladas. Compilando o app…"
    else
      ohai "Command Line Tools encontradas. Compilando o app…"
    end

    source_dir = Dir.glob("#{staged_path}/MyMailForAI-*").first || staged_path.to_s

    # build_app.sh ja faz tudo: compila, gera o icone e embute o CLI em Python
    # dentro do bundle. Duplicar esses passos aqui seria manter dois roteiros.
    system_command "/bin/bash", args: ["#{source_dir}/mac/build_app.sh"], chdir: source_dir

    FileUtils.rm_rf(app_path)
    FileUtils.cp_r("#{source_dir}/mac/MyMailForAI.app", app_path)

    # O CLI mora dentro do app: uma instalacao so, e o app sempre conversa com
    # a mesma versao que o terminal.
    cli = "#{app_path}/Contents/Resources/mymailforai/bin/mymailforai"
    FileUtils.chmod 0755, cli
    FileUtils.mkdir_p HOMEBREW_PREFIX/"bin"
    FileUtils.ln_sf cli, HOMEBREW_PREFIX/"bin/mymailforai"

    system_command "/usr/bin/xattr", args: ["-cr", app_path]
    system_command "/usr/bin/codesign", args: ["--force", "--deep", "--sign", "-", app_path]

    ohai "Pronto. Rode 'mymailforai login voce@gmail.com' e abra o MyMailForAI."
  end

  # `uninstall` nao pode conviver com `stage_only`: o Homebrew recusa o cask
  # inteiro. O que o postflight criou sai por aqui.
  uninstall_postflight do
    FileUtils.rm_rf "#{appdir}/MyMailForAI.app"
    FileUtils.rm_f HOMEBREW_PREFIX/"bin/mymailforai"
  end

  zap trash: [
    "#{appdir}/MyMailForAI.app",
    "#{HOMEBREW_PREFIX}/bin/mymailforai",
    "~/.mymailforai",
    "~/Library/Preferences/dev.nspx.mymailforai.plist",
  ]

  caveats <<~EOS
    O MyMailForAI compila na sua maquina (leva ~30s) e nao guarda senha em arquivo:
    a senha de aplicativo vai pro Chaveiro do macOS.

    Proximo passo:
      mymailforai login voce@gmail.com

    O resto acontece no item da barra de menus: confirmar envio, trocar de modo,
    entrar com outro e-mail, sair, desinstalar.

    Pra apagar tambem a fila e o historico (~/.mymailforai):
      brew zap --cask mymailforai
  EOS
end
