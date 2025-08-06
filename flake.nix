{
  description = "A simple NixOS flake for Hetzner Cloud server with Bonfire";

  inputs = {
    # NixOS official package source, using the nixos-25.05 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    bonfire-nix.url = "github:bonfire-networks/bonfire-nix/main"; # Or a specific tag/commit
    flake-utils.url = "github:numtide/flake-utils";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
  };

  outputs = { self, nixpkgs, bonfire-nix, flake-utils, sops-nix,
              disko, nixos-facter-modules, ... }@inputs: {
      nixosConfigurations.nixos-vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix # Your main configuration.nix
          ./hardware-configuration.nix # Add other modules here if you have them, e.g., hardware-configuration.nix
          sops-nix.nixosModules.sops
          bonfire-nix.nixosModules.bonfire
          disko.nixosModules.disko
        ];
      };
    };
}
