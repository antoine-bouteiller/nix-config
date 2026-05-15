{
  config,
  globals,
  lib,
  ...
}: let
  signingKeyPath = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
  allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
in {
  home.activation.gitAllowedSigners = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -f ${lib.escapeShellArg signingKeyPath} ]; then
      mkdir -p ${lib.escapeShellArg (dirOf allowedSignersFile)}
      printf '%s namespaces="git" %s\n' ${lib.escapeShellArg globals.email} "$(cat ${lib.escapeShellArg signingKeyPath})" > ${lib.escapeShellArg allowedSignersFile}
    fi
  '';

  programs.git = {
    enable = true;
    ignores = [
      # Editor
      "*.swp"
      "*~"
      ".vscode/"
      ".idea/"
      ".zed/"

      # OS
      ".DS_Store"
      "Thumbs.db"

      # Nix
      "result"
      "result-*"

      # Direnv
      ".direnv/"

      # Node
      "node_modules/"

      # Claude
      ".claude/settings.local.json"
    ];
    lfs = {
      enable = true;
    };
    settings = {
      user = {
        name = globals.name;
        email = lib.mkDefault globals.email;
      };
      init.defaultBranch = "main";
      core = {
        editor = "vim";
        autocrlf = "input";
      };
      pull.rebase = true;
      push.autoSetupRemote = true;
      rebase.autoStash = true;
      commit.gpgsign = true;
      tag.gpgsign = true;
      gpg.format = "ssh";
      gpg.ssh.allowedSignersFile = allowedSignersFile;
      user.signingkey = signingKeyPath;
    };
  };

  programs.zsh.shellAliases = {
    # --- The Basics ---
    g = "git";
    gst = "git status";
    gd = "git diff";
    ga = "git add";
    gaa = "git add --all";

    # --- Commits (The 'gc' family) ---
    gc = "git commit -v";
    "gc!" = "git commit -v --amend";
    gca = "git commit -v -a";
    "gca!" = "git commit -v -a --amend";
    "gcan!" = "git commit -v -a --no-edit --amend";
    gcam = "git commit -a -m";
    "gcam!" = "git commit -a --amend";
    gcmsg = "git commit -m";

    # --- Branches & Checkout ---
    gb = "git branch";
    gco = "git checkout";
    gcb = "git checkout -b";

    # --- Push & Pull ---
    gp = "git push";
    gpf = "git push --force-with-lease";
    "gpf!" = "git push --force";
    gl = "git pull";
    gpr = "git pull --rebase";
    gpra = "git pull --rebase --autostash";

    # --- Logs ---
    glo = "git log --oneline --decorate";
    glg = "git log --stat";
    glog = "git log --oneline --decorate --graph";
  };
}
