#!/bin/bash

# Dual-AI-Chat 修复部署脚本
# 此脚本用于修复容器重启问题并重新部署应用

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 配置
CONTAINER_NAME="dual-ai-chat"
IMAGE_NAME="dual-ai-chat-fixed"
PORT="8081"
DEPLOY_DIR="/home/app"

echo -e "${GREEN}===== Dual-AI-Chat 修复部署脚本 =====${NC}"
echo ""

# 检查是否在正确的目录
if [ ! -f "Dockerfile.root" ]; then
  echo -e "${RED}错误: 找不到Dockerfile.root文件${NC}"
  echo "请确保您在项目根目录中运行此脚本"
  exit 1
fi

# 停止并删除现有容器
echo -e "${YELLOW}停止并删除现有容器...${NC}"
docker stop app_dual-ai-chat_1 &>/dev/null || true
docker rm app_dual-ai-chat_1 &>/dev/null || true
docker stop ${CONTAINER_NAME} &>/dev/null || true
docker rm ${CONTAINER_NAME} &>/dev/null || true

# 构建新镜像
echo -e "${YELLOW}使用修复版Dockerfile构建新镜像...${NC}"
docker build -t ${IMAGE_NAME} -f Dockerfile.root .

if [ $? -ne 0 ]; then
  echo -e "${RED}错误: 构建镜像失败${NC}"
  exit 1
fi

# 启动新容器
echo -e "${YELLOW}启动新容器...${NC}"
docker run -d \
  --name ${CONTAINER_NAME} \
  -p ${PORT}:80 \
  --restart unless-stopped \
  ${IMAGE_NAME}

if [ $? -ne 0 ]; then
  echo -e "${RED}错误: 启动容器失败${NC}"
  exit 1
fi

# 等待容器启动
echo -e "${YELLOW}等待容器启动...${NC}"
sleep 3

# 检查容器状态
CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' ${CONTAINER_NAME})

if [ "$CONTAINER_STATUS" != "running" ]; then
  echo -e "${RED}错误: 容器未正常运行，状态为 ${CONTAINER_STATUS}${NC}"
  echo "请检查容器日志获取更多信息:"
  echo "docker logs ${CONTAINER_NAME}"
  exit 1
fi

# 获取服务器IP
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo -e "${GREEN}===== 部署成功! =====${NC}"
echo ""
echo -e "应用现在可以通过以下地址访问:"
echo -e "${GREEN}http://${SERVER_IP}:${PORT}${NC}"
echo ""
echo "请在应用设置中配置API密钥。"
echo ""
echo "容器管理命令:"
echo "  查看容器状态: docker ps"
echo "  查看容器日志: docker logs ${CONTAINER_NAME}"
echo "  停止容器: docker stop ${CONTAINER_NAME}"
echo "  启动容器: docker start ${CONTAINER_NAME}"
echo ""
