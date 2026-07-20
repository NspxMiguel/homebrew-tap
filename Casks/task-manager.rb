cask "task-manager" do
  version "1.1.0"
  sha256 "f593d98651b03887e711401dba087617eaa5be165ba219fe5e7b4289e7232ad7"

  # Baixa o CODIGO-FONTE (nao um binario pronto) e compila na maquina de
  # quem instala. Build local = sem atributo de "quarantine" no binario
  # final = sem aviso de Gatekeeper, e sem precisar de Developer ID pago.
  url "https://github.com/spxmiguel/mac-task-manager/archive/refs/tags/v#{version}.tar.gz"
  name "Task Manager"
  desc "Gerenciador de tarefas nativo para macOS, estilo Windows 11 (compila na sua maquina)"
  homepage "https://github.com/spxmiguel/mac-task-manager"

  depends_on macos: :ventura

  # Nao tem artefato pronto pra "instalar" — o postflight abaixo cuida de
  # checar/instalar as Command Line Tools, compilar e colocar o app em
  # /Applications.
  stage_only true

  postflight do
    app_path = "#{appdir}/TaskManager.app"

    clt_installed = system_command("/usr/bin/xcode-select", args: ["-p"], print_stderr: false).success?

    unless clt_installed
      ohai "Command Line Tools do Xcode nao encontradas — baixando (necessario pra compilar)…"
      system_command "/usr/bin/xcode-select", args: ["--install"]

      ohai "Aguardando a instalacao terminar (clique em \"Instalar\" na janela que abriu)…"
      waited = 0
      timeout = 30 * 60 # 30 min
      until system_command("/usr/bin/xcode-select", args: ["-p"], print_stderr: false).success?
        if waited >= timeout
          odie "Tempo esgotado esperando as Command Line Tools instalarem. Rode 'xcode-select --install', espere terminar, e rode 'brew reinstall --cask task-manager' de novo."
        end
        sleep 10
        waited += 10
      end
      ohai "Command Line Tools instaladas. Compilando o app…"
    else
      ohai "Command Line Tools encontradas. Compilando o app…"
    end

    source_dir = Dir.glob("#{staged_path}/mac-task-manager-*").first || staged_path.to_s
    swift_bin = system_command("/usr/bin/xcrun", args: ["-f", "swift"], print_stderr: false).stdout.strip
    swift_bin = "swift" if swift_bin.empty?

    system_command swift_bin, args: ["build", "-c", "release", "--disable-sandbox"], chdir: source_dir

    FileUtils.rm_rf(app_path)
    FileUtils.mkdir_p("#{app_path}/Contents/MacOS")
    FileUtils.mkdir_p("#{app_path}/Contents/Resources")
    FileUtils.cp("#{source_dir}/.build/release/TaskManager", "#{app_path}/Contents/MacOS/TaskManager")
    FileUtils.cp("#{source_dir}/Resources/AppIcon.icns", "#{app_path}/Contents/Resources/AppIcon.icns")

    File.write("#{app_path}/Contents/Info.plist", <<~XML)
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
          <key>CFBundleExecutable</key>
          <string>TaskManager</string>
          <key>CFBundleIconFile</key>
          <string>AppIcon</string>
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

    system_command "/usr/bin/codesign", args: ["--force", "--deep", "-s", "-", app_path]

    ohai "Pronto! Task Manager compilado e instalado em #{app_path}"
  end

  zap trash: [
    "~/Library/Preferences/com.miguel.taskmanager.plist",
    "#{appdir}/TaskManager.app",
  ]
end
