cask "forgetray" do
  version "0.1.0"

  # Forge is a private repo, so a plain archive URL 404s for anyone without
  # an auth header attached. `using: :git` clones instead, going through
  # the system's normal git credential storage (already set up here via
  # `gh auth login` -> osxkeychain) rather than needing a token wired
  # through Homebrew separately. `revision:` pins the exact commit the tag
  # pointed at, so a moved tag can't silently change what gets installed.
  url "https://github.com/NspxMiguel/forge.git",
      using:    :git,
      tag:      "v#{version}",
      revision: "c662445c28e5c17ea9d65b222b9048416dba816e"
  name "ForgeTray"
  desc "Barra de menu para o setup de streaming do Forge (compila na sua maquina)"
  homepage "https://github.com/NspxMiguel/forge"

  depends_on macos: :ventura

  # Same reasoning as task-manager.rb: build from source on the installing
  # machine so the binary carries no quarantine flag, no Gatekeeper warning,
  # and no paid Developer ID certificate is needed.
  stage_only true

  postflight do
    app_path = "#{appdir}/ForgeTray.app"

    clt_installed = system_command("/usr/bin/xcode-select", args: ["-p"], print_stderr: false).success?

    unless clt_installed
      ohai "Command Line Tools do Xcode nao encontradas — baixando (necessario pra compilar)…"
      system_command "/usr/bin/xcode-select", args: ["--install"]

      ohai "Aguardando a instalacao terminar (clique em \"Instalar\" na janela que abriu)…"
      waited = 0
      timeout = 30 * 60 # 30 min
      until system_command("/usr/bin/xcode-select", args: ["-p"], print_stderr: false).success?
        if waited >= timeout
          odie "Tempo esgotado esperando as Command Line Tools instalarem. Rode 'xcode-select --install', espere terminar, e rode 'brew reinstall --cask forgetray' de novo."
        end
        sleep 10
        waited += 10
      end
      ohai "Command Line Tools instaladas. Compilando o app…"
    else
      ohai "Command Line Tools encontradas. Compilando o app…"
    end

    forge_root = Dir.glob("#{staged_path}/forge-*").first || staged_path.to_s
    source_dir = "#{forge_root}/mac/ForgeTray"
    swift_bin = system_command("/usr/bin/xcrun", args: ["-f", "swift"], print_stderr: false).stdout.strip
    swift_bin = "swift" if swift_bin.empty?

    system_command swift_bin, args: ["build", "-c", "release", "--disable-sandbox"], chdir: source_dir

    FileUtils.rm_rf(app_path)
    FileUtils.mkdir_p("#{app_path}/Contents/MacOS")
    FileUtils.mkdir_p("#{app_path}/Contents/Resources")
    FileUtils.cp("#{source_dir}/.build/release/ForgeTray", "#{app_path}/Contents/MacOS/ForgeTray")
    FileUtils.cp("#{source_dir}/Resources/AppIcon.icns", "#{app_path}/Contents/Resources/AppIcon.icns")

    File.write("#{app_path}/Contents/Info.plist", <<~XML)
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
          <key>CFBundleExecutable</key>
          <string>ForgeTray</string>
          <key>CFBundleIconFile</key>
          <string>AppIcon</string>
          <key>CFBundleIdentifier</key>
          <string>com.miguel.forgetray</string>
          <key>CFBundleName</key>
          <string>ForgeTray</string>
          <key>CFBundleDisplayName</key>
          <string>ForgeTray</string>
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
          <key>LSUIElement</key>
          <true/>
          <key>NSHighResolutionCapable</key>
          <true/>
      </dict>
      </plist>
    XML

    # Files copied out of the downloaded tarball (the .icns, here) can carry
    # a quarantine attribute even after being copied into the built bundle -
    # clear everything before signing.
    system_command "/usr/bin/xattr", args: ["-cr", app_path]
    system_command "/usr/bin/codesign", args: ["--force", "--deep", "-s", "-", app_path]

    ohai "Pronto! ForgeTray compilado e instalado em #{app_path}"
  end

  zap trash: [
    "#{appdir}/ForgeTray.app",
  ]
end
