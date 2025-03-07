{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "flake-utils";
  };

  outputs = { self, flake-utils, nixpkgs }:
    let
      supportedSystems =
        [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" "aarch64-linux" ];
      compilerVersion = "966";
    in flake-utils.lib.eachSystem supportedSystems (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            haskell.compiler."ghc${compilerVersion}"
            (pkgs.haskell-language-server.override {
              supportedGhcVersions = [ compilerVersion ];
            })
          ];
        };
      });
}
