#!/usr/bin/env bash
# ============================================================
#  U-Claw OpenClaw Startup Script (Linux)
#  Completely self-contained — no external file dependencies
# ============================================================

set -euo pipefail

INSTALL_DIR="/opt/u-claw"
NODE_BIN="$INSTALL_DIR/runtime/node-linux-x64/bin/node"
CORE_DIR="$INSTALL_DIR/core"
DATA_DIR="$INSTALL_DIR/data"

export OPENCLAW_HOME="$DATA_DIR/.openclaw"
export OPENCLAW_STATE_DIR="$DATA_DIR/.openclaw"
export OPENCLAW_CONFIG_PATH="$DATA_DIR/.openclaw/openclaw.json"

# --- Sanity checks ---
if [[ ! -x "$NODE_BIN" ]]; then
    echo "[ERROR] Node.js not found at $NODE_BIN"
    echo "Please run setup-openclaw.sh first."
    read -rp "Press Enter to exit..."
    exit 1
fi

if [[ ! -d "$CORE_DIR/node_modules/openclaw" ]]; then
    echo "[ERROR] OpenClaw not installed in $CORE_DIR"
    echo "Please run setup-openclaw.sh first."
    read -rp "Press Enter to exit..."
    exit 1
fi

# --- Find available port in 18789-18799 ---
PORT=""
for p in $(seq 18789 18799); do
    if ! ss -tlnp 2>/dev/null | grep -q ":${p} "; then
        PORT="$p"
        break
    fi
done

if [[ -z "$PORT" ]]; then
    echo "[ERROR] All ports 18789-18799 are in use."
    read -rp "Press Enter to exit..."
    exit 1
fi

echo "============================================"
echo "  U-Claw AI Assistant"
echo "  Starting on port $PORT ..."
echo "============================================"

# --- Check if model is configured ---
CONFIG_FILE="$OPENCLAW_CONFIG_PATH"
FIRST_RUN=false
if [[ ! -f "$CONFIG_FILE" ]] || ! grep -q '"apiKey"' "$CONFIG_FILE" 2>/dev/null; then
    FIRST_RUN=true
    echo ""
    echo "[INFO] No AI model configured yet."
    echo "       After startup, please configure your model in the browser."
    echo ""
fi

# --- Start OpenClaw gateway ---
cd "$CORE_DIR"
OPENCLAW_ENTRY=$(find node_modules/openclaw -name "openclaw.mjs" -maxdepth 2 2>/dev/null | head -1)

if [[ -z "$OPENCLAW_ENTRY" ]]; then
    echo "[ERROR] Cannot find openclaw.mjs entry point."
    read -rp "Press Enter to exit..."
    exit 1
fi

echo "Opening browser at http://localhost:$PORT ..."

# Open browser after a short delay
(sleep 3 && xdg-open "http://localhost:$PORT" 2>/dev/null) &

"$NODE_BIN" "$OPENCLAW_ENTRY" gateway run \
    --allow-unconfigured \
    --force \
    --port "$PORT"
