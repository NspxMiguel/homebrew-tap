cask "nanobridge" do
  version "0.1.0"
  sha256 "22a6f309da7f2efb6b140c91c366e9fdc8cbb01879cd04f290bd0a90278f512e"

  # Mesmo padrao dos outros casks deste tap: baixa o CODIGO-FONTE e monta na
  # maquina de quem instala. Aqui nao ha binario pra compilar — o que se monta
  # e um virtualenv isolado, pra nao sujar o Python do sistema nem brigar com
  # outro pacote.
  url "https://github.com/NspxMiguel/NanoBridge/archive/refs/tags/v#{version}.tar.gz"
  name "NanoBridge"
  desc "Geracao de imagens do Nano Banana (Gemini) como CLI e servidor MCP"
  homepage "https://github.com/NspxMiguel/NanoBridge"

  depends_on macos: :monterey

  # Sem artefato pronto: o postflight monta o venv e publica o CLI no PATH.
  stage_only true

  postflight do
    source_dir = Dir.glob("#{staged_path}/NanoBridge-*").first || staged_path.to_s
    prefix = "#{HOMEBREW_PREFIX}/opt/nanobridge"
    venv = "#{prefix}/libexec"

    # Python 3.11+ e requisito duro: o codigo usa "str | None" em tempo de
    # execucao e sintaxe que 3.10 nao aceita.
    python = %w[python3.13 python3.12 python3.11 python3].find do |candidate|
      path = which(candidate)
      next false if path.nil?

      system_command(path.to_s,
                     args:         ["-c",
                                    "import sys; raise SystemExit(0 if sys.version_info[:2] >= (3, 11) else 1)"],
                     print_stderr: false).success?
    end

    if python.nil?
      odie "NanoBridge precisa de Python 3.11 ou mais novo. Instale com: brew install python@3.13"
    end

    ohai "Montando o ambiente do NanoBridge com #{python}…"
    FileUtils.rm_r(venv)
    FileUtils.mkdir_p(prefix)
    system_command which(python).to_s, args: ["-m", "venv", venv]
    system_command "#{venv}/bin/python", args: ["-m", "pip", "install", "--quiet", "--upgrade", "pip"]
    system_command "#{venv}/bin/python", args: ["-m", "pip", "install", "--quiet", source_dir]

    FileUtils.mkdir_p("#{HOMEBREW_PREFIX}/bin")
    FileUtils.ln_sf("#{venv}/bin/nanobridge", "#{HOMEBREW_PREFIX}/bin/nanobridge")

    # A skill do agente vive fora do venv: e um arquivo que o Claude Code le.
    skill_src = "#{source_dir}/skill/SKILL.md"
    if File.exist?(skill_src)
      skill_dir = "#{Dir.home}/.claude/skills/nanobanana"
      FileUtils.mkdir_p(skill_dir)
      FileUtils.cp(skill_src, "#{skill_dir}/SKILL.md")
    end

    # Registrar o servidor MCP e opcional: so acontece se o Claude Code existir.
    claude = which("claude")
    if claude
      system_command claude.to_s, args: ["mcp", "remove", "nanobridge", "--scope", "user"],
                                  print_stderr: false, must_succeed: false
      registered = system_command(claude.to_s,
                                  args: ["mcp", "add", "nanobridge", "--scope", "user", "--",
                                         "#{venv}/bin/nanobridge", "mcp"],
                                  print_stderr: false, must_succeed: false).success?
      ohai "Servidor MCP registrado no Claude Code." if registered
    end

    ohai "Pronto. Rode: nanobridge doctor"
  end

  uninstall_postflight do
    FileUtils.rm("#{HOMEBREW_PREFIX}/bin/nanobridge")
    FileUtils.rm_r("#{HOMEBREW_PREFIX}/opt/nanobridge")
  end

  zap trash: [
    "#{HOMEBREW_PREFIX}/opt/nanobridge",
    "~/.claude/skills/nanobanana",
    "~/.config/nanobridge",
  ]
end
