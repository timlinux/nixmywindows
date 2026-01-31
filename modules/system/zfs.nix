# ZFS configuration module
{ config, lib, pkgs, ... }:

with lib;

{
  options.nixmywindows.zfs = {
    enable = mkEnableOption "Enable ZFS filesystem support";
    
    encryption = mkEnableOption "Enable ZFS encryption";
    
    autoSnapshot = mkEnableOption "Enable automatic ZFS snapshots";
    
    datasets = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of ZFS datasets to manage";
    };
  };

  config = mkIf config.nixmywindows.zfs.enable {
    # Enable ZFS support
    boot.supportedFilesystems = [ "zfs" ];
    boot.zfs = {
      requestEncryptionCredentials = config.nixmywindows.zfs.encryption;
      forceImportRoot = true;
    };
    
    # ZFS services
    services.zfs = {
      autoScrub = {
        enable = true;
        interval = "weekly";
      };
      
      autoSnapshot = mkIf config.nixmywindows.zfs.autoSnapshot {
        enable = true;
        frequent = 4;
        hourly = 24;
        daily = 7;
        weekly = 4;
        monthly = 12;
      };
    };

    # ZFS utilities
    environment.systemPackages = with pkgs; [
      zfs
      zfstools
    ];
    
    # Networking host ID required for ZFS - will be set by hardware.nix
    # Don't set a default here to avoid conflicts with installer-generated IDs
  };
}

