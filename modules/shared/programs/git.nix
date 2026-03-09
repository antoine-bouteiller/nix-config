{
  globals,
  lib,
  ...
}: {
  programs.git = {
    enable = true;
    ignores = ["*.swp"];
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
    };
  };
}
