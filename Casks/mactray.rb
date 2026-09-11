cask "mactray" do
  version "1.3.1"
  sha256 "d03913a1075bb7d0bd735fe39536b1d4e2b99f1b7159c39a2f614bd941305360"

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
    # Assinatura ad-hoc muda o hash do binario a cada build, e o requisito designado do
    # app e esse hash: o macOS trata cada versao como um app diferente e joga fora a
    # permissao de Acessibilidade. Quem tem um certificado local assina com ele, o que
    # prende o requisito ao certificado e faz a permissao sobreviver as atualizacoes.
    # Quem nao tem — o caso normal de quem instala pelo tap — segue no ad-hoc.
    sign_keychain = Pathname.new(Dir.home)/"Library/Keychains/nspx-codesign.keychain-db"
    sign_id = "NSPX Local Code Signing"
    has_id = sign_keychain.exist? && system_command("/usr/bin/security",
                                                    args: ["find-identity", "-p", "codesigning",
                                                           sign_keychain.to_s],
                                                    print_stderr: false)
                                     .merged_output.include?(sign_id)
    signed_locally = false
    if has_id
      # must_succeed: false — sem isso o system_command lança exceção no primeiro
      # codesign que falhar, e o fallback ad-hoc logo abaixo nunca roda. A identidade
      # pode aparecer na listagem (has_id) e ainda assim ser recusada pelo codesign de
      # verdade — por exemplo, um chaveiro sem confiança marcada pra assinatura de
      # código — e foi exatamente isso que quebrou a instalação em 11/09/2026.
      result = system_command("/usr/bin/codesign",
                              args: ["--force", "--deep", "--sign", sign_id,
                                     "--keychain", sign_keychain.to_s, app_path],
                              print_stderr: false, must_succeed: false)
      signed_locally = result.success?
    end
    unless signed_locally
      system_command "/usr/bin/codesign", args: ["--force", "--deep", "--sign", "-", app_path]
    end

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
