#!/bin/bash

# Exit on any error
set -e

echo "============================================"
echo "ComfyUI Setup Script"
echo "============================================"
echo ""

# Clone repository
REPO_ID="r3zenix/ps-cos-v2"
CLONE_DIR="$HOME/ps-cos-v2"

echo "[1/5] Downloading repository using HuggingFace Hub..."
echo "-------------------------------------------"

# Install huggingface_hub (CLI)
echo "Installing huggingface_hub..."
pip3 install -U "huggingface_hub[cli]"

# Clean old clone if exists
if [ -d "$CLONE_DIR" ]; then
    echo "Directory already exists. Removing old version..."
    rm -rf "$CLONE_DIR"
fi

echo "Downloading repository to: $CLONE_DIR"
# NOTE: On your hf CLI, --local-dir-use-symlinks is NOT available, so we don't use it.
hf download "$REPO_ID" --local-dir "$CLONE_DIR"
echo "Repository downloaded successfully"
echo ""

# Navigate to ComfyUI folder
echo "[2/5] Locating ComfyUI folder..."
echo "-------------------------------------------"
COMFYUI_DIR="$CLONE_DIR/ComfyUI"

if [ ! -d "$COMFYUI_DIR" ]; then
    echo "Error: ComfyUI folder not found at $COMFYUI_DIR"
    exit 1
fi

cd "$COMFYUI_DIR"
echo "Found ComfyUI at: $COMFYUI_DIR"
echo ""

# Install system dependencies
echo "[3/5] Installing system dependencies..."
echo "-------------------------------------------"
sudo apt update

# Check if Python 3.11 is installed
if ! command -v python3.11 &> /dev/null; then
    echo "Python 3.11 not found. Installing..."
    sudo apt install -y software-properties-common
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt update
    sudo apt install -y python3.11 python3.11-venv python3.11-dev
else
    echo "Python 3.11 is already installed."
fi

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment with Python 3.11..."
    python3.11 -m venv venv
fi

# Activate virtual environment
# shellcheck disable=SC1091
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

echo ""
echo "[4/5] Installing Python dependencies..."
echo "-------------------------------------------"

# Install PyTorch with CUDA support first (CUDA 12.1 wheels)
echo "Installing PyTorch with CUDA 12.1..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Install xformers build dependencies
echo "Installing xformers build dependencies (system)..."
sudo apt install -y ninja-build build-essential cmake git python3.11-dev

echo "Installing xformers build dependencies (Python)..."
pip install --upgrade wheel setuptools ninja

# Install xformers (latest)
echo "Installing latest xformers..."
pip install --upgrade xformers

# Install requirements from requirements.txt if it exists
if [ -f "requirements.txt" ]; then
    echo "Installing requirements from requirements.txt..."
    pip install -r requirements.txt
else
    echo "Warning: requirements.txt not found in $COMFYUI_DIR"
    echo "Skipping requirements.txt installation..."
fi

echo ""
echo "[5/5] Starting ComfyUI..."
echo "-------------------------------------------"
echo "ComfyUI will start now. Access it at http://127.0.0.1:8188"
echo ""

# Run ComfyUI
python main.py
