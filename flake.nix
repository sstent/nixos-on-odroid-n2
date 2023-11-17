{
  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    #nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  };

  outputs = { nixpkgs, ... }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
    };
    lib = nixpkgs.lib;

  

  in rec {
    devShell.${system} = pkgs.mkShell {
      buildInputs = with pkgs; [
        rsync
        zstd
      ];
    };

    nixosConfigurations.m1 = lib.nixosSystem {
      system = "aarch64-linux";

      modules = [
        {
          imports = [
            #./sd-image.nix
            ./default.nix
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-installer.nix"

          ];

          sdImage = {
            compressImage = false;
            populateFirmwareCommands = let
              configTxt = pkgs.writeText "README" ''
              Nothing to see here. This empty partition is here because I don't know how to turn its creation off.
              '';
            in ''
              cp ${configTxt} firmware/README
            '';
            populateRootCommands = ''
              ${config.boot.loader.kboot-conf.populateCmd} -c ${config.system.build.toplevel} -d ./files/kboot.conf
            '';
            };
          services.openssh = {
            enable = true;
            settings.PermitRootLogin = "yes";
          };
          users.extraUsers.root.initialPassword = lib.mkForce "test123";
        }
      ];
    };

    images = {
      m1 = nixosConfigurations.m1.config.system.build.sdImage;
    };
  };
}
