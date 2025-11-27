# Nextcloud Kubernetes 集群部署

这是一个完整的 Nextcloud 云存储解决方案在 Kubernetes 集群上的部署配置，包含 MySQL 主从复制、Redis 缓存和 NFS 存储支持。

## 🚀 功能特性

- **完整的 Nextcloud 套件**: 包含 Web 应用、数据库和缓存层
- **高可用数据库**: MySQL 主从复制架构
- **性能优化**: Redis 缓存支持
- **持久化存储**: 基于 NFS 的动态存储供应
- **资源管理**: 资源配额和限制范围
- **健康检查**: 完整的应用健康监控
- **分步部署**: 支持检查点的可靠部署流程

## 📋 前置要求

### 系统要求

- Kubernetes 集群 (v1.19+)
- kubectl 配置和集群访问权限
- NFS 服务器 (192.168.28.30:/data/nfs-sc)
- Docker 镜像仓库访问
### 资源要求

- CPU: 请求 4核，限制 6核
- 内存: 请求 6Gi，限制 12Gi
- 存储: 至少 31Gi NFS 存储空间

## 🗂 项目结构

```txt
.
├── 1-namespace.yaml              # 命名空间配置
├── 2-ResourceQuota.yaml          # 资源配额
├── 3-limitRange.yaml             # 限制范围
├── 4-rbac.yaml                   # NFS Provisioner RBAC
├── 5-deployment.yaml             # NFS Provisioner 部署
├── 6-sc.yaml                     # 存储类配置
├── 7-pvc.yaml                    # 持久卷声明
├── 8-1-mysql-master.yaml         # MySQL 主节点
├── 8-2-mysql-slave.yaml          # MySQL 从节点
├── 9-1-redis-config.yaml         # Redis 配置
├── 9-2-redis-deployment.yaml     # Redis 部署
├── 10-1-secrets.yaml             # 密钥配置
├── 10-2-nextcloud-cm.yaml        # Nextcloud 配置映射
├── 10-3-nextcloud-deployment.yaml # Nextcloud 部署
├── 10-4-nextcloud-php.yaml       # PHP 配置
├── 10-4-nextcloud-service.yaml   # Nextcloud 服务
├── deploy.sh                     # 自动化部署脚本
├── check-deploy-status.sh        # 部署状态检查脚本
└── reset-deploy.sh               # 重置部署脚本
```

## 🔧 配置说明

### 网络配置

- **Nextcloud Service**: NodePort 32048
- **MySQL Master**: Headless 服务，端口 3306
- **MySQL Slave**: Headless 服务，端口 3306
- **Redis**: 集群内部服务，端口 6379
### 存储配置

- **StorageClass**: `nfs-client`
- **PVC 分配**:
    - MySQL Master: 10Gi
    - MySQL Slave: 10Gi
    - Nextcloud: 10Gi
    - Redis: 1Gi

### 数据库配置

- **主从复制**: 自动配置  
- **字符集**: utf8mb4
- **连接数**: 最大 100
- **缓冲池**: Master 512M, Slave 256M

## 🛠 部署步骤

### 快速部署
```bash
# 授予执行权限
chmod +x deploy.sh check-deploy-status.sh reset-deploy.sh

# 开始部署
./deploy.sh

# 强制重新部署（如需要）
./deploy.sh true
```

### 分步部署
```bash
# 1. 创建命名空间和资源限制
    
    kubectl apply -f 1-namespace.yaml
    kubectl apply -f 2-ResourceQuota.yaml -f 3-limitRange.yaml
    
# 2. 部署存储基础设施
    
    kubectl apply -f 4-rbac.yaml
    kubectl apply -f 5-deployment.yaml
    kubectl apply -f 6-sc.yaml
    
# 3. 创建持久化存储
    
    kubectl apply -f 7-pvc.yaml
    
# 4. 部署数据库层
    
    kubectl apply -f 8-1-mysql-master.yaml
    kubectl apply -f 8-2-mysql-slave.yaml
    
# 5. 部署缓存层
    
    kubectl apply -f 9-1-redis-config.yaml
    kubectl apply -f 9-2-redis-deployment.yaml
    
# 6. 部署 Nextcloud 应用
    
    kubectl apply -f 10-1-secrets.yaml
    kubectl apply -f 10-2-nextcloud-cm.yaml
    kubectl apply -f 10-3-nextcloud-deployment.yaml
    kubectl apply -f 10-4-nextcloud-php.yaml
    kubectl apply -f 10-4-nextcloud-service.yaml
    # 部署nextcloud pod时，因应用初始化时间较久，未在yaml文件中设置相应的健康检查，待pod Running之后，可以根据一下命令对日志进行查看，待日志更新后代表初始化完成。
    kubectl logs -f -l app=nextcloud -n nextcloud 
```

## 📊 监控和管理

```bash
### 检查部署状态
./check-deploy-status.sh
### 查看所有资源

kubectl get all -n nextcloud
### 查看 Pod 状态

kubectl get pods -n nextcloud -o wide
### 查看服务

kubectl get svc -n nextcloud

### 查看存储

kubectl get pvc -n nextcloud
kubectl get pv

### 查看日志

# Nextcloud 日志
kubectl logs -l app=nextcloud -n nextcloud --tail=50

# MySQL Master 日志
kubectl logs mysql-master-0 -n nextcloud --tail=50
# Redis 日志
kubectl logs -l app=redis -n nextcloud --tail=50
```

## 🔄 故障排查

### 常见问题

1. **NFS Provisioner 无法启动**
    
    - 检查 NFS 服务器连通性  
    - 验证 NFS 路径权限
2. **MySQL 主从复制失败**
    
    - 检查网络连通性
    - 验证复制用户权限
    - 查看 MySQL 错误日志
3. **Nextcloud 无法连接数据库**
    
    - 检查服务发现
    - 验证数据库凭据
    - 确认网络策略
### 重置部署

```bash
# 重置检查点
./reset-deploy.sh

# 完全重置（删除所有资源）
./reset-deploy.sh
# 然后选择选项 3

# 前往NFS节点手动对持久化数据删除
```
## 🌐 访问应用

### 访问方式

1. **NodePort 访问**
    
    http://<节点IP>:32048
### 初始配置

首次访问时需要完成 Nextcloud 安装向导：

- **管理员账户**: 自定义用户名和密码
- **数据库配置**:
    - 数据库类型: MySQL/MariaDB
    - 数据库主机: `mysql-master`
    - 数据库名: `nextcloud`
    - 数据库用户: `nextcloud`
    - 数据库密码: `password`
- **可选 Redis 配置**（提升性能）:
	- 主机: `redis`
    - 端口: `6379`
	- 密码: `password`

#注释 若nextcloud平台中无redis相关配置选项，可按照[redis单点配置.md]方式手动进行添加


## 🔒 安全说明

- 所有敏感信息通过 Secret 管理
- 数据库使用独立密码
- Redis 配置了密码保护 
- 服务使用最小权限原则

## 📝 注意事项

1. **生产环境建议**:
    
    - 配置 TLS 证书
    - 设置合适的备份策略
    - 配置监控和告警
    - 使用企业级存储方案
2. **性能优化**:
    
    - 根据负载调整资源限制
    - 配置 PHP OPcache
    - 使用 Redis 进行会话和文件锁定
3. **数据持久化**:
    
    - 定期备份 NFS 存储
    - 监控存储使用情况
    - 配置数据库备份

## 📞 支持

如遇到部署问题，请检查：

1. Kubernetes 集群状态
2. NFS 服务器连通性
3. 资源配额是否足够
4. 容器镜像可访问性

查看详细日志获取具体错误信息。
