#!/bin/bash
set -e

# Путь к ComfyUI (на шаблонах vast обычно /workspace/ComfyUI)
COMFY=/workspace/ComfyUI

cd $COMFY

# --- Frontend 1.24.3+ и gdown (для скачивания с Google Drive) ---
pip install -U comfyui-frontend-package gdown

# --- Кастомные ноды ---
cd $COMFY/custom_nodes
git clone https://github.com/jags111/efficiency-nodes-comfyui || true
git clone https://github.com/rgthree/rgthree-comfy || true
git clone https://github.com/WASasquatch/was-node-suite-comfyui || true

for d in efficiency-nodes-comfyui rgthree-comfy was-node-suite-comfyui; do
  [ -f $d/requirements.txt ] && pip install -r $d/requirements.txt
done

# --- Чекпоинт (качается в фоне, пока идёт остальное) ---
cd $COMFY/models/checkpoints
wget -c -q --show-progress \
  https://huggingface.co/Drditone/safetensors/resolve/main/illustriousXL_v01.safetensors &

# --- Лора kkamja ---
cd $COMFY/models/loras
gdown 1_9v5722HWTNptNMC9VLmQSBMY8E5wloX -O kkamja.safetensors

# --- Воркфлоу ---
mkdir -p $COMFY/user/default/workflows
gdown --folder 1gUXftM015_2r2Zq5t1WcFcgLZhqi892t -O $COMFY/user/default/workflows

# Ждём, пока докачается чекпоинт
wait
echo "ГОТОВО. Загрузи лору dynamic-pose вручную в models/loras и перезапусти ComfyUI."
