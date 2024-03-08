#!/bin/bash

# Use this layer to add nodes and models

# Packages are installed after nodes so we can fix them...
PYTHON_PACKAGES=(
    "opencv-python==4.7.0.72"
    "onnxruntime-gpu"
)

NODES=(
    "https://github.com/ltdrdata/ComfyUI-Manager"
    "https://github.com/cubiq/ComfyUI_IPAdapter_plus"
    "https://github.com/Gourieff/comfyui-reactor-node"
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack"
    "https://github.com/Fannovel16/comfyui_controlnet_aux"
    "https://github.com/Acly/comfyui-tooling-nodes"
)

CHECKPOINT_MODELS=(
    "https://huggingface.co/RunDiffusion/Juggernaut-XL-v8/resolve/main/juggernautXL_v8Rundiffusion.safetensors"
    "https://huggingface.co/RunDiffusion/Juggernaut-XL-v9/resolve/main/Juggernaut-XL_v9_RunDiffusionPhoto_v2.safetensors"
    )

LORA_MODELS=(
    "https://huggingface.co/aadinash/lora/resolve/main/VIBRANTWAVYSWEATER-000006.safetensors"
)

VAE_MODELS=(
)

ESRGAN_MODELS=(
)

CONTROLNET_MODELS=(
    "https://huggingface.co/stabilityai/control-lora/resolve/main/control-LoRAs-rank128/control-lora-depth-rank128.safetensors"
)

IPADAPTER_MODELS=(
    "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter_sdxl_vit-h.safetensors"
)

CLIPVISION_MODELS=(
    "https://huggingface.co/h94/IP-Adapter/resolve/main/models/image_encoder/model.safetensors"
)

FACERESTORE_MODELS=(
    "https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/facerestore_models/GFPGANv1.3.pth"
    "https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/facerestore_models/GFPGANv1.4.pth"
    "https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/facerestore_models/codeformer-v0.1.0.pth"
)

SWAP_MODELS=(
"https://huggingface.co/datasets/Gourieff/ReActor/resolve/main/models/inswapper_128.onnx"
)

### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING ###

function build_extra_start() {
    build_extra_get_nodes
    build_extra_install_python_packages
    build_extra_get_models \
        "/opt/storage/stable_diffusion/models/ckpt" \
        "${CHECKPOINT_MODELS[@]}"
    build_extra_get_models \
        "/opt/storage/stable_diffusion/models/lora" \
        "${LORA_MODELS[@]}"
    build_extra_get_models \
        "/opt/storage/stable_diffusion/models/controlnet" \
        "${CONTROLNET_MODELS[@]}"
    build_extra_get_models \
        "/opt/storage/stable_diffusion/models/vae" \
        "${VAE_MODELS[@]}"
    build_extra_get_models \
        "/opt/storage/stable_diffusion/models/esrgan" \
        "${ESRGAN_MODELS[@]}"
    build_extra_get_models \
        "/opt/storage/stable_diffusion/models/ipadapter" \
        "${IPADAPTER_MODELS[@]}"
    build_extra_get_models \
        "/opt/storage/stable_diffusion/models/clip_vision" \
        "${CLIPVISION_MODELS[@]}"
    build_extra_get_models \
        "/opt/storage/stable_diffusion/models/facerestore" \
        "${FACERESTORE_MODELS[@]}"
    build_extra_get_models \
        "/opt/storage/stable_diffusion/models/insightface" \
        "${SWAP_MODELS[@]}"
     
    cd /opt/ComfyUI && \
    micromamba run -n comfyui -e LD_PRELOAD=libtcmalloc.so python main.py \
        --cpu \
        --listen 127.0.0.1 \
        --port 11404 \
        --disable-auto-launch \
        --quick-test-for-ci
    
    # Ensure pytorch hasn't been clobbered
    $MAMBA_DEFAULT_RUN python /opt/ai-dock/tests/assert-torch-version.py
}

function build_extra_get_nodes() {
    for repo in "${NODES[@]}"; do
        dir="${repo##*/}"
        path="/opt/ComfyUI/custom_nodes/${dir}"
        requirements="${path}/requirements.txt"
        if [[ -d $path ]]; then
            if [[ ${AUTO_UPDATE,,} != "false" ]]; then
                printf "Updating node: %s...\n" "${repo}"
                ( cd "$path" && git pull )
                if [[ -e $requirements ]]; then
                    micromamba -n comfyui run ${PIP_INSTALL} -r "$requirements"
                fi
            fi
        else
            printf "Downloading node: %s...\n" "${repo}"
            git clone "${repo}" "${path}" --recursive
            if [[ -e $requirements ]]; then
                micromamba -n comfyui run ${PIP_INSTALL} -r "${requirements}"
            fi
        fi
    done
}

function build_extra_install_python_packages() {
    if [ ${#PYTHON_PACKAGES[@]} -gt 0 ]; then
        micromamba -n comfyui run ${PIP_INSTALL} ${PYTHON_PACKAGES[*]}
    fi
}

function build_extra_get_models() {
    if [[ -n $2 ]]; then
        dir="$1"
        mkdir -p "$dir"
        shift
        arr=("$@")
        
        printf "Downloading %s model(s) to %s...\n" "${#arr[@]}" "$dir"
        for url in "${arr[@]}"; do
            printf "Downloading: %s\n" "${url}"
            build_extra_download "${url}" "${dir}"
            printf "\n"
        done
    fi
}

# Download from $1 URL to $2 file path
function build_extra_download() {
    wget -qnc --content-disposition --show-progress -e dotbytes="${3:-4M}" -P "$2" "$1"
}

umask 002

build_extra_start
fix-permissions.sh -o container