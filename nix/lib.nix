# Utility functions for Ambxst flake
{ nixpkgs, nixgl }:

let
  linuxSystems = [
    "x86_64-linux"
    "aarch64-linux"
    "i686-linux"
  ];
in {
  inherit linuxSystems;

  # Iterate over all supported Linux systems
  forAllSystems = f:
    builtins.foldl' (acc: system: acc // { ${system} = f system; }) {} linuxSystems;

  # Wrap a package with nixGL for non-NixOS systems
  wrapWithNixGL = { pkgs, system, isNixOS }:
    let
      nixGL = nixgl.packages.${system}.nixGLDefault;
    in
    pkg:
      if isNixOS then pkg else pkgs.symlinkJoin {
        name = "${pkg.pname or pkg.name}-nixGL";
        paths = [ pkg ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          for bin in $out/bin/*; do
            if [ -x "$bin" ]; then
              mv "$bin" "$bin.orig"
              makeWrapper ${nixGL}/bin/nixGL "$bin" --add-flags "$bin.orig"
            fi
          done
        '';
      };

  # Detect if running on NixOS
  detectNixOS = pkgs: pkgs ? config && pkgs.config ? nixosConfig;
}
