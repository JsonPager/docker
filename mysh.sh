#!/bin/bash

echo "请选择要执行的操作："
echo "1. 执行方法一"
echo "2. 执行方法二"

read -p "请输入您的选择: " choice

case $choice in
    1)
        echo "您选择了方法一"
        ;;
    2)
        echo "您选择了方法二"
        ;;
    *)
        echo "无效的选择，请重新输入。"
        ;;
esac
