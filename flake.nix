{
  description = "Jambhala: A Plutus Development Suite";

  inputs = {
    haskellNix.url = "github:input-output-hk/haskell.nix";
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    CHaP = {
      url = "github:input-output-hk/cardano-haskell-packages?ref=repo";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, haskellNix, CHaP }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [
          haskellNix.overlay
          (final: prev: {
            # This overlay adds our project to pkgs
            plutusDapp =
              final.haskell-nix.project' {
                src = ./.;
                compiler-nix-name = "ghc8107";
                # This is used by `nix develop .` to open a shell for use with
                # `cabal`, `hlint` and `haskell-language-server`
                shell.tools = {
                  cabal = { };
                  hlint = "3.4.1";
                  haskell-language-server = rec {
                    # HLS fix for stm-hamt bug
                    src = final.haskell-nix.sources."hls-1.10";
                    cabalProject = __readFile (src + "/cabal.project");
                  };
                };
                # Non-Haskell applications required by Jambhala
                shell.buildInputs = with pkgs; [
                  bashInteractive
                  gnugrep
                  httpie
                  neovim
                  nixpkgs-fmt
                  nix-prefetch-git
                  nodejs-18_x
                  nodePackages.pnpm
                  python311
                  python311Packages.autopep8
                  (vscode-with-extensions.override {
                    vscode = pkgs.vscodium;
                    vscodeExtensions = with pkgs.vscode-extensions; [
                      asvetliakov.vscode-neovim
                      dracula-theme.theme-dracula
                      haskell.haskell
                      jnoortheen.nix-ide
                      justusadam.language-haskell
                      mkhl.direnv
                      ms-python.python
                      ms-python.vscode-pylance
                    ];
                  })
                ];
                inputMap = { "https://input-output-hk.github.io/cardano-haskell-packages" = CHaP; };
              };
          })
        ];
        pkgs = import nixpkgs { inherit system overlays; inherit (haskellNix) config; };
        flake = pkgs.plutusDapp.flake { };
      in
      flake // {
        # Built by `nix build .`
        packages.default = flake.packages."plutusDapp:exe:jamb";
      });

  nixConfig = {
    extra-substituters = [
      "https://cache.iog.io"
      "https://cache.zw3rk.com"
    ];
    extra-trusted-public-keys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      "loony-tools:pr9m4BkM/5/eSTZlkQyRt57Jz7OMBxNSUiMC4FkcNfk="
    ];
  };
}
