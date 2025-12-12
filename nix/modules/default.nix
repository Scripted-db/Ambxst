# NixOS module for Ambxst
{ config, lib, ... }:

{
  config = lib.mkIf (!config.networking.networkmanager.enable) {
    networking.networkmanager.enable = lib.mkDefault true;
  };
}
