cask "ipod-music-helper" do
  version "0.1.0"
  sha256 "48d750d7af88ec3a9f29ecb5a96f5c59487559a75a500bd8fb7588a22933b7ea"

  # Downloads the SOURCE CODE and compiles it on the installing machine. A
  # local build carries no quarantine attribute, so Gatekeeper never
  # complains — no paid Developer ID needed.
  url "https://github.com/NspxMiguel/iPodMusicHelper/archive/refs/tags/v#{version}.tar.gz"
  name "iPod Music Helper"
  desc "Puts the music you own on an iPod, organized by your streaming playlists"
  homepage "https://github.com/NspxMiguel/iPodMusicHelper"

  depends_on macos: :sonoma
  # Every read and write of audio goes through ffmpeg and ffprobe.
  depends_on formula: "ffmpeg"

  stage_only true

  postflight do
    app_path = "#{appdir}/iPod Music Helper.app"

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
               "wait for it to finish, then run 'brew reinstall --cask ipod-music-helper' again."
        end
        sleep 10
        waited += 10
      end
      ohai "Command Line Tools installed. Building the app…"
    else
      ohai "Command Line Tools found. Building the app…"
    end

    source_dir = Dir.glob("#{staged_path}/iPodMusicHelper-*").first || staged_path.to_s

    # build.sh compiles universal, draws the icon, assembles Info.plist, puts
    # the CLI in Contents/Helpers and signs (local certificate or ad-hoc).
    system_command "/bin/bash", args: ["#{source_dir}/build.sh"], chdir: source_dir

    FileUtils.rm_rf(app_path)
    FileUtils.cp_r("#{source_dir}/build/iPod Music Helper.app", app_path)

    # A file copied out of the tarball can arrive quarantined; clearing xattrs
    # does not touch the signature build.sh already applied.
    system_command "/usr/bin/xattr", args: ["-cr", app_path]

    # One install: the terminal and the app always run the same version.
    cli = "#{app_path}/Contents/Helpers/ipod-helper"
    FileUtils.mkdir_p HOMEBREW_PREFIX/"bin"
    FileUtils.ln_sf cli, HOMEBREW_PREFIX/"bin/ipod-helper"

    ohai "Done! iPod Music Helper installed at #{app_path} and `ipod-helper` linked into #{HOMEBREW_PREFIX}/bin."
  end

  uninstall_postflight do
    FileUtils.rm_rf "#{appdir}/iPod Music Helper.app"
    FileUtils.rm_f HOMEBREW_PREFIX/"bin/ipod-helper"
  end

  zap trash: [
    "#{appdir}/iPod Music Helper.app",
    "#{HOMEBREW_PREFIX}/bin/ipod-helper",
    "~/Library/Application Support/iPod Music Helper",
    "~/Library/Caches/com.ipodmusichelper.app",
    "~/Library/Preferences/com.ipodmusichelper.app.plist",
  ]

  caveats <<~EOS
    iPod Music Helper compiles on your Mac (~1 min).

    It never downloads or decrypts streaming audio: your accounts give the
    list of songs, and the audio comes from files you already have.

    Rockbox iPods are written directly (FAT32). iPods with Apple firmware are
    prepared in ~/Music/iPod Music Helper and synced from Finder.

    The Spotify refresh token stays in the macOS keychain;
    `brew uninstall --zap --cask ipod-music-helper` does not remove it —
    delete the "com.ipodmusichelper.app.spotify" item in Keychain Access.
  EOS
end
