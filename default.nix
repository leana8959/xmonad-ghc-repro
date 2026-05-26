let
  pkgs0 = import <nixpkgs> { };
in
let
  # # unstable
  # nixpkgs = pkgs0.fetchFromGitHub {
  #   owner = "NixOS";
  #   repo = "nixpkgs";
  #   rev = "nixos-unstable";
  #   hash = "sha256-Ap9KJX+5xHIn3bPIpfNgT6MEXdAECECwo4/rmlQD74M=";
  # };

  # 25.11
  nixpkgs = pkgs0.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "nixos-25.11";
    hash = "sha256-nOesoDCiXcUftqbRBMz9tt4blI5PvljMWbm3kuCA+0s=";
  };

  home-manager = ~/wt/nix-community/home-manager/ghc-missing-repro;
in
let
  eval-config = import (nixpkgs + "/nixos/lib/eval-config.nix");
  lib = import (nixpkgs + "/lib");
  inherit (lib.modules) mkAliasOptionModule;
in
{
  test = eval-config {
    system = "x86_64-linux";
    modules = [
      { system.stateVersion = "25.11"; }

      # Auto login
      (mkAliasOptionModule [ "hm" ] [ "home-manager" "users" "alice" ])
      {
        imports = [
          (nixpkgs + "/nixos/tests/common/user-account.nix")
          (nixpkgs + "/nixos/tests/common/auto.nix")
        ];
        test-support.displayManager.auto = {
          enable = true;
          user = "alice";
        };
      }

      # X11 session
      (
        {
          pkgs,
          config,
          ...
        }:
        {
          services.xserver.enable = true;
          services.xserver.windowManager.session = [
            {
              name = "home-manager-wm";
              start = ''
                systemd-cat -t home-manager-wm -- ${config.hm.xsession.windowManager.command}
                waitPID=$!
              '';
            }
          ];
        }
      )

      # home-manager as a module
      {
        imports = [ (home-manager + "/nixos") ];
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        hm.imports = [
          { home.stateVersion = "25.11"; }
          (
            { pkgs, lib, ... }:
            {
              # Nothing -> no error, no compilation
              # [cabal-install] -> wants ghc
              # [ghc, cabal-install] -> needs hackage tarball
              # [ghc] -> no error, no compilation
              home.packages = [
                # pkgs.ghc
                pkgs.cabal-install
              ];

              xsession = {
                enable = true;
                windowManager.xmonad = {
                  enable = true;
                  enableContribAndExtras = true;
                };
              };

              xdg.configFile."xmonad" = {
                source = "${./xmonad}";
                recursive = true;
              };
            }
          )
        ];
      }
    ];
  };
}
