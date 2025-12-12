# Main Ambxst package
{ pkgs, lib, self, system, nixgl, quickshell, ambxstLib }:

let
  isNixOS = ambxstLib.detectNixOS pkgs;
  nixGL = nixgl.packages.${system}.nixGLDefault;
  quickshellPkg = quickshell.packages.${system}.default;

  wrapWithNixGL = ambxstLib.wrapWithNixGL {
    inherit pkgs system isNixOS;
  };

  # Import sub-packages
  ambxst-auth = import ./ambxst-auth.nix {
    inherit pkgs;
    src = self + /modules/lockscreen;
  };

  ttf-phosphor-icons = import ./phosphor-icons.nix { inherit pkgs; };

  # Base environment packages
  baseEnv = with pkgs; [
    (wrapWithNixGL quickshellPkg)

    (wrapWithNixGL gpu-screen-recorder)
    (wrapWithNixGL mpvpaper)

    brightnessctl
    ddcutil
    wl-clipboard
    wl-clip-persist
    sqlite
    hypridle
    fontconfig

  ] ++ (if isNixOS then [
    ambxst-auth
    power-profiles-daemon
    networkmanager
  ] else [
    nixGL
  ]) ++ (with pkgs; [
    mesa
    libglvnd
    egl-wayland
    wayland

    qt6.qtbase
    qt6.qtsvg
    qt6.qttools
    qt6.qtwayland
    qt6.qtdeclarative
    qt6.qtimageformats

    kdePackages.qtshadertools
    kdePackages.breeze-icons
    hicolor-icon-theme
    fuzzel
    wtype
    imagemagick
    matugen
    ffmpeg
    playerctl

    pipewire
    wireplumber

    # Control packages
    networkmanagerapplet
    blueman
    pwvucontrol
    easyeffects

    # Terminal
    (wrapWithNixGL kitty)
    tmux

    # Fonts
    roboto
    barlow
    terminus_font
    terminus_font_ttf
    nerd-fonts.symbols-only
    noto-fonts
    noto-fonts-color-emoji
    ttf-phosphor-icons
  ]);

  envAmbxst = pkgs.buildEnv {
    name = "Ambxst-env";
    paths = baseEnv;
  };

  launcher = pkgs.writeShellScriptBin "ambxst" ''
    # Ensure ambxst-auth is in PATH for lockscreen
    ${lib.optionalString isNixOS ''
      export PATH="${ambxst-auth}/bin:$PATH"
    ''}
    ${lib.optionalString (!isNixOS) ''
      # On non-NixOS, use local build from ~/.local/bin
      export PATH="$HOME/.local/bin:$PATH"
    ''}

    # Pass nixGL for non-NixOS
    ${lib.optionalString (!isNixOS) "export AMBXST_NIXGL=\"${nixGL}/bin/nixGL\""}

    export AMBXST_QS="${quickshellPkg}/bin/qs"

    # Delegate execution to CLI
    exec ${self}/cli.sh "$@"
  '';

in pkgs.buildEnv {
  name = "Ambxst";
  paths = [ envAmbxst launcher ];
}
