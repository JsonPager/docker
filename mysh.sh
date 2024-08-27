#!/bin/bash

cd /home
echo "请选择要执行的操作："
echo "1. 自动安装Docker+MPN+MySql+Wordpress"
echo "2. 卸载Docker"
echo "3. 退出"

while true; do
    read -p "请输入您的选择: " choice
    case $choice in
    1)
        echo "自动安装Docker+MPN+MySql+Wordpress"
        curl -L https://raw.githubusercontent.com/JsonPager/docker/main/dmw.sh -o dmw.sh && chmod +x dmw.sh && ./dmw.sh
        # ls
        ;;
    2)
        echo "卸载Docker"
        curl -L https://raw.githubusercontent.com/JsonPager/docker/main/undocker.sh -o undocker.sh && chmod +x undocker.sh && ./undocker.sh
        ;;
    3)
        echo "退出"
        exit 1
        ;;
    *)
        echo "无效输入"
        ;;
    esac
done
