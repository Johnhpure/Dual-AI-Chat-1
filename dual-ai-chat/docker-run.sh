#!/bin/bash

# 直接使用Docker命令启动Dual-AI-Chat应用的脚本
# 此脚本用于避免Docker Compose兼容性问题

# 设置变量
CONTAINER_NAME="dual-ai-chat"
IMAGE_NAME="dual-ai-chat"
PORT="8080"

echo "===== Dual-AI-Chat Docker部署脚本 ====="

# 检查是否已存在同名容器，如果有则停止并移除
if [ "$(docker ps -a -q -f name=^/${CONTAINER_NAME}$)" ]; then
  echo "停止并移除现有容器..."
  docker stop ${CONTAINER_NAME} > /dev/null 2>&1
  docker rm ${CONTAINER_NAME} > /dev/null 2>&1
fi

# 检查是否需要构建镜像
echo "检查镜像..."
if [[ "$(docker images -q ${IMAGE_NAME} 2> /dev/null)" == "" ]]; then
  echo "构建Docker镜像..."
  docker build -t ${IMAGE_NAME} .
else
  read -p "是否重新构建镜像? (y/n) [默认: n]: " REBUILD
  if [[ "$REBUILD" == "y" || "$REBUILD" == "Y" ]]; then
    echo "重新构建Docker镜像..."
    docker build -t ${IMAGE_NAME} .
  fi
fi

# 启动容器
echo "启动容器..."
docker run -d \
  --name ${CONTAINER_NAME} \
  -p ${PORT}:80 \
  --restart unless-stopped \
  ${IMAGE_NAME}

# 检查容器是否成功启动
if [ $? -eq 0 ]; then
  echo "===== 部署成功! ====="
  echo "应用现在可以通过以下地址访问:"
  echo "http://$(hostname -I | awk '{print $1}'):${PORT}"
  echo "或者 http://localhost:${PORT} (如果在本地访问)"
  echo ""
  echo "请在应用设置中配置API密钥。"
else
  echo "===== 部署失败! ====="
  echo "请检查Docker日志获取更多信息:"
  echo "docker logs ${CONTAINER_NAME}"
fi
