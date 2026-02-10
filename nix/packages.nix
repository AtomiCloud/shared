{ pkgs, pkgs-2511, pkgs-unstable, atomi }:
let

  all = {
    atomipkgs = (
      with atomi;
      {
        inherit
          atomiutils
          cyanprint
          sg
          pls;
      }
    );
    nix-unstable = (
      with pkgs-unstable;
      { }
    );
    nix-2511 = (
      with pkgs-2511;
      {

        inherit

          git

          infisical
          bun
          biome
          typescript-language-server

          treefmt
          shellcheck
          ;
      }
    );
  };
in
with all;
nix-2511 //
nix-unstable //
atomipkgs
