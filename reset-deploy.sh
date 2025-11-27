#!/bin/bash

CHECKPOINT_FILE="/tmp/nextcloud_deploy_checkpoint"
NAMESPACE="nextcloud"

echo "重置部署状态..."

if [[ -f $CHECKPOINT_FILE ]]; then
    CURRENT_CHECKPOINT=$(cat $CHECKPOINT_FILE)
    echo "删除检查点文件 (当前检查点: $CURRENT_CHECKPOINT)"
    rm -f $CHECKPOINT_FILE
    echo "检查点文件已删除"
else
    echo "没有找到检查点文件，无需重置"
fi

echo ""
echo "可选操作:"
echo "1. 只重置检查点 (已完成)"
echo "2. 删除Nextcloud资源并重置"
echo "3. 删除所有资源并完全重置"
read -p "请选择 (1/2/3): " choice

case $choice in
    2)
        echo "删除Nextcloud资源..."
        kubectl delete deployment nextcloud -n $NAMESPACE --ignore-not-found=true
        kubectl delete deployment redis -n $NAMESPACE --ignore-not-found=true
        kubectl delete service nextcloud -n $NAMESPACE --ignore-not-found=true
        kubectl delete service redis -n $NAMESPACE --ignore-not-found=true
        kubectl delete configmap nextcloud-config -n $NAMESPACE --ignore-not-found=true
        kubectl delete configmap nextcloud-php-config -n $NAMESPACE --ignore-not-found=true
        kubectl delete configmap redis-config -n $NAMESPACE --ignore-not-found=true
        echo "Nextcloud资源删除完成"
        ;;
    3)
        echo "删除所有Nextcloud命名空间资源..."
        kubectl delete namespace $NAMESPACE --ignore-not-found=true
        echo "资源删除完成"
        ;;
    *)
        echo "只重置检查点完成"
        ;;
esac
