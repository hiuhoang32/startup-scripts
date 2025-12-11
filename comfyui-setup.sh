#!/bin/bash

# Exit on any error
set -e

echo "============================================"
echo "ComfyUI Setup Script"
echo "============================================"
echo ""

# Clone repository
REPO_URL="https://huggingface.co/r3zenix/ps-cos-v2"
CLONE_DIR="$HOME/ps-cos-v2"

echo "[1/5] Cloning repository..."
echo "-------------------------------------------"

# Install git-lfs if not present
if ! command -v git-lfs &> /dev/null; then
    echo "Installing git-lfs..."
    apt update
    apt install -y git-lfs
fi

if [ -d "$CLONE_DIR" ]; then
    echo "Directory already exists. Removing old version..."
    rm -rf "$CLONE_DIR"
fi

cd "$HOME"
git lfs install
git clone "$REPO_URL"
echo "Repository cloned to: $CLONE_DIR"
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

# Install dependencies
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
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

echo ""
echo "[4/5] Installing Python dependencies..."
echo "-------------------------------------------"

# Install PyTorch with CUDA support first
echo "Installing PyTorch with CUDA 12.1..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Install xformers
echo "Installing xformers..."
pip install xformers

# Install requirements from requirements.txt if it exists
if [ -f "requirements.txt" ]; then
    echo "Installing requirements from requirements.txt..."
    pip install -r requirements.txt
else
    echo "Warning: requirements.txt not found in $COMFYUI_DIR"
    echo "Installing common ComfyUI dependencies..."
    pip install -r requirements.txt 2>/dev/null || echo "Continuing without requirements.txt..."
fi

echo ""
echo "[5/5] Starting ComfyUI..."
echo "-------------------------------------------"
echo "ComfyUI will start now. Access it at http://127.0.0.1:8188"
echo ""

# Run ComfyUI
python main.py
