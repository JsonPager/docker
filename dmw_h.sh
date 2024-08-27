#!/bin/bash

# 安装docker
install_docker() {
    #查看架构
    arch=$(dpkg --print-architecture)
    echo $arch
    # 删除旧包
    apt-get remove docker docker-ce docker-ce-cli containerd.io docker-engine docker.io containerd runc
    # 删除link的文件夹
    rm -rf /opt/docker
    rm -rf /var/lib/docker
    #首先，更新软件包索引，并且安装必要的依赖软件，来添加一个新的 HTTPS 软件源
    apt update -y
    apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    #导入源仓库的 GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    #Docker APT 软件源添加到你的系统
    sudo add-apt-repository -y "deb [arch=$arch] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    #更新软件包索引，安装 Docker 最新版本
    apt update -y
    apt install -y docker-ce docker-ce-cli containerd.io
    echo "安装完成，查看服务状态"
    systemctl --no-pager status docker
    echo "查看版本号"
    docker -v
    read -p "检查服务及版本状态，确认是否继续安装 ? [Y/n] :" yn
    [ -z "${yn}" ] && yn="y"
    if [[ $yn == [Yy] ]]; then
        echo "停止服务"
        systemctl stop docker
        echo "创建新的docker路径"
        mkdir -p /opt/docker
        echo "将原docker的文件移动到新的位置"
        mv /var/lib/docker/* /opt/docker
        echo "进入原docker路径下"
        cd /var/lib
        echo "删除docker文件夹"
        rm -rf docker
        echo "添加原docker路径的link到新的位置"
        ln -s /opt/docker/ /var/lib/docker
        echo "查看link文件夹的内容，确定link起效"
        ls -la docker
        echo "回到root"
        cd
        echo "启动docker"
        systemctl restart docker
        echo "查看docker状态"
        systemctl --no-pager status docker
        echo "设置docker自启动"
        systemctl enable docker
    fi
}

# 检测mynet网络是否存在
function check_network() {
    network_exists=$(docker network ls -q --filter name=mynet 2>/dev/null)
    
    if [[ -z "$network_exists" ]]; then       
        echo 1
    else
        echo 0
    fi
}

# 定义检查容器是否存在的方法
function check_container_exists() {
    container_name="$1" # 获取传入的容器名称

    # 检查容器是否存在，并返回结果
    if docker inspect -f '{{.Name}}' "$container_name" >/dev/null 2>&1; then
        # 容器存在，返回0
        return 0
    else
        # 容器不存在，返回1
        return 1
    fi
}

# 生成一个新的mynetip地址
function getmynetnewip() {

    # 获取网络名称
    local network_name="mynet"

    # 获取所有容器的 IPv4 地址，并去除子网掩码
    local ips=($(docker network inspect "$network_name" | jq -r '.[0].Containers[].IPv4Address' | cut -d/ -f1))

    # 打印数组中的每个 IP 地址
    #for ip in "${ips[@]}"; do
    #    echo "$ip"
    #done

    # 按字典序排序，最大的 IP 会排在最后
    local sorted_ips=($(echo "${ips[@]}" | sort -V))

    # 取出最后一个元素，即最大的 IP
    local max_ip="${sorted_ips[-1]}"

    #echo "最大的 IP 地址是：$max_ip"

    IFS='.' read -ra ip_parts <<<"$max_ip"

    # 对最低位加 1，并处理进位
    ((ip_parts[3]++))
    for ((i = 3; i >= 1; i--)); do
        if [ ${ip_parts[$i]} -gt 255 ]; then
            ((ip_parts[$i] %= 256))
            ((ip_parts[$i - 1]++))
        fi
    done

    # 将四段重新组合成 IP 地址
    # new_ip="${ip_parts[*]}"
    local new_ip=$(
        IFS='.'
        echo "${ip_parts[*]}"
    )

    echo "$new_ip"
}

# 生成一个本地未被使用的随机端口号
function get_unused_port() {
    local start_port=1024
    local end_port=65535
    local port

    # 随机生成一个端口号
    port=$(shuf -i "$start_port-$end_port" -n 1)

    # 检查端口是否被占用，并重试直到找到空闲端口
    while true; do
        if ! netstat -tulnp | grep -q ":${port}/"; then
            break # 端口未被占用，退出循环
        fi
        # 端口被占用，重新生成随机端口
        port=$(shuf -i "$start_port-$end_port" -n 1)
    done

    echo "$port"
}

# 检查docker服务是否存在，确定docker服务运行
if command -v docker &>/dev/null; then
    echo "Docker服务已存在"
    # 检查 Docker 服务是否正在运行
    if ! systemctl is-active docker; then
        echo "Docker服务未运行，正在启动..."
        systemctl start docker
        if ! systemctl is-active docker; then
            echo "启动 Docker 服务失败，退出安装..."
            exit 1
        else
            echo "Docker 服务启动成功！"
        fi
    else
        echo "Docker 运行中"
    fi
else
    echo "未检测到Docker服务，开始安装"
    # 安装docker
    install_docker

    if ! systemctl is-active docker; then
        echo "启动 Docker 服务失败，退出安装..."
        exit 1
    fi
fi

sleep 5

# 检测网络是否存在，不存在就创建网络
checknetresult=$(check_network)
if [[ $checknetresult -eq 0 ]]; then
    echo "已存在mynet网络"
else
    echo "创建mynet网络"
    docker network create --driver bridge --subnet 192.168.0.0/24 --gateway 192.168.0.1 mynet
fi

# 检查npm是否存在，不存在就创建npm
if check_container_exists "npm"; then
    echo "容器npm已存在"
else
    echo "容器npm不存在,创建npm容器,默认ip(192.168.0.2)，默认端口(81)"
    docker run --privileged=true -itd --restart=always --name=npm -p 80:80 -p 81:81 -p 443:443 --network=mynet --ip 192.168.0.2 -v /opt/dockerservice/npm/data:/data -v /opt/dockerservice/npm/letsencrypt:/etc/letsencrypt jc21/nginx-proxy-manager:latest
fi

# 设置mysql容器名称
while true; do
    read -p "请输入mysql容器名称:" container_mysql
    if [ -z "$container_mysql" ]; then
        echo "请输入容器名称"
        continue
    fi
    if check_container_exists "$container_mysql"; then
        echo "容器 $container_mysql 存在"
        continue
    fi
    break
done

# 设置mysql数据库名称
while true; do
    read -p "请输入mysql数据库名称:" mysql_dbname
    if [ -z "$mysql_dbname" ]; then
        echo "请输入数据库名称"
        continue
    fi
    if [ ${#mysql_dbname} -lt 9 ]; then
        echo "长度需要大于等于9"
        continue
    fi
    break
done

# 设置mysql数据库密码
while true; do
    read -p "请输入mysql数据库密码:" mysql_passwd
    if [ -z "$mysql_passwd" ]; then
        echo "请输入数据库密码"
        continue
    fi
    if [ ${#mysql_passwd} -lt 9 ]; then
        echo "长度需要大于等于9"
        continue
    fi
    break
done

# 设置mysql内网ip
mysqlip=$(getmynetnewip)
# 设置mysql外网映射端口号
mysqlport=$(get_unused_port)

echo "创建mysql容器"
docker run --privileged=true -itd --restart=always --name "$container_mysql" -p "$mysqlport":3306 --network=mynet --ip "$mysqlip" -v /opt/dockerservice/"$container_mysql":/var/lib/mysql -e MYSQL_ROOT_PASSWORD="$mysql_passwd" -e MYSQL_DATABASE="$mysql_dbname" -e MYSQL_AUTHENTICATION_PLUGIN=mysql_native_password mysql:latest
echo "创建mysql容器完成,重新启动容器"

docker restart $container_mysql

# 设置wordpress容器名称
while true; do
    read -p "请输入wordpress容器名称:" container_wordpress
    if [ -z "$container_wordpress" ]; then
        echo "请输入容器名称"
        continue
    fi
    if check_container_exists "$container_wordpress"; then
        echo "容器 $container_wordpress 存在"
        continue
    fi
    break
done

# 设置wordpress内网ip
wordpressip=$(getmynetnewip)
# 设置wordpress外网映射端口号
wordpressport=$(get_unused_port)

echo "创建wordpress容器"
docker run --privileged=true -itd --restart=always --name="$container_wordpress" -p "$wordpressport":80 --network=mynet --ip "$wordpressip" -v /opt/dockerservice/"$container_wordpress":/var/www/html -e WORDPRESS_DB_HOST="$mysqlip":3306 -e WORDPRESS_DB_USER=root -e WORDPRESS_DB_PASSWORD="$mysql_passwd" -e WORDPRESS_DB_NAME="$mysql_dbname" wordpress
echo "创建wordpress容器完成"

docker restart $container_wordpress

echo "mysql数据库:$mysql_dbname ,用户名:root, 密码: $mysql_passwd ,内网ip:$mysqlip ,外网映射端口: $mysqlport"
echo "wordpress内网ip:$wordpressip ,外网映射端口:$wordpressport"

# 开始构建容器
# startbuild
