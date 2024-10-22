{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  inputs.nix-darwin.url = "github:LnL7/nix-darwin";
  inputs.nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];
    perSystem = { pkgs, ... }: {
      packages.deploy-macos = pkgs.writeShellApplication {
        name = "deploy-macos";
        text = ''
          nix copy --to ssh-ng://enzime@hermes-macos-aarch64-darwin-vm ${./.}
          ssh -t enzime@hermes-macos-aarch64-darwin-vm darwin-rebuild switch --flake ${./.}
        '';
      };
    };
    flake = {
      darwinConfigurations.hermes-macos-aarch64-darwin-vm = inputs.nix-darwin.lib.darwinSystem {
        modules = [
          ({ pkgs, ... }:

          {
            networking.hostName = "hermes-macos-aarch64-darwin-vm";
            nixpkgs.hostPlatform = "aarch64-darwin";

            services.nix-daemon.enable = true;
            nix.settings.experimental-features = "nix-command flakes";

            programs.zsh.enable = true;

            system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
            system.stateVersion = 5;

            services.tailscale.enable = true;

            users.users.enzime.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINKZfejb9htpSB5K9p0RuEowErkba2BMKaze93ZVkQIE" ];
          })
        ];
      };
    };
  };
}
