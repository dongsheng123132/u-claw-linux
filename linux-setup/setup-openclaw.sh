#!/usr/bin/env bash
# ============================================================
#  U-Claw OpenClaw One-Click Installer for Linux
#  Completely self-contained — no external file dependencies
# ============================================================

set -euo pipefail

# ── All constants defined here (independent of any other project files) ──
NODE_VERSION="v22.14.0"
NODE_MIRROR="https://npmmirror.com/mirrors/node"
NODE_OFFICIAL="https://nodejs.org/dist"
NPM_MIRROR="https://registry.npmmirror.com"
INSTALL_DIR="/opt/u-claw"
NODE_ARCHIVE="node-${NODE_VERSION}-linux-x64.tar.xz"

echo "============================================"
echo "  U-Claw OpenClaw Installer for Linux"
echo "============================================"
echo ""

# ── 1. Check root ──
if [[ $EUID -ne 0 ]]; then
    echo "[ERROR] This script must be run as root (use sudo)."
    echo "Usage: sudo bash setup-openclaw.sh"
    exit 1
fi

# Detect the real user (for desktop shortcuts later)
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")

# ── 2. Install system dependencies ──
echo "[1/9] Installing system dependencies..."
apt-get update -qq
apt-get install -y -qq curl xdg-utils > /dev/null 2>&1
echo "      Done."

# ── 3. Create install directory ──
echo "[2/9] Creating install directory..."
mkdir -p "$INSTALL_DIR"/{runtime,core,data/{.openclaw,memory,backups,logs}}
echo "      $INSTALL_DIR created."

# ── 4. Download and extract Node.js ──
echo "[3/9] Downloading Node.js $NODE_VERSION..."
NODE_DIR="$INSTALL_DIR/runtime/node-linux-x64"
if [[ -x "$NODE_DIR/bin/node" ]]; then
    EXISTING_VER=$("$NODE_DIR/bin/node" --version 2>/dev/null || echo "")
    if [[ "$EXISTING_VER" == "$NODE_VERSION" ]]; then
        echo "      Node.js $NODE_VERSION already installed, skipping."
    else
        echo "      Existing Node.js ($EXISTING_VER) differs, re-downloading..."
        rm -rf "$NODE_DIR"
    fi
fi

if [[ ! -x "$NODE_DIR/bin/node" ]]; then
    TMPFILE=$(mktemp /tmp/node-XXXXXX.tar.xz)
    # Try China mirror first, then official
    if curl -fSL --connect-timeout 10 -o "$TMPFILE" "${NODE_MIRROR}/${NODE_VERSION}/${NODE_ARCHIVE}" 2>/dev/null; then
        echo "      Downloaded from China mirror."
    elif curl -fSL --connect-timeout 10 -o "$TMPFILE" "${NODE_OFFICIAL}/${NODE_VERSION}/${NODE_ARCHIVE}" 2>/dev/null; then
        echo "      Downloaded from official mirror."
    else
        echo "[ERROR] Failed to download Node.js. Please check your network."
        rm -f "$TMPFILE"
        exit 1
    fi
    mkdir -p "$NODE_DIR"
    tar -xJf "$TMPFILE" --strip-components=1 -C "$NODE_DIR"
    rm -f "$TMPFILE"
    echo "      Node.js extracted to $NODE_DIR"
fi

NODE_BIN="$NODE_DIR/bin/node"
NPM_BIN="$NODE_DIR/bin/npm"

echo "      Node.js version: $($NODE_BIN --version)"

# ── 5. Create package.json ──
echo "[4/9] Creating package.json..."
cat > "$INSTALL_DIR/core/package.json" << 'PKGJSON'
{
  "name": "u-claw-linux",
  "version": "1.0.0",
  "private": true,
  "description": "U-Claw OpenClaw Linux runtime"
}
PKGJSON
echo "      Done."

# ── 6. Install OpenClaw + QQ plugin ──
echo "[5/9] Installing OpenClaw (this may take 1-2 minutes)..."
cd "$INSTALL_DIR/core"
"$NPM_BIN" install --registry="$NPM_MIRROR" openclaw@latest @sliverp/qqbot@latest 2>&1 | tail -3
echo "      OpenClaw installed."

# ── 7. Write default config ──
echo "[6/9] Writing default configuration..."
CONFIG_FILE="$INSTALL_DIR/data/.openclaw/openclaw.json"
if [[ ! -f "$CONFIG_FILE" ]]; then
    cat > "$CONFIG_FILE" << 'CONFIGJSON'
{
  "gateway": {
    "mode": "local",
    "auth": {
      "token": "uclaw"
    }
  }
}
CONFIGJSON
    echo "      Default config written."
else
    echo "      Config already exists, keeping existing."
fi

# ── 8. Install start script ──
echo "[7/9] Installing startup script..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "$SCRIPT_DIR/start-openclaw.sh" ]]; then
    cp "$SCRIPT_DIR/start-openclaw.sh" "$INSTALL_DIR/start-openclaw.sh"
else
    echo "      [WARN] start-openclaw.sh not found next to this script."
    echo "      You may need to copy it manually to $INSTALL_DIR/"
fi
chmod +x "$INSTALL_DIR/start-openclaw.sh"
echo "      Done."

# ── 9. Install desktop shortcut ──
echo "[8/9] Installing desktop shortcut..."
DESKTOP_FILE="$REAL_HOME/Desktop/openclaw.desktop"
APPS_DIR="$REAL_HOME/.local/share/applications"
mkdir -p "$APPS_DIR"

cat > "$DESKTOP_FILE" << 'DESKTOPEOF'
[Desktop Entry]
Name=U-Claw AI Assistant
Comment=OpenClaw AI - Plug and Play
Exec=/opt/u-claw/start-openclaw.sh
Terminal=true
Type=Application
Categories=Utility;
DESKTOPEOF

cp "$DESKTOP_FILE" "$APPS_DIR/openclaw.desktop"
chmod +x "$DESKTOP_FILE"
chown "$REAL_USER:$REAL_USER" "$DESKTOP_FILE"
chown "$REAL_USER:$REAL_USER" "$APPS_DIR/openclaw.desktop"
# Mark as trusted on GNOME
sudo -u "$REAL_USER" gio set "$DESKTOP_FILE" metadata::trusted true 2>/dev/null || true
echo "      Desktop shortcut installed."

# ── 10. Optional: autostart ──
echo "[9/9] Setup complete!"
echo ""
read -rp "Enable autostart on login? (y/N): " AUTOSTART
if [[ "$AUTOSTART" =~ ^[Yy]$ ]]; then
    AUTOSTART_DIR="$REAL_HOME/.config/autostart"
    mkdir -p "$AUTOSTART_DIR"
    cp "$APPS_DIR/openclaw.desktop" "$AUTOSTART_DIR/openclaw.desktop"
    chown "$REAL_USER:$REAL_USER" "$AUTOSTART_DIR/openclaw.desktop"
    echo "      Autostart enabled."
fi

# ── Set ownership ──
chown -R "$REAL_USER:$REAL_USER" "$INSTALL_DIR/data"

echo ""
echo "============================================"
echo "  Installation Complete!"
echo "============================================"
echo ""
echo "  Node.js:   $($NODE_BIN --version)"
echo "  Install:   $INSTALL_DIR"
echo "  Config:    $INSTALL_DIR/data/.openclaw/openclaw.json"
echo ""
echo "  To start:  Double-click 'U-Claw AI Assistant' on desktop"
echo "         or: bash $INSTALL_DIR/start-openclaw.sh"
echo ""
echo "  First time? Configure your AI model in the browser after startup."
echo "============================================"
