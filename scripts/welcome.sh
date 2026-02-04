#!/usr/bin/env bash
# tuinix ISO welcome message - displayed on first login
# This script is deployed to the live ISO and sourced from the root profile.

TUINIX_DIR="/home/tuinix"
LOGO_PATH="${TUINIX_DIR}/assets/LOGO.png"

# Clear screen for clean welcome
clear

# Show mascot logo centered on screen using catimg
show_mascot() {
  if command -v catimg &>/dev/null && [ -f "${LOGO_PATH}" ]; then
    local cols
    cols=$(tput cols 2>/dev/null || echo 80)
    # Render logo at ~60 catimg width (~30 visible chars)
    local logo_width=60
    local visible_width=$(( logo_width / 2 ))
    local pad=$(( (cols - visible_width) / 2 ))
    if [ "$pad" -lt 0 ]; then
      pad=0
    fi
    # Generate padding string
    local padding
    padding=$(printf '%*s' "$pad" '')
    # Render catimg and prepend padding to each line for centering
    catimg -w "$logo_width" "${LOGO_PATH}" 2>/dev/null | while IFS= read -r line; do
      printf '%s%s\n' "$padding" "$line"
    done
  fi
}

show_mascot

# Show welcome message centered on screen
cols=$(tput cols 2>/dev/null || echo 80)
box_width=60
h_margin=$(( (cols - box_width - 2) / 2 ))
if [ "$h_margin" -lt 0 ]; then
  h_margin=0
fi

if command -v gum &>/dev/null; then
  gum style \
    --border rounded \
    --border-foreground 208 \
    --padding "1 3" \
    --margin "1 ${h_margin}" \
    --align center \
    --width ${box_width} \
    "Welcome to the tuinix Live Installer" \
    "" \
    "To install tuinix, run:" \
    "" \
    "  sudo installer" \
    "" \
    "You are in: ${TUINIX_DIR}"
else
  padding=$(printf '%*s' "$h_margin" '')
  echo ""
  echo "${padding}=========================================="
  echo "${padding}  Welcome to the tuinix Live Installer"
  echo "${padding}=========================================="
  echo "${padding}"
  echo "${padding}  To install tuinix, run:"
  echo "${padding}"
  echo "${padding}    sudo installer"
  echo "${padding}"
  echo "${padding}  You are in: ${TUINIX_DIR}"
  echo "${padding}=========================================="
  echo ""
fi
