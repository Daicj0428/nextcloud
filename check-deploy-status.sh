#!/bin/bash

NAMESPACE="nextcloud"
CHECKPOINT_FILE="/tmp/nextcloud_deploy_checkpoint"

echo "=== Nextcloud 部署状态检查 ==="

# 检查检查点
if [[ -f $CHECKPOINT_FILE ]]; then
    CURRENT_CHECKPOINT=$(cat $CHECKPOINT_FILE)
    echo "当前检查点: $CURRENT_CHECKPOINT"
else
    echo "当前检查点: 未开始 或 已完成"
fi

echo ""
echo "=== 资源状态 ==="
echo "命名空间:"
kubectl get ns $NAMESPACE 2>/dev/null && echo "✓ 存在" || echo "✗ 不存在"

echo ""
echo "Pod状态:"
kubectl get pods -n $NAMESPACE

echo ""
echo "PVC状态:"
kubectl get pvc -n $NAMESPACE

echo ""
echo "服务状态:"
kubectl get svc -n $NAMESPACE

echo ""
echo "=== 健康检查 ==="
# 检查关键服务
services=("mysql-master" "mysql-slave" "redis-cluster" "nextcloud")
for service in "${services[@]}"; do
    if kubectl get deployment,statefulset -n $NAMESPACE | grep -q "$service"; then
        echo "✓ $service: 已部署"
    else
        echo "✗ $service: 未部署"
    fi
done
