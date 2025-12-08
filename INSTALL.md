# nixmywindows Installation Guide

This guide will help you install nixmywindows on your system using the provided ISO image.

## Prerequisites

- A computer with x86_64 architecture
- At least 8GB RAM recommended
- 50GB+ free disk space
- USB drive (8GB+) for creating bootable media

## Step 1: Create Bootable USB

### On Linux:
```bash
sudo dd if=nixmywindows.v1.iso of=/dev/sdX bs=4M status=progress
```
Replace `/dev/sdX` with your USB device (check with `lsblk`).

### On Windows:
Use [Rufus](https://rufus.ie/) or [Balena Etcher](https://www.balena.io/etcher/) to write the ISO to your USB drive.

### On macOS:
```bash
sudo dd if=nixmywindows.v1.iso of=/dev/diskX bs=4m
```
Replace `/dev/diskX` with your USB device (check with `diskutil list`).

## Step 2: Boot from USB

1. Insert the USB drive into your target computer
2. Boot from USB (usually F12, F2, or DEL during startup to access boot menu)
3. Select the nixmywindows installer from the boot menu
4. Wait for the system to boot to the installer environment

## Step 3: Prepare Your Disk

The installer includes a ZFS-based disk configuration. You need to partition your disk first:

### Automatic ZFS Setup (Recommended)
```bash
# Identify your target disk
lsblk

# Replace /dev/sdX with your target disk
sudo disko --mode disko /iso/nixmywindows/hosts/laptop/disks.nix --arg device '"/dev/sdX"'
```

### Manual Partitioning
If you prefer manual setup:
1. Create a GPT partition table
2. Create a 512MB EFI boot partition
3. Create remaining space for ZFS pool
4. Set up your ZFS pool and datasets as desired

## Step 4: Install nixmywindows

Once your disk is prepared:

```bash
# Install the system
sudo nixos-install --flake /iso/nixmywindows#laptop

# Set root password when prompted
# The installation will download and install all necessary packages
```

## Step 5: First Boot

1. Remove the USB drive
2. Reboot your system
3. Boot into your new nixmywindows installation
4. Log in with the credentials configured in the system

## Configuration Details

Your nixmywindows system includes:

- **Terminal-focused environment** - Pure terminal-based Linux experience
- **ZFS filesystem** - Advanced filesystem with snapshots and compression
- **Security hardened** - Firewall, SSH hardening, and security modules
- **Development tools** - Pre-configured development environment
- **User accounts** - Configured users with appropriate permissions

## Customization

After installation, you can:

- Modify `/etc/nixos/configuration.nix` for system changes
- Update user configurations in `/home/<user>/.config/`
- Rebuild system with `sudo nixos-rebuild switch`

## Troubleshooting

### Boot Issues
- Try disabling Secure Boot in BIOS/UEFI
- Use the "No modesetting" option from the boot menu
- Check hardware compatibility

### Installation Failures
- Ensure sufficient disk space (50GB minimum)
- Verify disk permissions and access
- Check network connectivity for package downloads

### ZFS Issues
- Ensure your hardware supports ZFS
- Check that you have enough RAM (ZFS requires adequate memory)
- Verify disk is not corrupted

## Support

For issues or questions:
- Check the project repository for documentation
- Review system logs with `journalctl`
- Consult NixOS documentation for general NixOS questions

## Recovery

If you need to recover your system:
1. Boot from the installation USB
2. Import your ZFS pool: `sudo zpool import -f nixos`
3. Mount your system and chroot for repairs
4. Or restore from ZFS snapshots if available

---

**Note**: This installation will completely replace any existing operating system on the target disk. Make sure to backup important data before proceeding.