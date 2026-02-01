# Firewall configuration
{ config, lib, ... }:

with lib;

{
  options.nixtui.security.firewall = {
    enable = mkEnableOption "Enable firewall";
    
    allowedTCPPorts = mkOption {
      type = types.listOf types.int;
      default = [];
      description = "List of allowed TCP ports";
    };
    
    allowedUDPPorts = mkOption {
      type = types.listOf types.int;
      default = [];
      description = "List of allowed UDP ports";
    };
  };

  config = mkIf config.nixtui.security.firewall.enable {
    networking.firewall = {
      enable = true;
      allowedTCPPorts = config.nixtui.security.firewall.allowedTCPPorts;
      allowedUDPPorts = config.nixtui.security.firewall.allowedUDPPorts;
      
      # Default deny policy
      rejectPackets = true;
      
      # Disable ping
      allowPing = false;
    };
  };
}