cask "ebb" do
  version "1.0.0"
  sha256 "cad2e2123ab3cb495c3d6b9dfbf4528bb83bf6078e4053e4bf84c4a8dce8e928"

  # Downloads the SOURCE CODE and compiles it on the installing machine. A
  # local build carries no quarantine attribute, so Gatekeeper never
  # complains — no paid Developer ID needed.
  url "https://github.com/NspxMiguel/Ebb/archive/refs/tags/v#{version}.tar.gz"
  name "Ebb"
  desc "Deletes old email over IMAP so the mailbox never fills up"
  homepage "https://github.com/NspxMiguel/Ebb"

  depends_on macos: :sonoma

  stage_only true

  postflight do
    app_path = "#{appdir}/Ebb.app"

    clt_installed = system_command("/usr/bin/xcode-select", args: ["-p"], print_stderr: false).success?

    unless clt_installed
      ohai "Xcode Command Line Tools not found — installing (needed to compile)…"
      system_command "/usr/bin/xcode-select", args: ["--install"]

      ohai "Waiting for the install to finish (click \"Install\" in the window that opened)…"
      waited = 0
      timeout = 30 * 60
      until system_command("/usr/bin/xcode-select", args: ["-p"], print_stderr: false).success?
        if waited >= timeout
          odie "Timed out waiting for the Command Line Tools. Run 'xcode-select --install', " \
               "wait for it to finish, then run 'brew reinstall --cask ebb' again."
        end
        sleep 10
        waited += 10
      end
      ohai "Command Line Tools installed. Building the app…"
    else
      ohai "Command Line Tools found. Building the app…"
    end

    source_dir = Dir.glob("#{staged_path}/Ebb-*").first || staged_path.to_s

    # build.sh compiles universal, draws the icon, assembles Info.plist, puts
    # the CLI in Contents/Helpers and signs (local certificate or ad-hoc).
    system_command "/bin/bash", args: ["#{source_dir}/build.sh"], chdir: source_dir

    FileUtils.rm_rf(app_path)
    FileUtils.cp_r("#{source_dir}/build/Ebb.app", app_path)

    # A file copied out of the tarball can arrive quarantined; clearing xattrs
    # does not touch the signature build.sh already applied.
    system_command "/usr/bin/xattr", args: ["-cr", app_path]

    # One install: the terminal and the app always run the same version.
    cli = "#{app_path}/Contents/Helpers/ebb"
    FileUtils.mkdir_p HOMEBREW_PREFIX/"bin"
    FileUtils.ln_sf cli, HOMEBREW_PREFIX/"bin/ebb"

    ohai "Done! Ebb installed at #{app_path} and `ebb` linked into #{HOMEBREW_PREFIX}/bin."
  end

  uninstall_postflight do
    FileUtils.rm_rf "#{appdir}/Ebb.app"
    FileUtils.rm_f HOMEBREW_PREFIX/"bin/ebb"
  end

  zap trash: [
    "#{appdir}/Ebb.app",
    "#{HOMEBREW_PREFIX}/bin/ebb",
    "~/Library/Application Support/Ebb",
    "~/Library/Preferences/com.ebb.app.plist",
  ]

  caveats <<~EOS
    Ebb compiles on your machine (~1 min) and lives in the menu bar.

    It deletes email for good. Add an account with an app password
    (Gmail: myaccount.google.com/apppasswords, iCloud: account.apple.com),
    then preview with `ebb scan` before the first cleanup.

    App passwords stay in the macOS keychain; `brew uninstall --zap --cask ebb`
    does not remove them — delete the "com.ebb.app" items in Keychain Access.
  EOS
end
