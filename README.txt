nixmywindows Installation ISO

This ISO contains the nixmywindows NixOS configuration for laptop installations.

QUICK INSTALLATION (Recommended):
  sudo /install.sh

This automated script will guide you through:
- Disk selection and formatting with ZFS
- System installation
- Root password setup
- Automatic reboot

MANUAL INSTALLATION:
1. Boot from this ISO
2. Connect to the internet (wifi-connect or ethernet)  
3. Run: sudo disko --mode disko /iso/nixmywindows/hosts/laptop/disks.nix --arg device '"/dev/sdX"'
4. Run: sudo nixos-install --flake /iso/nixmywindows#laptop
5. Set root password when prompted
6. Reboot

Default root password for ISO: nixos
SSH is enabled for remote installation

For more information, see the flake configuration in /nixmywindows/