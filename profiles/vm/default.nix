# Absolutely minimal VM configuration: kernel + ZFS + user + Portuguese locale + fish
{ config, lib, pkgs, ... }:

{
  # Enable ZFS for minimal VM
  nixmywindows.zfs.enable = lib.mkForce true;

  # Boot essentials only with stable kernel for ZFS compatibility
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    supportedFilesystems = [ "zfs" ];
    kernelPackages = lib.mkForce pkgs.linuxPackages; # Use stable kernel for ZFS
  };

  # Minimal networking - DHCP only
  networking = {
    useDHCP = lib.mkForce true;
    usePredictableInterfaceNames = lib.mkForce false;
    networkmanager.enable = lib.mkForce false;
    firewall.enable = lib.mkForce false;
  };

  # Portuguese locale only
  i18n = {
    defaultLocale = lib.mkForce "pt_PT.UTF-8";
    supportedLocales = lib.mkForce [ "pt_PT.UTF-8/UTF-8" ];
  };
  
  console = {
    keyMap = lib.mkForce "pt-latin1";
    font = lib.mkForce null;
  };
  
  time.timeZone = lib.mkForce "Europe/Lisbon";

  # Fish shell only
  environment.systemPackages = lib.mkForce [ pkgs.fish ];
  programs.fish.enable = lib.mkForce true;
  users.defaultUserShell = lib.mkForce pkgs.fish;

  # Essential user (override existing user config)
  users.users.user = {
    isNormalUser = true;
    shell = lib.mkForce pkgs.fish;
    password = lib.mkForce "user";
    extraGroups = lib.mkForce [];
    openssh.authorizedKeys.keys = lib.mkForce [];
  };

  # Disable everything else
  documentation.enable = lib.mkForce false;
  documentation.nixos.enable = lib.mkForce false;
  fonts.packages = lib.mkForce [];
  security.audit.enable = lib.mkForce false;
  security.apparmor.enable = lib.mkForce false;
  hardware.alsa.enable = lib.mkForce false;
  services.pulseaudio.enable = lib.mkForce false;
  services.openssh.enable = lib.mkForce false;
  services.fail2ban.enable = lib.mkForce false;
  services.tlp.enable = lib.mkForce false;
  services.thermald.enable = lib.mkForce false;
  services.acpid.enable = lib.mkForce false;
  hardware.enableAllFirmware = lib.mkForce false;
  hardware.cpu.intel.updateMicrocode = lib.mkForce false;
  hardware.cpu.amd.updateMicrocode = lib.mkForce false;
  
  # Minimal system packages only
  environment.defaultPackages = lib.mkForce [];
  
  # No home-manager for users
  home-manager.users = lib.mkForce {};
}