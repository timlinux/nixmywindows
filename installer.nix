# Simple installer ISO configuration
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];

  # Include the nixmywindows flake for installation
  isoImage.contents = [
    {
      source = ./.;
      target = "/nixmywindows";
    }
    {
      source = ./README.txt;
      target = "/README.txt";
    }
    {
      source = ./scripts/install.sh;
      target = "/install.sh";
    }
  ];

  # Basic packages for installation
  environment.systemPackages = with pkgs; [
    git
    vim
    nano
    curl
    wget
    parted
    gptfdisk
    e2fsprogs
    dosfstools
    zfs
    disko
  ];

  # Enable SSH
  services.openssh.enable = true;
  users.users.root.password = "nixos";

  # Network configuration
  networking.useDHCP = lib.mkForce true;
  networking.networkmanager.enable = lib.mkForce true;
  networking.firewall.enable = lib.mkForce false;

  # Enable flakes and nix-command for disko and nixos-install
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "24.05";
}

