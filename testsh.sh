#!/bin/bash

function get_next_available_ip() {
    local network_name="$1"
    local subnet_mask="$2" # 可选参数，用于指定子网掩码

    # 获取网络信息
    network_info=$(docker network inspect "$network_name" 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "网络 '$network_name' 不存在"
        return 1
    fi

    # 提取子网掩码
    if [ -z "$subnet_mask" ]; then
        subnet_mask=$(echo "$network_info" | jq -r '.[0].IPAM.Config[0].Subnet' | cut -d/ -f2)
    fi

    # 提取所有容器的IP地址
    ips=$(echo "$network_info" | jq -r '.[0].Containers[].IPv4Address')

    # 将IP地址按点分十进制排序
    IFS='.' read -ra max_ip <<<$(echo "$ips" | sort -V | tail -n 1)

    # 计算下一个IP地址
    ((max_ip[3]++))
    for ((i = 3; i >= 0; i--)); do
        if [ ${max_ip[$i]} -gt 255 ]; then
            ((max_ip[$i] = 0))
            ((max_ip[$i - 1]++))
        fi
    done

    # 将IP各部分拼接成字符串
    new_ip="${max_ip[*]}"

    # 验证IP是否在子网范围内
    if ! validate_ip "$new_ip" "$subnet_mask"; then
        echo "生成的IP不在子网范围内"
        return 1
    fi

    echo "$new_ip"
}

# 验证IP是否在子网范围内
function validate_ip() {
    local ip="$1"
    local subnet_mask="$2"
    # ... 使用ipcalc等工具或自行实现逻辑进行验证 ...
    return 0 # 验证通过
}

# 示例用法
network_name="mynet"
subnet_mask="24" # 可以省略，会自动从网络信息中获取
next_ip=$(get_next_available_ip "$network_name" "$subnet_mask")
if [ $? -eq 0 ]; then
    echo "下一个可用IP：$next_ip"
fi
