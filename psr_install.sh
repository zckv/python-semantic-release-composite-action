#!/bin/bash

set -eux

install_pipx(){
    read -r os_like< <(grep -Po "(?<=ID_LIKE=).*" /etc/os-release)
    case ${os_like} in
        debian)
            apt install pipx;;
        fedora)
            dnf install pipx;;
        *)
            echo "Runner OS not supported, BEST EFFORT"
            pip install pipx;;
    esac
}

install_psr(){
    if ! command -v pipx &> /dev/null; then
        install_pipx
    fi

    if [ -z "$INPUT_PSR_VERSION" ]; then
      pipx install python-semantic-release
    else
      pipx install "python-semantic-release==$INPUT_PSR_VERSION"
    fi

    pipx ensurepath
}


if ! command -v semantic-release &> /dev/null; then
    echo "Semantic-release not found, will try to install using pipx"
    install_psr
fi
