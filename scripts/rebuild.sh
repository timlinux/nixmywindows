#!/usr/bin/env bash
# Rebuild NixOS from the local nixmywindows flake
# Usage: sudo ./rebuild.sh [switch|boot|test]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOSTNAME="$(hostname)"
ACTION="${1:-switch}"

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  echo "Usage: sudo $0 [switch|boot|test]"
  exit 1
fi

case "$ACTION" in
  switch|boot|test)
    ;;
  *)
    echo "Usage: $0 [switch|boot|test]"
    echo "  switch - Build and activate immediately (default)"
    echo "  boot   - Build and activate on next boot"
    echo "  test   - Build and activate, but don't add to boot menu"
    exit 1
    ;;
esac

echo "Rebuilding NixOS from: $FLAKE_DIR#$HOSTNAME"
echo "Action: $ACTION"
echo ""

nixos-rebuild "$ACTION" --flake "$FLAKE_DIR#$HOSTNAME"
