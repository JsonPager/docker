#!/bin/bash

cd /home
echo "请选择要执行的操作："
echo "1. 自动安装Docker+MPN+MySql+Wordpress"
echo "2. 卸载Docker"

while true; do
    read -p "请输入您的选择: " choice
    case $choice in
    1)
        echo "您选择了方法一"
        # ls
        ;;
    2)
        echo "您选择了方法二"
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
