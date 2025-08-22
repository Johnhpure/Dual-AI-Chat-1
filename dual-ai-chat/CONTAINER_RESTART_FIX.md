# 容器重启问题解决方案

本文档提供了解决Dual-AI-Chat应用容器不断重启问题的详细说明和解决方案。

## 问题描述

部署Dual-AI-Chat应用后，容器状态显示为"restarting"，无法正常运行。通过`docker inspect`命令可以看到以下关键信息：

- 容器状态：`"Status": "restarting"`
- 退出代码：`"ExitCode": 1`
- 用户设置：`"User": "appuser"`（非root用户）
- 重启次数：`"RestartCount": 10`（多次尝试重启）

## 问题原因

经过分析，问题的主要原因是**使用非root用户运行Nginx导致的权限问题**。在Dockerfile中，我们使用了`appuser`非root用户来运行Nginx，但在某些Linux系统上，这可能导致以下权限问题：

1. 无法访问必要的系统文件和目录
2. 无法写入日志文件
3. 无法创建PID文件
4. 无法绑定低端口（如80端口）

## 解决方案

### 方案1：使用root用户运行Nginx（推荐）

这是最简单直接的解决方案，通过修改Dockerfile，移除非root用户设置。

1. 使用提供的`Dockerfile.root`文件：
   ```bash
   # 在项目根目录执行
   cd /home/app
   
   # 使用fix-deploy.sh脚本自动修复和部署
   ./fix-deploy.sh
   ```

2. 或者手动执行以下步骤：
   ```bash
   # 停止并删除现有容器
   docker stop app_dual-ai-chat_1
   docker rm app_dual-ai-chat_1
   
   # 使用修复版Dockerfile构建新镜像
   docker build -t dual-ai-chat-fixed -f Dockerfile.root .
   
   # 启动新容器
   docker run -d \
     --name dual-ai-chat \
     -p 8081:80 \
     --restart unless-stopped \
     dual-ai-chat-fixed
   ```

### 方案2：修复非root用户的权限问题

如果您出于安全考虑，希望继续使用非root用户运行Nginx，可以尝试以下解决方案：

1. 创建一个修复权限问题的Dockerfile：
   ```bash
   cat > Dockerfile.permissions << 'EOF'
   # 第一阶段：构建应用
   FROM node:20-alpine AS build
   
   # 设置工作目录
   WORKDIR /app
   
   # 复制package.json和package-lock.json
   COPY package*.json ./
   
   # 安装依赖，使用缓存优化
   RUN npm ci --production && \
       npm ci && \
       npm cache clean --force
   
   # 复制源代码
   COPY . .
   
   # 创建.env文件（如果不存在）
   RUN touch .env
   
   # 构建应用
   RUN VITE_APP_VERSION=$(date -u +'%Y%m%d-%H%M%S') npm run build
   
   # 第二阶段：部署到Nginx
   FROM nginx:stable-alpine
   
   # 添加非root用户来运行Nginx
   RUN adduser -D -u 1000 appuser
   
   # 从构建阶段复制构建产物到Nginx服务目录
   COPY --from=build /app/dist /usr/share/nginx/html
   
   # 复制自定义Nginx配置
   COPY nginx.conf /etc/nginx/conf.d/default.conf
   
   # 修改目录权限
   RUN chown -R appuser:appuser /usr/share/nginx/html && \
       chown -R appuser:appuser /var/cache/nginx && \
       chown -R appuser:appuser /var/log/nginx && \
       chown -R appuser:appuser /etc/nginx/conf.d && \
       touch /var/run/nginx.pid && \
       chown -R appuser:appuser /var/run/nginx.pid && \
       # 确保nginx可以写入临时目录
       mkdir -p /tmp/nginx && \
       chown -R appuser:appuser /tmp/nginx && \
       # 修改nginx.conf以使用/tmp/nginx作为临时目录
       sed -i 's|^pid.*|pid /tmp/nginx/nginx.pid;|' /etc/nginx/nginx.conf && \
       # 确保日志目录存在并有正确权限
       mkdir -p /var/log/nginx && \
       chown -R appuser:appuser /var/log/nginx && \
       # 修改run目录权限
       mkdir -p /var/run/nginx && \
       chown -R appuser:appuser /var/run/nginx
   
   # 切换到非root用户
   USER appuser
   
   # 暴露端口
   EXPOSE 80
   
   # 启动Nginx
   CMD ["nginx", "-g", "daemon off;"]
   EOF
   
   # 构建和运行
   docker build -t dual-ai-chat-secure -f Dockerfile.permissions .
   docker run -d --name dual-ai-chat -p 8081:80 --restart unless-stopped dual-ai-chat-secure
   ```

## 验证部署

无论使用哪种方法，部署后都可以通过以下方式验证：

```bash
# 检查容器状态
docker ps

# 查看容器日志
docker logs dual-ai-chat

# 测试应用访问
curl http://localhost:8081
```

应用应该可以通过`http://服务器IP:8081`访问，然后您可以在应用设置中配置API密钥。

## 预防措施

为避免未来遇到类似问题，建议：

1. 在开发和测试环境中使用相同的Docker配置
2. 在部署前测试容器的健康检查
3. 如果需要使用非root用户，确保正确配置所有必要的权限
4. 保持Docker和Docker Compose版本的一致性
