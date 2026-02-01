# SSH configuration
{ config, lib, ... }:

with lib;

{
  options.nixtui.security.ssh = {
    enable = mkEnableOption "Enable SSH server";
    
    port = mkOption {
      type = types.int;
      default = 22;
      description = "SSH port";
    };
    
    permitRootLogin = mkOption {
      type = types.enum [ "yes" "no" "prohibit-password" ];
      default = "prohibit-password";
      description = "Permit root login";
    };
    
    passwordAuthentication = mkOption {
      type = types.bool;
      default = false;
      description = "Allow password authentication";
    };
  };

  config = mkIf config.nixtui.security.ssh.enable {
    services.openssh = {
      enable = true;
      ports = [ config.nixtui.security.ssh.port ];
      
      settings = {
        PermitRootLogin = config.nixtui.security.ssh.permitRootLogin;
        PasswordAuthentication = config.nixtui.security.ssh.passwordAuthentication;
        
        # Security hardening
        Protocol = 2;
        X11Forwarding = false;
        AllowAgentForwarding = false;
        AllowTcpForwarding = false;
        GatewayPorts = "no";
      };
    };
    
    # Add SSH port to firewall if enabled
    nixtui.security.firewall.allowedTCPPorts = 
      mkIf config.nixtui.security.firewall.enable 
        [ config.nixtui.security.ssh.port ];
  };
}