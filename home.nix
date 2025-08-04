{ config, pkgs, username, homeDirectory, ... }: {
  home.username = username;
  home.homeDirectory = homeDirectory;

  home.packages = with pkgs; [
    zsh
    kubectl
    git

    (writeShellScriptBin "nixm" ''
      #!/usr/bin/env bash

      if [ -z "$1" ]; then
        echo "Usage: nixm <module-name>"
        echo "Available modules: $(ls -1 $HOME/dotfiles/modules | sed 's/-flake.nix$//' | tr '\n' ' ')"
        exit 1
      fi

      MODULE_NAME="$1"
      MODULE_PATH="$HOME/dotfiles/modules/$MODULE_NAME-flake"

      nix develop "path:$MODULE_PATH" --extra-experimental-features "nix-command flakes"
    '')
  ];

  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "tonotdo";
      plugins = [ "git" ];
    };
    shellAliases = {
      cls = "clear";
      k = "kubectl";
    };
    initContent = ''
      export ANDROID_SDK_ROOT=${homeDirectory}/Library/Android/sdk
      export PATH="${homeDirectory}/dev/flutter/bin:$PATH"
      export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
      export PATH="$PATH:${homeDirectory}/.pub-cache/bin"
      export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
      export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"
      export LANG=en_US.UTF-8
      export PATH="${homeDirectory}/.cargo/bin:$PATH"
    '';
  };

  home.stateVersion = "24.05";
  programs.home-manager.enable = true;

  home.file.".config/nix/nix.conf".text = ''
    experimental-features = nix-command flakes
  '';
}
