{
  description = "My dotfiles and setup";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }: 
  let
    system = "aarch64-darwin";  # or "x86_64-linux"
    username = "jimmyfraiture";
    homeDirectory = "/Users/${username}";
  in {
    homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${system};

      modules = [ ./home.nix ];

      extraSpecialArgs = {
        inherit username homeDirectory;
      };
    };
  };
}
