#!/bin/bash
# =====================================================
#  Настройка новой машины Vast.ai для работы с ComfyUI
#  Запуск:  bash /workspace/setup.sh
# =====================================================

COMFY=/workspace/ComfyUI
PY=/venv/main/bin/python
[ -x "$PY" ] || PY=python3

CKPT_DIR=$COMFY/models/checkpoints
LORA_DIR=$COMFY/models/loras
NODES_DIR=$COMFY/custom_nodes

MODEL_FILE=illustriousXL_v01.safetensors
MODEL_URL="https://huggingface.co/Drditone/safetensors/resolve/main/illustriousXL_v01.safetensors"

KKAMJA_FILE=kkamja.safetensors

POSE_FILE=dynamic-pose-illustriousxl-lora-nochekaiser.safetensors
POSE_VERSION_ID=1722309

echo ""
echo "=== 0. Проверка, что ComfyUI на месте ==="
if [ ! -d "$COMFY" ]; then
  echo "ОШИБКА: папки $COMFY нет. Выполни: ls /workspace   и напиши мне, что показалось."
  exit 1
fi
echo "OK: $COMFY найдена"

# ---------- проверка целостности LoRA ----------
check_lora() {
  "$PY" - "$1" <<'EOF'
import sys
try:
    from safetensors import safe_open
    with safe_open(sys.argv[1], framework="pt") as f:
        for k in f.keys():
            f.get_tensor(k)
    print("OK")
except Exception as e:
    print("BAD:", e)
    sys.exit(1)
EOF
}

echo ""
echo "=== 1. Модель illustriousXL (около 6.5 ГБ) ==="
mkdir -p "$CKPT_DIR"
MODEL_SIZE=$(stat -c%s "$CKPT_DIR/$MODEL_FILE" 2>/dev/null || echo 0)
if [ "$MODEL_SIZE" -gt 6000000000 ]; then
  echo "Модель уже скачана, пропускаю."
else
  echo "Скачиваю модель, это несколько минут..."
  wget -c -O "$CKPT_DIR/$MODEL_FILE" "$MODEL_URL"
fi

echo ""
echo "=== 2. Дополнения (custom nodes) ==="
cd "$NODES_DIR" || exit 1
[ -d efficiency-nodes-comfyui ] || git clone https://github.com/jags111/efficiency-nodes-comfyui.git
[ -d rgthree-comfy ]            || git clone https://github.com/rgthree/rgthree-comfy.git
[ -d was-node-suite-comfyui ]   || git clone https://github.com/WASasquatch/was-node-suite-comfyui.git

echo "Ставлю то, что нужно дополнениям для работы..."
[ -f efficiency-nodes-comfyui/requirements.txt ] && pip install -q -r efficiency-nodes-comfyui/requirements.txt
[ -f was-node-suite-comfyui/requirements.txt ]   && pip install -q -r was-node-suite-comfyui/requirements.txt

echo ""
echo "=== 3. LoRA kkamja ==="
mkdir -p "$LORA_DIR"
if [ -s "$LORA_DIR/$KKAMJA_FILE" ] && check_lora "$LORA_DIR/$KKAMJA_FILE" >/dev/null 2>&1; then
  echo "kkamja уже на месте и целая, пропускаю."
else
  echo ">>> kkamja загрузи вручную через Jupyter (Upload) в workspace/ComfyUI/models/loras"
fi

echo ""
echo "=== 4. LoRA dynamic pose ==="
if [ -s "$LORA_DIR/$POSE_FILE" ] && check_lora "$LORA_DIR/$POSE_FILE" >/dev/null 2>&1; then
  echo "dynamic pose уже на месте и целая, пропускаю."
else
  rm -f "$LORA_DIR/$POSE_FILE"
  echo ">>> Эту LoRA загрузи вручную: скачай с Civitai на компьютер, назови"
  echo ">>> $POSE_FILE"
  echo ">>> и загрузи через Jupyter (Upload) в workspace/ComfyUI/models/loras"
fi

echo ""
echo "=== 5. ИТОГОВАЯ ПРОВЕРКА ==="
echo "--- Модель:"
ls -lh "$CKPT_DIR/$MODEL_FILE" 2>/dev/null || echo "НЕТ МОДЕЛИ!"
echo "--- LoRA:"
for f in "$KKAMJA_FILE" "$POSE_FILE"; do
  if [ -s "$LORA_DIR/$f" ]; then
    echo "[ОК]   $f  ($(du -h "$LORA_DIR/$f" | cut -f1))"
  else
    echo "[НЕТ]  $f  <- загрузи вручную через Upload"
  fi
done
echo "--- Дополнения:"
for d in efficiency-nodes-comfyui rgthree-comfy was-node-suite-comfyui; do
  [ -d "$NODES_DIR/$d" ] && echo "[ОК]   $d" || echo "[НЕТ]  $d"
done

echo ""
echo "=== ГОТОВО ==="
echo "Дальше: в ComfyUI нажми Manager -> Restart, подожди минуту, потом Ctrl+F5."
