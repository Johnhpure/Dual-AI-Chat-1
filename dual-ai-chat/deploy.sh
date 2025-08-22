#!/bin/bash

# 部署Dual-AI-Chat到服务器的脚本
# 使用方法: ./deploy.sh [服务器IP] [用户名]

# 默认值
SERVER_IP=${1:-"47.79.145.239"}
USERNAME=${2:-"root"}

echo "开始部署Dual-AI-Chat到服务器: $SERVER_IP"

# 确保.env文件存在
if [ ! -f ".env" ]; then
  echo "错误: .env文件不存在。请先创建.env文件。"
  echo "可以复制docker-env.example为.env并填写API密钥。"
  exit 1
fi

# 打包项目文件
echo "打包项目文件..."
tar -czf dual-ai-chat.tar.gz \
  --exclude=node_modules \
  --exclude=.git \
  --exclude=dist \
  .

# 上传到服务器
echo "上传文件到服务器..."
scp dual-ai-chat.tar.gz $USERNAME@$SERVER_IP:/tmp/

# 在服务器上执行部署
echo "在服务器上执行部署..."
ssh $USERNAME@$SERVER_IP << 'ENDSSH'
  # 创建部署目录
  mkdir -p /opt/dual-ai-chat
  
  # 解压文件
  tar -xzf /tmp/dual-ai-chat.tar.gz -C /opt/dual-ai-chat
  
  # 进入项目目录
  cd /opt/dual-ai-chat
  
  # 构建并启动Docker容器
  docker-compose down
  docker-compose up -d --build
  
  # 清理临时文件
  rm /tmp/dual-ai-chat.tar.gz
  
  echo "部署完成！应用现在应该在http://$HOSTNAME:8080上运行"
ENDSSH

# 清理本地临时文件
rm dual-ai-chat.tar.gz

echo "部署脚本执行完毕"
echo "应用应该在http://$SERVER_IP:8080上运行"
