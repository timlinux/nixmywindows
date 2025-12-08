#!/usr/bin/env bash

# QEMU VM runner for NixMyWindows
# Usage: ./run-vm.sh [install|run]
#   install - Boot from ISO for installation
#   run     - Boot from disk (after installation)

set -e

VM_NAME="nixmywindows"
DEFAULT_DISK_SIZE="50G"
DEFAULT_MEMORY="8G"
ENABLE_ENHANCED_VIRTUALIZATION="${ENABLE_ENHANCED_VIRTUALIZATION:-true}"
DISK_FILE="$VM_NAME.qcow2"
ISO_FILE="nixmywindows.v1.iso"
CONFIG_DIR="$HOME/.config/nixmywindows"
MEMORY_CONFIG="$CONFIG_DIR/memory"
DISK_CONFIG="$CONFIG_DIR/disk_size"

# Check if nix is available for gum
if ! command -v nix &>/dev/null; then
  echo "Error: nix is not available"
  echo "This script requires nix to run gum"
  exit 1
fi

# Function to run gum via nix or fallback
gum() {
  # Always use fallback in non-interactive environments
  case "$1" in
    "confirm")
      echo "Using default: yes"
      return 0
      ;;
    "choose")
      echo "$2"  # Return first option
      ;;
    "input")
      shift 3  # Skip command and flags
      echo "${1:-$DEFAULT_MEMORY}"  # Return value or default
      ;;
  esac
}

# Function to save configuration
save_config() {
  mkdir -p "$CONFIG_DIR"
  echo "$MEMORY" > "$MEMORY_CONFIG"
  echo "$DISK_SIZE" > "$DISK_CONFIG"
}

# Function to load configuration
load_config() {
  if [ -f "$MEMORY_CONFIG" ] && [ -f "$DISK_CONFIG" ]; then
    MEMORY=$(cat "$MEMORY_CONFIG")
    DISK_SIZE=$(cat "$DISK_CONFIG")
    return 0
  fi
  return 1
}

# Clean function to remove disk and config
clean_vm() {
  echo "🧹 Cleaning VM data..."
  
  if [ -f "$DISK_FILE" ]; then
    if gum confirm "Remove disk image '$DISK_FILE'?"; then
      rm -f "$DISK_FILE"
      echo "✓ Removed disk image"
    fi
  fi
  
  if [ -d "$CONFIG_DIR" ]; then
    if gum confirm "Remove configuration cache?"; then
      rm -rf "$CONFIG_DIR"
      echo "✓ Removed configuration cache"
    fi
  fi
  
  echo "VM cleanup complete"
  exit 0
}

# Enhanced QEMU arguments for better compatibility and performance
get_enhanced_qemu_args() {
  if [ "$ENABLE_ENHANCED_VIRTUALIZATION" = "true" ]; then
    echo "-cpu host,+x2apic,+tsc-deadline,+hypervisor,+tsc_adjust,+umip,+md-clear,+stibp,+arch-capabilities,+ssbd,+xsaves \
-machine q35,accel=kvm,kernel_irqchip=on \
-smp 4,cores=2,threads=2 \
-drive file=$DISK_FILE,format=qcow2,if=virtio,cache=writethrough \
-netdev user,id=net0 \
-device virtio-net-pci,netdev=net0 \
-display sdl \
-usb \
-device qemu-xhci \
-device usb-tablet \
-rtc base=localtime \
-global kvm-pit.lost_tick_policy=delay"
  else
    echo "-cpu host \
-smp 4 \
-drive file=$DISK_FILE,format=qcow2,if=virtio \
-netdev user,id=net0 \
-device virtio-net-pci,netdev=net0 \
-display sdl \
-usb \
-device usb-tablet"
  fi
}

# Check if qemu-system-x86_64 is available
if ! command -v qemu-system-x86_64 &>/dev/null; then
  echo "Error: qemu-system-x86_64 is not installed"
  echo "Please install QEMU first"
  exit 1
fi

# Check if ISO file exists
if [ ! -f "$ISO_FILE" ]; then
  echo "Error: ISO file '$ISO_FILE' not found"
  echo "You may need to build the ISO first using: ./build-iso.sh"
  exit 1
fi

