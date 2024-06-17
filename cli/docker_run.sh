#!/bin/env bash
# 批量启动容器镜像代理
# https://github.com/fimreal/registry-proxy/blob/main/cli/docker_run.sh
# last motified at 20240617

################## 自定义配置 ####################
# 指定启动工具
# podman or docker
crcli="podman"
# 自定义网络名称
network_name="registry-proxy"
# 执行代理地址
# name remote_address listen_port listen_ui_port
# myregistry https://remote.registry.io 5000 80
proxy_dict=(
    "k8sr https://registry.k8s.io 5000 5080"
    "gcr https://k8s.gcr.io 5001 5081"
    "quay https://quay.io 5002 5082"
    "dockerhub https://registry.docker.io 5003 5083"
    "ghcr https://ghcr.io 5004 5084"
    # "rhcr https://registry.access.redhat.com 5005 5085"
    # "ecr https://public.ecr.aws 5006 5086"
)
#################################################

batch_run() {
    $crcli network create ${network_name}
    for job in ${proxy_dict[@]}; do
        set -- $job
        name=$1
        remote_address=$2
        listen_port=$3
        listen_ui_port=$4
        run_registry "${name}" "${remote_address}" "${listen_port}"
        run_registry_ui "${name}" "${listen_ui_port}" "${listen_port}"
        echo -e "\033[1;34m[INFO] registry-${name} starting\033[0m"
    done
}

batch_clean() {
    for job in "${proxy_dict[@]}"; do
        set -- $job
        name=$1
        ${crcli} stop "registry-${name}" && ${crcli} rm "registry-${name}"
        ${crcli} stop "registry-${name}-ui" && ${crcli} rm "registry-${name}-ui"
        echo -e "\033[1;34m[INFO] registry-${name} stopping\033[0m"
    done
    $crcli network rm $network_name
}

function run_registry() {
    name=${1}
    remote_address=${2}
    listen_port=${3}
    
    ${crcli} run -d --name registry-${name} \
        --restart always \
        --network $network_name \
        -p ${listen_port}:5000 \
        -e REGISTRY_PROXY_REMOTEURL=${remote_address} \
        -e REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY="/var/lib/registry" \
        -e REGISTRY_STORAGE_DELETE_ENABLED="true" \
        -e REGISTRY_HTTP_HEADERS_ACCESS-CONTROL-ALLOW-ORIGIN="['*']" \
        -e REGISTRY_HTTP_HEADERS_ACCESS-CONTROL-ALLOW-METHOD="['HEAD', 'GET', 'OPTIONS', 'DELETE']" \
        -e REGISTRY_HTTP_HEADERS_ACCESS-CONTROL-ALLOW-HEADERS="['Authorization', 'Accept', 'Cache-Control', 'Docker-Content-Digest']" \
        -e REGISTRY_HTTP_HEADERS_ACCESS-CONTROL-EXPOSE-HEADERS="['Docker-Content-Digest']" \
        registry:2
}

function run_registry_ui() {
    name=${1}
    listen_ui_port=${2}
    registry_port=${3}

    # epurs/registry-ui: amd64 or arm64 
    ${crcli} run -d --name registry-${name}-ui \
        --restart always \
        --network $network_name \
        -p ${listen_ui_port}：80 \
        -e REGISTRY_HOST="registry-${name}:${registry_port}" \
        -e REGISTRY_SSL=false \
        -e REGISTRY_STORAGE_DELETE_ENABLED=true \
        epurs/registry-ui
}

# 初始化检查
# find container runtime cli
if ! command -v ${crcli} &>/dev/null; then
    echo -e "\033[1;31m[ERR] ${crcli} command not found.\033[0m\n"
    exit 1
fi
# 确保容器运行时支持重启
if "${crcli}" == "podman"; then
    systemctl enable podman-restart.service
fi
# 检查当前 shell 是否支持数组
if ! declare -a test_array >/dev/null 2>&1; then
    echo -e "\033[1;31m[ERR] This script requires a shell with array support, please use bash re-run script\033[0m\n"
    exit 1
fi

case "$1" in
    "clean")
        echo -e "\033[1;35m[WARN] clean all registry-proxy\033[0m"
        batch_clean
        ;;
    "run"|*)
        echo -e "\033[1;34m[INFO] start all registry-proxy\033[0m"
        batch_run
        ;;
esac