# R36S NixOS Build Notes

This document captures the research and context needed to create a direct-flash SD card image for the R36S handheld gaming device.

## Device Overview

- **Device**: R36S handheld gaming console
- **SoC**: Rockchip RK3326 (ARM Cortex-A35 quad-core)
- **Architecture**: aarch64 (ARM64)
- **Storage**: SD card slots (TF1 and TF2)
- **Display**: 3.5" IPS screen (multiple panel variants exist)

## Why ISO Won't Work

The standard aarch64 ISO requires UEFI boot support. The R36S uses Rockchip's custom boot flow:

1. **BootROM** (on-chip) looks for bootloader at specific SD card offsets
2. **idbloader.img** must be at sector 64 (0x40)
3. **u-boot.itb** must be at sector 16384 (0x4000)
4. No UEFI - uses U-Boot with extlinux.conf

## Required Components

### 1. U-Boot Bootloader

Need R36S-specific U-Boot binaries:
- `idbloader.img` - First stage loader (DDR init + SPL)
- `u-boot.itb` - Main U-Boot binary

**Sources:**
- [R36S-Stuff/R36S-u-boot](https://github.com/R36S-Stuff/R36S-u-boot)
- [AndreRenaud/u-boot-r36s](https://github.com/AndreRenaud/u-boot-r36s)
- Extract from stock R36S SD card image

### 2. Device Tree Blob (DTB)

**Critical**: R36S has 5+ display panel variants. Wrong DTB = black screen.

Common DTB names:
- `rk3326-r36s.dtb`
- `rk3326-r35s-linux.dtb`
- `rk3326-rg351mp-linux.dtb`
- `gameconsole-r36s.dtb`

Best approach: Extract from stock image to match your specific hardware revision.

### 3. Kernel

Options:
- Mainline Linux with RK3326 support (may need patches)
- Vendor kernel from R36S firmware
- Community kernel (JELOS, ArkOS sources)

## SD Card Layout

```
Offset (sectors)  | Content
------------------|------------------
0-63              | Reserved (MBR at 0)
64                | idbloader.img (~200KB)
16384             | u-boot.itb (~1MB)
32768             | Boot partition (FAT32) - kernel, DTB, extlinux.conf
262144+           | Root partition (ext4) - NixOS root filesystem
```

## Implementation Plan

### Step 1: Extract Stock Image Components

```bash
# Dump the bootloader region
sudo dd if=/dev/sdX of=r36s-bootloader.bin bs=512 count=32768

# Mount and copy boot partition contents
sudo mount /dev/sdX1 /mnt
cp -r /mnt/* ./r36s-boot-contents/

# Find and copy the DTB
find ./r36s-boot-contents -name "*.dtb" -exec cp {} ./r36s.dtb \;
```

### Step 2: Create NixOS SD Image Module

```nix
# modules/images/r36s-sd-image.nix
{ config, lib, pkgs, ... }:

{
  imports = [
    "${pkgs.path}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
  ];

  # Use extlinux bootloader (not GRUB)
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # R36S device tree
  hardware.deviceTree.enable = true;
  hardware.deviceTree.name = "rockchip/rk3326-r36s.dtb";

  # Serial console for debugging
  boot.kernelParams = [
    "console=ttyS2,1500000n8"
    "root=/dev/mmcblk0p2"
    "rootwait"
  ];

  # SD image settings
  sdImage = {
    compressImage = false;
    imageBaseName = "tuinix-r36s";

    # Write U-Boot to correct offsets
    postBuildCommands = ''
      # Write idbloader at sector 64
      dd if=${./firmware/idbloader.img} of=$img bs=512 seek=64 conv=notrunc

      # Write u-boot.itb at sector 16384
      dd if=${./firmware/u-boot.itb} of=$img bs=512 seek=16384 conv=notrunc
    '';
  };
}
```

### Step 3: Add to Flake

```nix
# In flake.nix
nixosConfigurations.r36s-sd = nixpkgs.lib.nixosSystem {
  system = "aarch64-linux";
  modules = [
    ./modules/images/r36s-sd-image.nix
    ./hosts/r36s
  ];
};

# Build with:
# nix build .#nixosConfigurations.r36s-sd.config.system.build.sdImage
```

### Step 4: Build Script

Add to `scripts/build-iso.sh` or create `scripts/build-sd-image.sh`:

```bash
#!/usr/bin/env bash
# Build R36S SD card image

nix build .#nixosConfigurations.r36s-sd.config.system.build.sdImage

# Copy to project root
cp result/sd-image/*.img ./tuinix.${VERSION}.r36s.img
```

## Files to Create

1. `modules/images/r36s-sd-image.nix` - SD image configuration
2. `firmware/r36s/idbloader.img` - Extracted/built U-Boot stage 1
3. `firmware/r36s/u-boot.itb` - Extracted/built U-Boot stage 2
4. `firmware/r36s/rk3326-r36s.dtb` - Device tree for your R36S variant
5. `scripts/build-sd-image.sh` - Build script for SD images

## Reference Projects

- [nabam/nixos-rockchip](https://github.com/nabam/nixos-rockchip) - NixOS on Rockchip boards
- [Mic92/nixos-aarch64-images](https://github.com/Mic92/nixos-aarch64-images) - ARM64 image patterns
- [JELOS](https://github.com/JustEnoughLinuxOS/distribution) - R36S-compatible Linux distro
- [ArkOS](https://github.com/christianhaitian/arkos) - Another R36S Linux option

## Debugging

### Serial Console

R36S uses UART2 at 1500000 baud:
```
console=ttyS2,1500000n8
```

### Common Issues

1. **Black screen**: Wrong DTB for your display panel variant
2. **No boot**: idbloader/u-boot at wrong offset or corrupted
3. **Kernel panic**: Missing drivers or wrong root= parameter
4. **No SD card detected**: Need correct MMC driver in kernel

## User Action Required

Before implementing, provide:
1. **Stock SD card image** or mounted device path for extraction
2. **R36S variant info** (check sticker on device or boot screen)

This will let us extract the exact bootloader and DTB for your specific unit.
