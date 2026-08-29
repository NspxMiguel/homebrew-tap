cask "nanobridge" do
  version "0.8.0"
  sha256 "217a19b3e26020dbb64450fbc4cb7eb0144bc906732228a43ce13aa769d613bf"

  # Mesmo padrao dos outros casks deste tap: baixa o CODIGO-FONTE e monta na
  # maquina de quem instala. Aqui nao ha binario pra compilar — o que se monta
  # e um virtualenv isolado, pra nao sujar o Python do sistema nem brigar com
  # outro pacote.
  url "https://github.com/NspxMiguel/NanoBridge/archive/refs/tags/v#{version}.tar.gz"
  name "NanoBridge"
  desc "Geracao de imagens do Nano Banana (Gemini) como CLI e servidor MCP"
  homepage "https://github.com/NspxMiguel/NanoBridge"

  depends_on formula: "python@3.13"
  depends_on macos: :monterey

  # Sem artefato pronto: o postflight monta o venv e publica o CLI no PATH.
  stage_only true

  postflight do
    source_dir = Dir.glob("#{staged_path}/NanoBridge-*").first || staged_path.to_s
    prefix = "#{HOMEBREW_PREFIX}/opt/nanobridge"
    venv = "#{prefix}/libexec"

    # Python vem do proprio Homebrew (depends_on acima), nao do sistema: o
    # /usr/bin/python3 do macOS ainda e 3.9 e o codigo pede 3.11+.
    python = "#{HOMEBREW_PREFIX}/opt/python@3.13/bin/python3.13"
    odie "NanoBridge precisa de python@3.13 (brew install python@3.13)" unless File.executable?(python)

    ohai "Montando o ambiente do NanoBridge…"
    FileUtils.rm_r(venv) if File.exist?(venv)
    FileUtils.mkdir_p(prefix)
    system_command python, args: ["-m", "venv", venv]
    system_command "#{venv}/bin/python", args: ["-m", "pip", "install", "--quiet", "--upgrade", "pip"]
    # Com o extra [3d]: quem instala pelo cask quer a ferramenta inteira, e
    # mesh/turntable/sprite3d dependem de NumPy, trimesh e gradio_client.
    system_command "#{venv}/bin/python", args: ["-m", "pip", "install", "--quiet", "#{source_dir}[3d]"]

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
    # O PATH do postflight e enxuto, entao os lugares habituais entram na busca
    # a mao — sem isso a instalacao termina "limpa" sem ter registrado nada.
    claude = [
      which("claude"),
      "#{Dir.home}/.local/bin/claude",
      "#{Dir.home}/.claude/local/claude",
      "#{HOMEBREW_PREFIX}/bin/claude",
      "/usr/local/bin/claude",
    ].compact.map(&:to_s).find { |candidate| File.executable?(candidate) }

    if claude
      system_command claude.to_s, args: ["mcp", "remove", "nanobridge", "--scope", "user"],
                                  print_stderr: false, must_succeed: false
      registered = system_command(claude.to_s,
                                  args: ["mcp", "add", "nanobridge", "--scope", "user", "--",
                                         "#{venv}/bin/nanobridge", "mcp"],
                                  print_stderr: false, must_succeed: false).success?
      if registered
        ohai "Servidor MCP registrado no Claude Code."
      else
        opoo "Nao consegui registrar o MCP. Rode:"
        opoo "  claude mcp add nanobridge --scope user -- #{venv}/bin/nanobridge mcp"
      end
    else
      opoo "Claude Code nao encontrado. Para registrar o MCP depois, rode:"
      opoo "  claude mcp add nanobridge --scope user -- #{venv}/bin/nanobridge mcp"
    end

    ohai "Pronto. Rode: nanobridge doctor"
  end

  uninstall_postflight do
    link = "#{HOMEBREW_PREFIX}/bin/nanobridge"
    FileUtils.rm(link) if File.symlink?(link) || File.exist?(link)
    prefix = "#{HOMEBREW_PREFIX}/opt/nanobridge"
    FileUtils.rm_r(prefix) if File.exist?(prefix)

    # Registro de MCP apontando pro que acabou de sumir nao e resto inofensivo:
    # o Claude Code tenta subir o servidor toda sessao e mostra "Failed to
    # connect" para sempre. Quem registrou desregistra.
    claude = [
      which("claude"),
      "#{Dir.home}/.local/bin/claude",
      "#{Dir.home}/.claude/local/claude",
      "#{HOMEBREW_PREFIX}/bin/claude",
      "/usr/local/bin/claude",
    ].compact.map(&:to_s).find { |candidate| File.executable?(candidate) }

    if claude
      # `ohai` e as outras ajudantes de saida do Homebrew nao existem dentro de
      # uninstall_postflight: chamar uma delas levanta NoMethodError no meio da
      # desinstalacao, que para depois de ja ter apagado o binario e antes de
      # limpar o Caskroom — e o brew passa a achar que ainda esta instalado.
      removed = system_command(claude.to_s,
                               args: ["mcp", "remove", "nanobridge", "--scope", "user"],
                               print_stderr: false, must_succeed: false).success?
      puts "==> Servidor MCP desregistrado do Claude Code." if removed
    end
  end

  zap trash: [
    "#{HOMEBREW_PREFIX}/opt/nanobridge",
    "~/.claude/skills/nanobanana",
    "~/.config/nanobridge",
  ]
end
