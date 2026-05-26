let
  pkgs0 = import <nixpkgs> { };
in
let
  # since https://github.com/nixos/nixpkgs/pull/507470, xmonad 0.18.1 it stopped working
  nixpkgs = pkgs0.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev =
      # nixos-unstable
      "64c08a7ca051951c8eae34e3e3cb1e202fe36786";
    hash = "sha256-tpyBcxPpcQb8ukyNF7DoCwfSY3VPsxHoYwj00Cayv5o=";
  };
  home-manager = pkgs0.fetchFromGitHub {
    owner = "nix-community";
    repo = "home-manager";
    rev = # "release-26.05"
      "b179bde238977f7d4454fc770b1a727eaf55111c";
    hash = "sha256-RUkMrREjKDQrA+dA9+xZviGAxM5W1aVdyOr/bSYpHrE=";
  };
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
                pkgs.ghc
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
