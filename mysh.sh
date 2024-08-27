#!/bin/bash

cd /home
echo "请选择要执行的操作："
echo "1. 执行方法一"
echo "2. 执行方法二"

read -p "请输入您的选择: " choice

case $choice in
    1)
        echo "您选择了方法一"
		ls -la
        ;;
    2)
        echo "您选择了方法二"
        ;;
    *)
        echo "已退出。"
        ;;
esac
