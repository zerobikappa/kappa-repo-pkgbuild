#!/bin/bash

function set-env() {
    if [[ -n "${XDG_CACHE_HOME}" ]];
    then
        SETUP_DIR="${XDG_CACHE_HOME}"/facefusion
    else
        SETUP_DIR="${HOME}"/.cache/facefusion
    fi
    
}

function reset-cache() {
    echo "setup to ${SETUP_DIR}"
    mkdir -p "${SETUP_DIR}"/conda-env

    source /opt/miniconda3/etc/profile.d/conda.sh
    
    #if [[ "${LOCAL_FACEFUSION_PYTHON_VERSION}" != "${FACEFUSION_PYTHON_VERSION}" ]] || [[ "${LOCAL_FACEFUSION_PIP_VERSION}" != "${FACEFUSION_PIP_VERSION}" ]];then
        conda create --prefix "${SETUP_DIR}"/conda-env -y python="${FACEFUSION_PYTHON_VERSION}" pip="${FACEFUSION_PIP_VERSION}"
    #fi
    
    conda activate "${SETUP_DIR}"/conda-env

    if [[ "${LOCAL_FACEFUSION_INSTALL_VERSION}" != "${FACEFUSION_INSTALL_VERSION}" ]];then
        rm -rf "${SETUP_DIR}"/facefusion
        cp -r /opt/facefusion/facefusion "${SETUP_DIR}"
    fi
    mkdir -p "${SETUP_DIR}"/assets
    ln -sf ../assets "${SETUP_DIR}"/facefusion/.assets
    
    SAVE_PWD="$(pwd)"
    if [[ "${FACEFUSION_INSTALL_SELECT}" == "cuda" ]];then
        conda install -y nvidia/label/cuda-12.9.1::cuda-runtime nvidia/label/cudnn-9.10.0::cudnn
        pip install tensorrt==10.12.0.36 --extra-index-url https://pypi.nvidia.com
        cd "${SETUP_DIR}"/facefusion || exit
        python install.py --onnxruntime cuda
    elif [[ "${FACEFUSION_INSTALL_SELECT}" == "rocm" ]];then
        conda install -y conda-forge::gcc=15.2.0
        cd "${SETUP_DIR}"/facefusion || exit
        python install.py --onnxruntime migraphx
    elif [[ "${FACEFUSION_INSTALL_SELECT}" == "openvino" ]];then
        conda install -y conda-forge::openvino=2025.3.0
        cd "${SETUP_DIR}"/facefusion || exit
        python install.py --onnxruntime openvino
    else
        cd "${SETUP_DIR}"/facefusion || exit
        python install.py --onnxruntime default
    fi
    cd "${SAVE_PWD}" || exit
    unset SAVE_PWD

    conda deactivate

    cp -f /opt/facefusion/facefusion_version "${SETUP_DIR}"/facefusion_version
    
}


set-env
if [[ ! -d "${SETUP_DIR}"/facefusion ]];then
    source /opt/facefusion/facefusion_version
    reset-cache
elif
    [[ ! -f "${SETUP_DIR}"/facefusion_version ]];then
    source /opt/facefusion/facefusion_version
    reset-cache
elif
    [[ -n "$(diff "${SETUP_DIR}/facefusion_version" /opt/facefusion/facefusion_version)" ]];then
    source "${SETUP_DIR}/facefusion_version"
    LOCAL_FACEFUSION_INSTALL_VERSION="${FACEFUSION_INSTALL_VERSION}"
    LOCAL_FACEFUSION_PYTHON_VERSION="${FACEFUSION_PYTHON_VERSION}"
    LOCAL_FACEFUSION_PIP_VERSION="${FACEFUSION_PIP_VERSION}"
    source /opt/facefusion/facefusion_version
    reset-cache
fi

source /opt/miniconda3/etc/profile.d/conda.sh
export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1
conda activate "${SETUP_DIR}"/conda-env
cd "${SETUP_DIR}"/facefusion || exit
python facefusion.py "$@"


