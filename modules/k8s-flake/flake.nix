{
  description = "Kubernetes dev environment";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }: {
    devShells.aarch64-darwin.default = nixpkgs.legacyPackages.aarch64-darwin.mkShell {
      buildInputs = with nixpkgs.legacyPackages.aarch64-darwin; [
        zsh  # Add zsh explicitly
        kubectl
        k9s
        kubernetes-helm
      ];
      shellHook = ''
        echo "Entering K8s shell..."
        alias k="kubectl"
        alias kgp="kubectl get pods"
        alias kgs="kubectl get services"
        alias kctx="kubectl config use-context"
        alias k9="k9s"
        alias h="helm"
        exec zsh  # Switch to zsh
      '';
    };
  };
}