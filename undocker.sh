#!/bin/bash

# 检查docker服务是否存在
if ! command -v docker &>/dev/null; then
    echo "Docker服务不存在"
    exit 1
fi

# 检查 Docker 服务是否正在运行
if ! systemctl is-active docker; then
    echo "Docker服务未运行，正在启动..."
    systemctl start docker
    if ! systemctl is-active docker; then
        echo "启动 Docker 服务失败，正在卸载 Docker..."
        exit 1
    else
        echo "Docker 服务启动成功！"
    fi
else
    echo "Docker 运行中"
fi
