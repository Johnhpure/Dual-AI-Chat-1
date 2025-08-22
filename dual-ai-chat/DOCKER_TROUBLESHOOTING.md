# Docker部署故障排除指南

本文档提供了在部署Dual-AI-Chat应用时可能遇到的Docker相关问题的解决方案。

## 常见问题

### 1. Docker Compose版本兼容性问题

**症状:** 运行`docker-compose up -d`时出现`KeyError: 'ContainerConfig'`错误。

```
ERROR: for dual-ai-chat  'ContainerConfig'
Traceback (most recent call last):
  ...
KeyError: 'ContainerConfig'
Failed to execute script docker-compose
```

**原因:** 这通常是由于服务器上的Docker Compose版本较旧，与配置文件中的某些高级功能不兼容导致的。

**解决方案:**

#### 方案1: 使用简化版docker-compose.yml

我们提供了一个简化版的docker-compose配置文件，兼容旧版Docker Compose:

```bash
# 使用简化版配置文件
docker-compose -f docker-compose.simple.yml up -d
```

#### 方案2: 使用docker-run.sh脚本

如果Docker Compose仍然无法正常工作，可以使用我们提供的直接使用Docker命令的脚本:

```bash
# 添加执行权限
chmod +x docker-run.sh

# 运行脚本
./docker-run.sh
```

#### 方案3: 更新Docker Compose

如果条件允许，建议更新Docker Compose到最新版本:

```bash
# 移除旧版本
sudo rm /usr/local/bin/docker-compose

# 安装最新版本
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 验证安装
docker-compose --version
```

### 2. 端口冲突问题

**症状:** 启动容器时提示端口已被占用。

```
ERROR: for dual-ai-chat_dual-ai-chat_1  Cannot start service dual-ai-chat: driver failed programming external connectivity on endpoint dual-ai-chat_dual-ai-chat_1: Bind for 0.0.0.0:8080 failed: port is already allocated
```

**解决方案:**

1. 查找占用端口的进程:
   ```bash
   sudo netstat -tulpn | grep 8080
   # 或者
   sudo lsof -i :8080
   ```

2. 停止占用端口的进程:
   ```bash
   sudo kill <进程ID>
   ```

3. 或者修改端口映射:
   - 在docker-compose.yml中将`8080:80`改为其他端口，如`8081:80`
   - 或者在运行docker-run.sh时修改PORT变量:
     ```bash
     PORT=8081 ./docker-run.sh
     ```

## 使用local-deploy.sh脚本

我们的`local-deploy.sh`脚本已经更新，可以自动处理Docker Compose兼容性问题:

```bash
# 添加执行权限
chmod +x local-deploy.sh

# 运行脚本
sudo ./local-deploy.sh
```

脚本会自动尝试以下方法:
1. 使用标准docker-compose命令
2. 如果失败，尝试使用简化版docker-compose.yml
3. 如果仍然失败，尝试使用docker-run.sh脚本

## 手动部署步骤

如果上述方法都不起作用，您可以按照以下步骤手动部署:

1. 构建Docker镜像:
   ```bash
   docker build -t dual-ai-chat .
   ```

2. 运行容器:
   ```bash
   docker run -d -p 8080:80 --name dual-ai-chat dual-ai-chat
   ```

3. 访问应用:
   ```
   http://服务器IP:8080
   ```

4. 在应用设置中配置API密钥
