cask "mactray" do
  version "1.1.3"
  sha256 "7d13f8086eeaf0ca39db3599e2e0e51583739732fd54963e4066786708f82613"

  # Baixa o CODIGO-FONTE e compila na maquina de quem instala. Build local =
  # sem atributo de quarentena no binario final = sem aviso de Gatekeeper, e
  # sem precisar de Developer ID pago.
  url "https://github.com/NspxMiguel/MacTray/archive/refs/tags/v#{version}.tar.gz"
  name "MacTray"
  desc "Esconde os icones que nao cabem na barra de menus"
  homepage "https://github.com/NspxMiguel/MacTray"

  depends_on macos: :sonoma

  # Nada pronto pra "instalar": o postflight compila e monta o bundle.
  stage_only true

  postflight do
    app_path = "#{appdir}/MacTray.app"

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
               "espere terminar, e rode 'brew reinstall --cask mactray' de novo."
        end
        sleep 10
        waited += 10
      end
      ohai "Command Line Tools instaladas. Compilando o app…"
    else
      ohai "Command Line Tools encontradas. Compilando o app…"
    end

    source_dir = Dir.glob("#{staged_path}/MacTray-*").first || staged_path.to_s

    # build.sh ja compila universal, desenha o icone e monta o Info.plist.
    # Duplicar esses passos aqui seria manter dois roteiros da mesma coisa.
    system_command "/bin/bash", args: ["#{source_dir}/build.sh"], chdir: source_dir

    FileUtils.rm_rf(app_path)
    FileUtils.cp_r("#{source_dir}/build/MacTray.app", app_path)

    # Arquivo copiado do tarball (o icone, por exemplo) pode chegar marcado —
    # limpa o bundle inteiro antes de assinar.
    system_command "/usr/bin/xattr", args: ["-cr", app_path]
    system_command "/usr/bin/codesign", args: ["--force", "--deep", "--sign", "-", app_path]

    ohai "Pronto! MacTray instalado em #{app_path}. Abra o app e libere a Acessibilidade."
  end

  # `uninstall` nao pode conviver com `stage_only`: o Homebrew recusa o cask.
  uninstall_postflight do
    FileUtils.rm_rf "#{appdir}/MacTray.app"
  end

  zap trash: [
    "#{appdir}/MacTray.app",
    "~/Library/Preferences/dev.nspx.MacTray.plist",
  ]

  caveats <<~EOS
    O MacTray compila na sua maquina (leva ~1 min) e roda so na barra de menus.

    Na primeira abertura ele pede permissao de Acessibilidade — sem isso os
    icones nao se movem.
  EOS
end
