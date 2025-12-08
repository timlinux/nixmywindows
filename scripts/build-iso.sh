#!/usr/bin/env bash
# Build bootable ISO for nixmywindows laptop profile

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Version for ISO naming
VERSION="${NIXMYWINDOWS_VERSION:-v1}"

echo "🚀 Building nixmywindows laptop ISO..."
echo "Working directory: $PROJECT_ROOT"

cd "$PROJECT_ROOT"

# Function to validate ISO contents
validate_iso() {
  local iso_file="$1"
  local mount_point="/tmp/nixmywindows-iso-validation"

  echo "🔍 Validating ISO contents..."

  # Create mount point
  sudo mkdir -p "$mount_point"

  # Mount ISO
  if ! sudo mount -o loop "$iso_file" "$mount_point" 2>/dev/null; then
    echo "❌ Failed to mount ISO for validation"
    return 1
  fi

  local validation_failed=0

  # Check for flake configuration
  if [[ -f "$mount_point/nixmywindows/flake.nix" && -f "$mount_point/nixmywindows/flake.lock" ]]; then
    echo "✅ Flake configuration found"
  else
    echo "❌ Missing flake configuration"
    validation_failed=1
  fi

  # Check for host configurations
  if [[ -d "$mount_point/nixmywindows/hosts/laptop" ]]; then
    echo "✅ Laptop host configuration found"
  else
    echo "❌ Missing laptop host configuration"
    validation_failed=1
  fi

  # Check for user configurations
  if [[ -d "$mount_point/nixmywindows/users" ]]; then
    echo "✅ User configurations found"
  else
    echo "❌ Missing user configurations"
    validation_failed=1
  fi

  # Check for modules
  if [[ -d "$mount_point/nixmywindows/modules" ]]; then
    echo "✅ System modules found"
  else
    echo "❌ Missing system modules"
    validation_failed=1
  fi

  # Check for installation README
  if [[ -f "$mount_point/README.txt" ]]; then
    echo "✅ Installation README found"
  else
    echo "❌ Missing installation README"
    validation_failed=1
  fi

  # Check for nix store
  if [[ -f "$mount_point/nix-store.squashfs" ]]; then
    echo "✅ Nix store found"
  else
    echo "❌ Missing nix store"
    validation_failed=1
  fi

  # Unmount
  sudo umount "$mount_point"
  sudo rmdir "$mount_point"

  if [[ $validation_failed -eq 0 ]]; then
    echo "✅ ISO validation passed"
    return 0
  else
    echo "❌ ISO validation failed"
    return 1
  fi
}

# Build the ISO
nix build .#nixosConfigurations.installer.config.system.build.isoImage

# Check if build was successful
if [[ -L "result" && -d "result/iso" ]]; then
  # Find ISO file (either .iso or .iso.zst)
  ISO_PATH=$(find result/iso -name "*.iso" -o -name "*.iso.zst" | head -1)
  ISO_NAME=$(basename "$ISO_PATH")

  echo "✅ ISO built successfully!"
  echo "📀 ISO location: $ISO_PATH"
  echo "📁 ISO name: $ISO_NAME"
  echo ""

  # Determine final ISO name
  FINAL_ISO_NAME="nixmywindows.${VERSION}.iso"
  if [[ -f "./$FINAL_ISO_NAME" ]]; then
    echo "⚠️  Removing existing ISO: ./$FINAL_ISO_NAME"
    sudo rm "./$FINAL_ISO_NAME"
  fi

  if [[ "$ISO_PATH" == *.zst ]]; then
    echo "📦 Decompressing ISO..."
    TEMP_ISO_NAME="${ISO_NAME%.zst}"
    zstd -d "$ISO_PATH" -o "./$TEMP_ISO_NAME"

    # Validate the decompressed ISO
    if validate_iso "./$TEMP_ISO_NAME"; then
      # Rename to final name
      mv "./$TEMP_ISO_NAME" "./$FINAL_ISO_NAME"
      echo "✅ ISO created and validated: ./$FINAL_ISO_NAME"
    else
      echo "❌ ISO validation failed - removing invalid ISO"
      rm -f "./$TEMP_ISO_NAME"
      exit 1
    fi
  else
    echo "📋 Copying ISO..."
    cp "$ISO_PATH" "./$FINAL_ISO_NAME"

    # Validate the copied ISO
    if validate_iso "./$FINAL_ISO_NAME"; then
      echo "✅ ISO created and validated: ./$FINAL_ISO_NAME"
    else
      echo "❌ ISO validation failed - removing invalid ISO"
      rm -f "./$FINAL_ISO_NAME"
      exit 1
    fi
  fi

  echo ""
  echo "📊 ISO Information:"
  echo "  📁 Name: $FINAL_ISO_NAME"
  echo "  📏 Size: $(du -h "./$FINAL_ISO_NAME" | cut -f1)"
  echo "  🏷️  Version: $VERSION"
  echo ""
  echo "To create a bootable USB:"
  echo "  sudo dd if=./$FINAL_ISO_NAME of=/dev/sdX bs=4M status=progress"
  echo "  (Replace /dev/sdX with your USB device)"
else
  echo "❌ ISO build failed or result not found"
  exit 1
fi

