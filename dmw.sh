# 获取当前主机名
hostname=$(hostname)

# 检查 Docker 服务状态
check_docker_status() {
  ssh root@${hostname} "systemctl status docker | grep 'running'" > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "Docker 服务在 $hostname 上正在运行"
  else
    echo "Docker 服务在 $hostname 上未运行"
  fi
}

# 调用函数检查状态
check_docker_status

# 根据检查结果执行后续操作
# 例如：
if [ $? -eq 0 ]; then
  # 如果 Docker 正在运行，执行其他操作
  echo "执行其他操作，例如启动容器..."
else
  # 如果 Docker 未运行，执行其他操作
  echo "启动 Docker 服务..."
  # ssh root@${hostname} "systemctl start docker"
fi
