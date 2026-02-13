# NetworkManager configuration with nmtui
{ config, lib, pkgs, ... }:

with lib;

{
  options.tuinix.networking.networkmanager = {
    enable = mkEnableOption "Enable NetworkManager for network management";
  };

  config = mkIf config.tuinix.networking.networkmanager.enable {
    # Enable NetworkManager
    networking.networkmanager = {
      enable = true;
      wifi.powersave = true;
    };

    # Disable conflicting network services
    networking.useDHCP = lib.mkDefault false;

    # NetworkManager tools including nmtui
    environment.systemPackages = with pkgs; [
      networkmanager # includes nmtui, nmcli
      networkmanagerapplet # nm-applet for tray (optional)
    ];

    # Add users to networkmanager group
    users.groups.networkmanager = { };
  };
}
