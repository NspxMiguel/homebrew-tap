cask "scrollback" do
  version "1.0.0"
  sha256 "7630823d2f9be9479b7679196da19f543d3616d2e83ab315ba2998cfba9a7bef"

  # Downloads the SOURCE CODE and compiles it on the installing machine. A
  # local build carries no quarantine attribute, so Gatekeeper never
  # complains — no paid Developer ID needed.
  url "https://github.com/NspxMiguel/ScrollBack/archive/refs/tags/v#{version}.tar.gz"
  name "ScrollBack"
  desc "Reverses mouse scroll (not trackpad) and revives side buttons macOS drops"
  homepage "https://github.com/NspxMiguel/ScrollBack"

  depends_on macos: :sonoma

  stage_only true

  postflight do
    app_path = "#{appdir}/ScrollBack.app"

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
               "wait for it to finish, then run 'brew reinstall --cask scrollback' again."
        end
        sleep 10
        waited += 10
      end
      ohai "Command Line Tools installed. Building the app…"
    else
      ohai "Command Line Tools found. Building the app…"
    end

    source_dir = Dir.glob("#{staged_path}/ScrollBack-*").first || staged_path.to_s

    # build.sh already compiles universal, draws the icon and assembles
    # Info.plist — duplicating those steps here would just be a second
    # script to keep in sync with the same thing.
    system_command "/bin/bash", args: ["#{source_dir}/build.sh"], chdir: source_dir

    FileUtils.rm_rf(app_path)
    FileUtils.cp_r("#{source_dir}/build/ScrollBack.app", app_path)

    # A file copied out of the tarball (the icon, for instance) can arrive
    # quarantined — clear the whole bundle before signing it.
    system_command "/usr/bin/xattr", args: ["-cr", app_path]

    # Ad-hoc signing changes the binary's hash on every build, and that hash
    # is the app's designated requirement: macOS treats each version as a
    # different app and throws away the Accessibility grant. Whoever has a
    # local certificate signs with it instead, pinning the requirement to
    # the certificate — which doesn't change — so the permission survives
    # updates. Whoever installs through the tap (the normal case) stays on
    # ad-hoc.
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
                              print_stderr: false, must_succeed: false)
      signed_locally = result.success?
    end
    unless signed_locally
      system_command "/usr/bin/codesign", args: ["--force", "--deep", "--sign", "-", app_path]
    end

    ohai "Done! ScrollBack installed at #{app_path}. Open it and grant Accessibility."
  end

  uninstall_postflight do
    FileUtils.rm_rf "#{appdir}/ScrollBack.app"
  end

  zap trash: [
    "#{appdir}/ScrollBack.app",
    "~/Library/Preferences/dev.nspx.ScrollBack.plist",
    "~/Library/Logs/ScrollBack.log",
  ]

  caveats <<~EOS
    ScrollBack compiles on your machine (~1 min) and lives in the menu bar.

    On first launch it asks for Accessibility permission — without it, it
    can't see scroll or mouse button events at all.
  EOS
end
