class TaskManager < Formula
  desc "Gerenciador de tarefas nativo para macOS, estilo Windows 11"
  homepage "https://github.com/spxmiguel/mac-task-manager"
  url "https://github.com/spxmiguel/mac-task-manager/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "c1f843321f87caa19b37bef3d0dbb862b8b0b3b37bba031ae4740f6b69ee135f"
  license "MIT"

  depends_on macos: :ventura

  # Compilado localmente na maquina do usuario (via Command Line Tools,
  # gratuitas, sem precisar de licenca do Xcode) em vez de baixar um binario
  # pronto. Isso evita o aviso do Gatekeeper de "app malicioso/desenvolvedor
  # nao identificado" que aparece em apps ad-hoc-assinados baixados prontos
  # da internet (o atributo de quarantine so e' aplicado a arquivos baixados,
  # nao ao binario gerado localmente pelo compilador).
  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"

    app = prefix/"TaskManager.app"
    (app/"Contents/MacOS").mkpath
    (app/"Contents/Resources").mkpath
    cp ".build/release/TaskManager", app/"Contents/MacOS/TaskManager"

    (app/"Contents/Info.plist").write <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
          <key>CFBundleExecutable</key>
          <string>TaskManager</string>
          <key>CFBundleIdentifier</key>
          <string>com.miguel.taskmanager</string>
          <key>CFBundleName</key>
          <string>Gerenciador de Tarefas</string>
          <key>CFBundleDisplayName</key>
          <string>Gerenciador de Tarefas</string>
          <key>CFBundlePackageType</key>
          <string>APPL</string>
          <key>CFBundleShortVersionString</key>
          <string>#{version}</string>
          <key>CFBundleVersion</key>
          <string>1</string>
          <key>LSMinimumSystemVersion</key>
          <string>13.0</string>
          <key>LSApplicationCategoryType</key>
          <string>public.app-category.utilities</string>
          <key>NSHighResolutionCapable</key>
          <true/>
      </dict>
      </plist>
    XML
  end

  def post_install
    target = Pathname.new("/Applications/TaskManager.app")
    target.rmtree if target.exist?
    system "cp", "-R", "#{opt_prefix}/TaskManager.app", "/Applications/"
    system "xattr", "-dr", "com.apple.quarantine", target.to_s
    system "codesign", "--force", "--deep", "-s", "-", target.to_s
  end

  def caveats
    <<~EOS
      TaskManager.app foi compilado localmente e copiado para /Applications
      (build local = sem aviso de "desenvolvedor nao identificado" do Gatekeeper).

      Abra pelo Spotlight ou:
        open /Applications/TaskManager.app

      Atalho padrao para abrir/fechar: Cmd+Esc (configuravel dentro do app, aba Ajustes).
    EOS
  end

  test do
    assert_predicate prefix/"TaskManager.app/Contents/MacOS/TaskManager", :exist?
  end
end
