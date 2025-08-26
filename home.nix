{ config, pkgs, username, homeDirectory, ... }: {
  home.username = username;
  home.homeDirectory = homeDirectory;

  home.packages = with pkgs; [
    zsh
    kubectl
    git
    tmux

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
      l = "ls -la";
    };
    initContent = ''
      export ANDROID_SDK_ROOT=${homeDirectory}/Library/Android/sdk
      export PATH="${homeDirectory}/dev/flutter/bin:$PATH"
      export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
      export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
      export PATH="$PATH:${homeDirectory}/.pub-cache/bin"
      export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
      export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"
      export LANG=en_US.UTF-8
      export PATH="${homeDirectory}/.cargo/bin:$PATH"
      # 1Password CLI integration for secrets
      # Set OPENAI_API_KEY from 1Password if available.
      # Defaults to vault "Secret Manager", item "OpenAI", field "token".
      if command -v op >/dev/null 2>&1; then
        # Allow override, else use default path
        if [ -z "$OPENAI_1P_SECRET" ]; then
          OPENAI_1P_SECRET='op://Secret Manager/OpenAI/token'
        fi
        OPENAI_FROM_1P=$(op read "$OPENAI_1P_SECRET" 2>/dev/null || true)
        if [ -n "$OPENAI_FROM_1P" ]; then
          export OPENAI_API_KEY="$OPENAI_FROM_1P"
        fi
        unset OPENAI_FROM_1P
      fi
    '';
    # Also run the 1Password secret export in login shells to ensure early availability
    loginExtra = ''
      if command -v op >/dev/null 2>&1; then
        if [ -z "$OPENAI_1P_SECRET" ]; then
          OPENAI_1P_SECRET='op://Secret Manager/OpenAI/token'
        fi
        OPENAI_FROM_1P=$(op read "$OPENAI_1P_SECRET" 2>/dev/null || true)
        if [ -n "$OPENAI_FROM_1P" ]; then
          export OPENAI_API_KEY="$OPENAI_FROM_1P"
        fi
        unset OPENAI_FROM_1P
      fi
    '';
  };
  programs.tmux = {
    enable = true;
    terminal = "xterm-256color";
    historyLimit = 10000;
    keyMode = "vi"; # Use vi key bindings
    extraConfig = ''
      set -g mouse on
      bind | split-window -h
      bind - split-window -v
      unbind '"'
      unbind %
      bind r source-file ~/.tmux.conf \; display "Reloaded!"
    '';
  };

  home.stateVersion = "24.05";
  programs.home-manager.enable = true;

  home.file.".config/nix/nix.conf".text = ''
    experimental-features = nix-command flakes
  '';
}
