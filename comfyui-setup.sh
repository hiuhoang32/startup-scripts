#!/bin/bash
# Exit on any error
set -e

echo "============================================"
echo "ComfyUI Setup Script"
echo "============================================"
echo ""

# ------------------------------
# 1. Download from DigitalOcean Spaces
# ------------------------------
MODEL_URL="https://comfyui-retouch-model.tor1.digitaloceanspaces.com/Model.7z"
DOWNLOAD_FILE="Model.7z"
CLONE_DIR="$HOME/ps-cos-v2"

echo "[1/5] Downloading model from DigitalOcean Spaces..."
echo "-------------------------------------------"

# Install required tools
echo "Installing required tools (wget, p7zip)..."
sudo apt update
sudo apt install -y wget p7zip-full

# Remove old directory if exists
if [ -d "$CLONE_DIR" ]; then
    echo "Directory $CLONE_DIR already exists. Removing old version..."
    rm -rf "$CLONE_DIR"
fi

# Create directory
mkdir -p "$CLONE_DIR"
cd "$CLONE_DIR"

# Download file
echo "Downloading from: $MODEL_URL"
wget -O "$DOWNLOAD_FILE" "$MODEL_URL"

# Extract 7z archive
echo "Extracting $DOWNLOAD_FILE..."
7z x "$DOWNLOAD_FILE"

# Remove downloaded archive to save space
echo "Removing archive file..."
rm "$DOWNLOAD_FILE"

echo "Model downloaded and extracted successfully"
echo ""

# ------------------------------
# 2. Locate ComfyUI folder
# ------------------------------
echo "[2/5] Locating ComfyUI folder..."
echo "-------------------------------------------"

COMFYUI_DIR="$CLONE_DIR/ComfyUI"

if [ ! -d "$COMFYUI_DIR" ]; then
    echo "Error: ComfyUI folder not found at $COMFYUI_DIR"
    echo "Checking for alternative paths..."
    # Try to find ComfyUI in extracted files
    COMFYUI_DIR=$(find "$CLONE_DIR" -type d -name "ComfyUI" -print -quit)
    if [ -z "$COMFYUI_DIR" ]; then
        echo "Error: Could not locate ComfyUI folder"
        exit 1
    fi
fi

cd "$COMFYUI_DIR"
echo "Found ComfyUI at: $COMFYUI_DIR"
echo ""

# ------------------------------
# 3. System dependencies
# ------------------------------
echo "[3/5] Installing system dependencies..."
echo "-------------------------------------------"

sudo apt update

# Ensure Python 3.11 exists
if ! command -v python3.11 &> /dev/null; then
    echo "Python 3.11 not found. Installing..."
    sudo apt install -y software-properties-common
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt update
    sudo apt install -y python3.11 python3.11-venv python3.11-dev
else
    echo "Python 3.11 is already installed."
fi

# ------------------------------
# 4. Virtualenv + Python deps
# ------------------------------
if [ ! -d "venv" ]; then
    echo "Creating virtual environment with Python 3.11..."
    python3.11 -m venv venv
fi

# shellcheck disable=SC1091
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

echo ""
echo "[4/5] Installing Python dependencies..."
echo "-------------------------------------------"

# PyTorch with CUDA 12.1
echo "Installing PyTorch with CUDA 12.1..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# xformers build deps (system)
echo "Installing xformers build dependencies (system)..."
sudo apt install -y ninja-build build-essential cmake git python3.11-dev

# xformers build deps (Python)
echo "Installing xformers build dependencies (Python)..."
pip install --upgrade wheel setuptools ninja

# xformers itself
echo "Installing latest xformers..."
pip install --upgrade xformers

# ComfyUI requirements
if [ -f "requirements.txt" ]; then
    echo "Installing requirements from requirements.txt..."
    pip install -r requirements.txt
else
    echo "Warning: requirements.txt not found in $COMFYUI_DIR"
    echo "Skipping requirements.txt installation..."
fi

# ------------------------------
# 5. Start ComfyUI
# ------------------------------
echo ""
echo "[5/5] Starting ComfyUI..."
echo "-------------------------------------------"
echo "ComfyUI will start now. Access it at http://127.0.0.1:8188"
echo ""

python main.py