# Handle help and clean commands early
if [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo "Usage: $0 [install|run|clean|help]"
  echo ""
  echo "Commands:"
  echo "  install  - Boot from ISO for installation"
  echo "  run      - Boot from disk after installation"
  echo "  clean    - Remove VM disk image and configuration cache"
  echo "  help     - Show this help message"
  echo ""
  echo "VM Configuration will be prompted interactively using gum"
  echo "Default settings: Memory: $DEFAULT_MEMORY, Disk: $DEFAULT_DISK_SIZE"
  exit 0
fi

if [ "$1" = "clean" ]; then
  clean_vm
fi

# Determine boot mode early to handle configuration appropriately
if [ $# -eq 0 ]; then
  MODE=$(gum choose "install" "run" --header "Choose VM mode:")
else
  MODE="$1"
fi

# Configuration handling based on mode
case "$MODE" in
"install")
  # For installation, always prompt for configuration
  echo "🖥️  NixMyWindows VM Configuration (Installation)"
  echo ""

  # Memory configuration
  if gum confirm "Use default memory size ($DEFAULT_MEMORY)?"; then
    MEMORY="$DEFAULT_MEMORY"
  else
    MEMORY=$(gum input --placeholder "Enter memory size (e.g., 4G, 8G, 16G)" --value "$DEFAULT_MEMORY")
  fi

  # Disk configuration
  if gum confirm "Use default disk size ($DEFAULT_DISK_SIZE)?"; then
    DISK_SIZE="$DEFAULT_DISK_SIZE"
  else
    DISK_SIZE=$(gum input --placeholder "Enter disk size (e.g., 20G, 50G, 100G)" --value "$DEFAULT_DISK_SIZE")
  fi
  
  # Save configuration for future runs
  save_config
  ;;

"run")
  # For run mode, require existing configuration
  if ! load_config; then
    echo "❌ No VM configuration found!"
    echo "You must run installation mode first: $0 install"
    echo "Or run clean and install again: $0 clean && $0 install"
    exit 1
  fi
  
  if [ ! -f "$DISK_FILE" ]; then
    echo "❌ No disk image found!"
    echo "You must run installation mode first: $0 install"
    exit 1
  fi
  ;;

*)
  echo "Error: Unknown command '$MODE'"
  echo "Use '$0 help' for usage information"
  exit 1
  ;;
esac

echo ""
echo "VM Configuration:"
echo "  Memory: $MEMORY"
echo "  Disk: $DISK_SIZE"
echo "  ISO: $ISO_FILE"
echo ""

# Create disk image if it doesn't exist (only for install mode)
if [ "$MODE" = "install" ] && [ ! -f "$DISK_FILE" ]; then
  echo "Creating virtual disk: $DISK_FILE ($DISK_SIZE)"
  qemu-img create -f qcow2 "$DISK_FILE" "$DISK_SIZE"
fi

# Launch VM based on mode
case "$MODE" in
"install")
  echo ""
  echo "🚀 Starting VM in installation mode (booting from ISO)"
  echo "After installation, shutdown the VM and run: ./run-vm.sh run"
  echo ""

  if ! gum confirm "Start the VM now?"; then
    echo "VM startup cancelled."
    exit 0
  fi

  QEMU_ARGS=$(get_enhanced_qemu_args)
  
  echo "🐛 If you experience kernel panics, try running: ENABLE_ENHANCED_VIRTUALIZATION=false $0 install"
  echo ""
  
  qemu-system-x86_64 \
    -enable-kvm \
    -m "$MEMORY" \
    $QEMU_ARGS \
    -cdrom "$ISO_FILE" \
    -boot order=dc,menu=on \
    -name "NixMyWindows (Installation)"
  ;;

"run")
  echo ""
  echo "🚀 Starting VM in normal mode (booting from disk)"
  echo ""

  if ! gum confirm "Start the VM now?"; then
    echo "VM startup cancelled."
    exit 0
  fi

  QEMU_ARGS=$(get_enhanced_qemu_args)
  
  qemu-system-x86_64 \
    -enable-kvm \
    -m "$MEMORY" \
    $QEMU_ARGS \
    -boot order=c,menu=on \
    -name "NixMyWindows"
  ;;

*)
  echo "Error: Unknown command '$MODE'"
  echo "Use '$0 help' for usage information"
  exit 1
  ;;
esac

