cask "recap" do
  version "1.0.0"
  sha256 "39a66f9129893cb4ba8be55f95b7a9c4c56ef4ee2a4993e137e4ae31d07a9144"

  # Baixa o CODIGO-FONTE e compila na maquina de quem instala. Build local =
  # sem atributo de quarentena no binario final = sem aviso de Gatekeeper, e
  # sem precisar de Developer ID pago.
  url "https://github.com/NspxMiguel/Recap/archive/refs/tags/v#{version}.tar.gz"
  name "Recap"
  desc "Grava reunioes (microfone + audio do sistema) e resume com IA"
  homepage "https://github.com/NspxMiguel/Recap"

  depends_on macos: :sequoia

  # Nada pronto pra "instalar": o postflight compila e monta o bundle.
  stage_only true

  postflight do
    app_path = "#{appdir}/Recap.app"

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
               "espere terminar, e rode 'brew reinstall --cask recap' de novo."
        end
        sleep 10
        waited += 10
      end
      ohai "Command Line Tools instaladas. Compilando o app…"
    else
      ohai "Command Line Tools encontradas. Compilando o app…"
    end

    source_dir = Dir.glob("#{staged_path}/Recap-*").first || staged_path.to_s

    # build.sh ja compila universal, desenha o icone e monta o Info.plist.
    # Duplicar esses passos aqui seria manter dois roteiros da mesma coisa.
    system_command "/bin/bash", args: ["#{source_dir}/build.sh"], chdir: source_dir

    FileUtils.rm_rf(app_path)
    FileUtils.cp_r("#{source_dir}/build/Recap.app", app_path)

    # Arquivo copiado do tarball (o icone, por exemplo) pode chegar marcado —
    # limpa o bundle inteiro antes de assinar.
    system_command "/usr/bin/xattr", args: ["-cr", app_path]
    # Assinatura ad-hoc muda o hash do binario a cada build, e o requisito designado do
    # app e esse hash: o macOS trata cada versao como um app diferente e joga fora as
    # permissoes de gravacao de tela/audio do sistema e de microfone. Quem tem um
    # certificado local assina com ele, o que prende o requisito ao certificado e faz a
    # permissao sobreviver as atualizacoes. Quem nao tem — o caso normal de quem instala
    # pelo tap — segue no ad-hoc, e reautoriza a cada versao nova.
    sign_keychain = Pathname.new(Dir.home)/"Library/Keychains/nspx-codesign.keychain-db"
    sign_id = "NSPX Local Code Signing"
    has_id = sign_keychain.exist? && system_command("/usr/bin/security",
                                                    args: ["find-identity", "-p", "codesigning",
                                                           sign_keychain.to_s],
                                                    print_stderr: false)
                                     .merged_output.include?(sign_id)
    signed_locally = false
    if has_id
      result = system_command("/usr/bin/codesign",
                              args: ["--force", "--deep", "--sign", sign_id,
                                     "--keychain", sign_keychain.to_s, app_path],
                              print_stderr: false)
      signed_locally = result.success?
    end
    unless signed_locally
      system_command "/usr/bin/codesign", args: ["--force", "--deep", "--sign", "-", app_path]
    end

    ohai "Pronto! Recap instalado em #{app_path}."
    ohai "Abra o app, clique no icone de onda sonora na barra de menus, e autorize " \
         "gravacao de tela/audio do sistema e microfone na primeira reuniao."
  end

  # `uninstall` nao pode conviver com `stage_only`: o Homebrew recusa o cask inteiro.
  uninstall_postflight do
    FileUtils.rm_rf "#{appdir}/Recap.app"
  end

  zap trash: [
    "#{appdir}/Recap.app",
    "~/Library/Preferences/com.recap.app.plist",
    "~/Library/Application Support/Recap",
  ]

  caveats <<~EOS
    O Recap compila na sua maquina (leva ~1 min) e roda so na barra de menus.

    Precisa do macOS 15 (Sequoia) ou mais novo, e de uma chave de API gratuita
    da Groq (console.groq.com/keys) — configure nas Preferencias do app.

    Na primeira gravacao ele pede permissao de gravacao de tela/audio do
    sistema e de microfone — sem isso nao ha reuniao pra ouvir.
  EOS
end
