# 第一阶段：构建应用
FROM node:20-alpine AS build

# 设置工作目录
WORKDIR /app

# 复制package.json和package-lock.json
COPY package*.json ./

# 安装依赖，使用缓存优化
RUN npm ci --production && \
    # 如果你需要开发依赖来构建，则添加：
    npm ci && \
    # 清理npm缓存以减少镜像大小
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
    chown -R appuser:appuser /var/run/nginx.pid

# 切换到非root用户
USER appuser

# 暴露端口
EXPOSE 80

# 启动Nginx
CMD ["nginx", "-g", "daemon off;"]
