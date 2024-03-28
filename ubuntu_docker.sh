# 安装docker
install_docker(){
   #查看架构
   arch=$(dpkg --print-architecture)
   echo $arch
   # 删除旧包
   apt-get remove docker docker-engine docker.io containerd runc
   # 删除link的文件夹
      rm -rf /home/data/docker
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
                        mkdir -p /home/data/docker
                        echo "将原docker的文件移动到新的位置"
                        mv /var/lib/docker/* /home/data/docker
                        echo "进入原docker路径下"
                        cd /var/lib
                        echo "删除docker文件夹"
                        rm -rf docker
                        echo "添加原docker路径的link到新的位置"
                        ln -s /home/data/docker/ /var/lib/docker
                        echo "查看link文件夹的内容，确定link起效"
                        ls -la docker
                        echo "回到root"
                        cd
                        echo "启动docker"
                        systemctl restart docker
                        echo "查看docker状态"
                        systemctl --no-pager status docker
	fi
}

install_docker