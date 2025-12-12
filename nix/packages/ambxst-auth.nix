# Ambxst auth binary for lockscreen
{ pkgs, src }:

pkgs.stdenv.mkDerivation {
  pname = "ambxst-auth";
  version = "1.0.0";
  inherit src;

  nativeBuildInputs = [ pkgs.gcc ];
  buildInputs = [ pkgs.pam ];

  buildPhase = ''
    gcc -o ambxst-auth auth.c -lpam -Wall -Wextra -O2
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp ambxst-auth $out/bin/
    chmod 755 $out/bin/ambxst-auth
  '';
}
