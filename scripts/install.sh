#!/usr/bin/env bash
# nixmywindows Automated Installation Script

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
  if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
  fi
}

# Display disk selection
select_disk() {
  log_info "Available disks:"
  echo ""

  # Display available block devices with more details
  echo "Device    Size    Type    Model"
  echo "------    ----    ----    -----"
  lsblk -d -n -o NAME,SIZE,TYPE,MODEL | while read name size type model; do
    if [[ "$type" == "disk" ]]; then
      echo "/dev/$name    $size    $type    $model"
    fi
  done

  echo ""
  read -p "Enter the target disk (e.g., /dev/vda, /dev/sda, /dev/nvme0n1): " target_disk

  # Validate disk exists
  if [[ ! -b "$target_disk" ]]; then
    log_error "Disk $target_disk does not exist or is not a block device!"
    log_info "Available block devices:"
    ls -la /dev/sd* /dev/vd* /dev/nvme* 2>/dev/null | head -10 || true
    exit 1
  fi

  # Check if disk is mounted
  if mount | grep -q "^$target_disk"; then
    log_warning "Disk $target_disk has mounted partitions!"
    log_warning "This will destroy all data on $target_disk"
    echo ""
    read -p "Are you absolutely sure you want to continue? (type 'yes' to confirm): " confirm
    if [[ "$confirm" != "yes" ]]; then
      log_info "Installation cancelled"
      exit 0
    fi
  fi

  echo "$target_disk"
}

# Unmount any existing partitions on the target disk
unmount_disk() {
  local disk="$1"
  log_info "Unmounting any existing partitions on $disk..."

  # Find all partitions on this disk and unmount them
  for partition in $(lsblk -nr -o NAME "$disk" | tail -n +2); do
    partition_path="/dev/$partition"
    if mount | grep -q "^$partition_path"; then
      log_info "Unmounting $partition_path"
      umount "$partition_path" || true
    fi
  done

  # Also try to export any ZFS pools that might be using this disk
  if command -v zpool >/dev/null 2>&1; then
    log_info "Checking for ZFS pools on $disk..."
    zpool export -a 2>/dev/null || true
  fi
}

# Run disko to partition and format the disk
format_disk() {
  local disk="$1"
  log_info "Partitioning and formatting $disk with ZFS..."

  # Create a temporary disko config with the correct device
  local temp_config="/tmp/disko-config.nix"

  log_info "Creating temporary disko config for device: $disk"

  # Use awk instead of sed to avoid delimiter issues
  awk -v new_device="$disk" '{
        if ($0 ~ /d0 = "\/dev\/nvme0n1";/) {
            sub(/\/dev\/nvme0n1/, new_device)
        }
        print
    }' /iso/nixmywindows/hosts/laptop/disks.nix >"$temp_config"

  log_info "Running disko to format $disk..."
  log_info "Using config: $temp_config"

  # Show the modified config for debugging
  log_info "Modified device variable:"
  grep "d0.*=" "$temp_config" || log_warning "Could not find device variable"

  if [[ ! -f "$temp_config" ]]; then
    log_error "Failed to create temporary config file"
    exit 1
  fi

  disko --mode disko "$temp_config"

  log_success "Disk formatting completed"
}

# Install the system
install_system() {
  log_info "Installing nixmywindows system..."

  # Set a reasonable timeout for the installation
  export NIX_CONFIG="
        extra-substituters = https://cache.nixos.org/
        extra-trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
        max-jobs = auto
        cores = 0
    "

  log_info "Starting nixos-install (this may take a while)..."
  nixos-install --flake /iso/nixmywindows#laptop --no-root-passwd

  log_success "System installation completed"
}

# Set up root password
setup_root_password() {
  log_info "Setting up root password..."

  # Chroot into the new system to set password
  nixos-enter --root /mnt --command "passwd root"

  log_success "Root password configured"
}

# Post-installation cleanup
cleanup() {
  log_info "Cleaning up..."

  # Clean up temporary files
  rm -f /tmp/disko-config.nix

  log_success "Cleanup completed"
}

# Main installation function
main() {
  echo "========================================"
  echo "     nixmywindows Auto-Installer"
  echo "========================================"
  echo ""

  log_warning "This script will completely wipe the selected disk!"
  log_warning "Make sure you have backed up all important data."
  echo ""

  check_root

  # Select target disk
  target_disk=$(select_disk)
  log_info "Target disk: $target_disk"
  echo ""

  # Final confirmation
  log_warning "FINAL WARNING: This will DESTROY ALL DATA on $target_disk"
  read -p "Type 'DESTROY' to confirm: " final_confirm
  if [[ "$final_confirm" != "DESTROY" ]]; then
    log_info "Installation cancelled"
    exit 0
  fi

  echo ""
  log_info "Starting installation process..."

  # Installation steps
  unmount_disk "$target_disk"
  format_disk "$target_disk"
  install_system
  setup_root_password
  cleanup

  echo ""
  log_success "========================================="
  log_success "  nixmywindows installation completed!"
  log_success "========================================="
  echo ""
  log_info "You can now remove the installation media and reboot."
  log_info "Your new nixmywindows system is ready!"
  echo ""

  read -p "Reboot now? (y/N): " reboot_confirm
  if [[ "$reboot_confirm" =~ ^[Yy]$ ]]; then
    log_info "Rebooting..."
    reboot
  fi
}

# Trap to cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"

