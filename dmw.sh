# 安装docker
install_docker() {
    #查看架构
    arch=$(dpkg --print-architecture)
    echo $arch
    # 删除旧包
    apt-get remove docker docker-engine docker.io containerd runc
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

# 检查 Docker 服务状态
startbuild() {
    systemctl status docker | grep 'running' >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Docker服务正在运行，执行后续操作"
        echo "创建网络mynet"
        docker network create --driver bridge --subnet 192.168.0.0/24 --gateway 192.168.0.1 mynet
        echo "创建npm容器"
        docker run --privileged=true -itd --restart=always --name=npm -p 80:80 -p 81:81 -p 443:443 --network=mynet --ip 192.168.0.2 -v /opt/dockerservice/npm/data:/data -v /opt/dockerservice/npm/letsencrypt:/etc/letsencrypt jc21/nginx-proxy-manager:latest
        echo "创建mysql容器"
        docker run --privileged=true -itd --restart=always --name mysqlwp -p 33306:3306 --network=mynet --ip 192.168.0.3 -v /opt/dockerservice/mysql:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=lanlongning -e MYSQL_DATABASE=wordpressdb -e MYSQL_AUTHENTICATION_PLUGIN=mysql_native_password mysql:latest
        echo "创建wordpress容器"
        docker run --privileged=true -itd --restart=always --name=wp --network=mynet --ip 192.168.0.4 -v /opt/dockerservice/wordpress:/var/www/html -e WORDPRESS_DB_HOST=192.168.0.3:3306 -e WORDPRESS_DB_USER=root -e WORDPRESS_DB_PASSWORD=lanlongning -e WORDPRESS_DB_NAME=wordpressdb wordpress
    else
        echo "Docker服务未运行"
    fi
}

# 安装docker
install_docker
# 调用函数检查状态
startbuild 
