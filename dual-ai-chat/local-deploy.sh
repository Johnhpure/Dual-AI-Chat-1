#!/bin/bash

# Dual-AI-Chat 一键部署脚本 - 用于本地物理服务器
# 作者: Claude
# 版本: 1.0

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志文件
LOG_FILE="deploy-$(date +%Y%m%d-%H%M%S).log"

# 默认配置
DEFAULT_PORT=8080
DEFAULT_DEPLOY_DIR="/opt/dual-ai-chat"
DEFAULT_GEMINI_API_KEY=""
DEFAULT_OPENAI_API_KEY=""
DEFAULT_OPENAI_BASE_URL="https://api.openai.com"

# 日志函数
log() {
  local level=$1
  local message=$2
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  
  case $level in
    "INFO")
      echo -e "${GREEN}[INFO]${NC} $message"
      ;;
    "WARN")
      echo -e "${YELLOW}[WARN]${NC} $message"
      ;;
    "ERROR")
      echo -e "${RED}[ERROR]${NC} $message"
      ;;
    *)
      echo -e "${BLUE}[DEBUG]${NC} $message"
      ;;
  esac
  
  echo "[$timestamp] [$level] $message" >> $LOG_FILE
}

# 检查命令是否存在
check_command() {
  if ! command -v $1 &> /dev/null; then
    log "ERROR" "$1 未安装，请先安装 $1"
    return 1
  fi
  return 0
}

# 检查环境
check_environment() {
  log "INFO" "检查环境..."
  
  # 检查Docker
  if ! check_command docker; then
    log "ERROR" "请先安装Docker: https://docs.docker.com/engine/install/"
    return 1
  fi
  
  # 检查Docker Compose
  if ! check_command docker-compose; then
    log "ERROR" "请先安装Docker Compose: https://docs.docker.com/compose/install/"
    return 1
  fi
  
  # 检查其他依赖
  for cmd in curl tar grep sed; do
    if ! check_command $cmd; then
      return 1
    fi
  done
  
  # 检查Docker服务状态
  if ! docker info &> /dev/null; then
    log "ERROR" "Docker服务未运行，请先启动Docker服务"
    log "INFO" "可以尝试运行: sudo systemctl start docker"
    return 1
  fi
  
  log "INFO" "环境检查通过"
  return 0
}

# 检查端口是否被占用
check_port() {
  local port=$1
  if command -v netstat &> /dev/null; then
    netstat -tuln | grep -q ":$port "
    return $?
  elif command -v ss &> /dev/null; then
    ss -tuln | grep -q ":$port "
    return $?
  else
    log "WARN" "无法检查端口占用情况，netstat和ss命令均不可用"
    return 0
  fi
}

# 获取可用端口
get_available_port() {
  local port=$1
  local max_port=9000
  
  while [ $port -lt $max_port ]; do
    if ! check_port $port; then
      echo $port
      return 0
    fi
    port=$((port + 1))
  done
  
  log "ERROR" "无法找到可用端口"
  return 1
}

# 配置向导
configure() {
  log "INFO" "开始配置..."
  
  # 部署目录
  read -p "请输入部署目录 [默认: $DEFAULT_DEPLOY_DIR]: " DEPLOY_DIR
  DEPLOY_DIR=${DEPLOY_DIR:-$DEFAULT_DEPLOY_DIR}
  
  # 端口配置
  read -p "请输入Web服务端口 [默认: $DEFAULT_PORT]: " PORT
  PORT=${PORT:-$DEFAULT_PORT}
  
  # 检查端口是否被占用
  if check_port $PORT; then
    log "WARN" "端口 $PORT 已被占用"
    read -p "是否自动分配可用端口? (y/n) [默认: y]: " AUTO_PORT
    AUTO_PORT=${AUTO_PORT:-y}
    
    if [[ $AUTO_PORT =~ ^[Yy]$ ]]; then
      PORT=$(get_available_port $PORT)
      if [ $? -ne 0 ]; then
        log "ERROR" "无法找到可用端口，请手动指定一个未被占用的端口"
        return 1
      fi
      log "INFO" "已自动分配可用端口: $PORT"
    else
      log "ERROR" "请修改端口配置后重试"
      return 1
    fi
  fi
  
  # API密钥配置
  log "INFO" "配置API密钥..."
  read -p "请输入Gemini API密钥 [留空则稍后手动配置]: " GEMINI_API_KEY
  GEMINI_API_KEY=${GEMINI_API_KEY:-$DEFAULT_GEMINI_API_KEY}
  
  read -p "请输入OpenAI API密钥 (可选) [留空则稍后手动配置]: " OPENAI_API_KEY
  OPENAI_API_KEY=${OPENAI_API_KEY:-$DEFAULT_OPENAI_API_KEY}
  
  read -p "请输入OpenAI API基础URL [默认: $DEFAULT_OPENAI_BASE_URL]: " OPENAI_BASE_URL
  OPENAI_BASE_URL=${OPENAI_BASE_URL:-$DEFAULT_OPENAI_BASE_URL}
  
  log "INFO" "配置完成"
  return 0
}

# 创建环境变量文件
create_env_file() {
  local env_file="$DEPLOY_DIR/.env"
  
  log "INFO" "创建环境变量文件: $env_file"
  
  cat > $env_file << EOF
# Gemini API配置
GEMINI_API_KEY=$GEMINI_API_KEY

# OpenAI API配置（可选）
OPENAI_API_KEY=$OPENAI_API_KEY
OPENAI_BASE_URL=$OPENAI_BASE_URL
EOF
  
  log "INFO" "环境变量文件创建成功"
}

# 修改docker-compose.yml中的端口
update_docker_compose() {
  local compose_file="$DEPLOY_DIR/docker-compose.yml"
  
  log "INFO" "更新docker-compose.yml中的端口配置"
  
  if [ -f "$compose_file" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      # macOS需要不同的sed语法
      sed -i '' "s/\"8080:80\"/\"$PORT:80\"/" $compose_file
    else
      # Linux标准语法
      sed -i "s/\"8080:80\"/\"$PORT:80\"/" $compose_file
    fi
    log "INFO" "端口配置已更新为 $PORT:80"
  else
    log "ERROR" "找不到docker-compose.yml文件"
    return 1
  fi
  
  return 0
}

# 部署应用
deploy() {
  log "INFO" "开始部署应用..."
  
  # 创建部署目录
  log "INFO" "创建部署目录: $DEPLOY_DIR"
  mkdir -p $DEPLOY_DIR
  
  # 复制项目文件
  log "INFO" "复制项目文件到部署目录..."
  cp -r ./* $DEPLOY_DIR/
  
  # 进入部署目录
  cd $DEPLOY_DIR
  
  # 创建环境变量文件
  create_env_file
  
  # 更新docker-compose.yml中的端口
  update_docker_compose
  
  # 构建和启动容器
  log "INFO" "构建和启动Docker容器..."
  
  # 尝试使用标准docker-compose命令
  docker-compose down >> $LOG_FILE 2>&1
  docker-compose up -d --build >> $LOG_FILE 2>&1
  
  # 检查是否成功
  if [ $? -ne 0 ]; then
    log "WARN" "标准docker-compose命令失败，尝试使用简化配置..."
    
    # 尝试使用简化版docker-compose.yml
    if [ -f "docker-compose.simple.yml" ]; then
      log "INFO" "使用简化版docker-compose.yml..."
      docker-compose -f docker-compose.simple.yml down >> $LOG_FILE 2>&1
      docker-compose -f docker-compose.simple.yml up -d --build >> $LOG_FILE 2>&1
      
      if [ $? -ne 0 ]; then
        log "WARN" "简化版docker-compose也失败，尝试直接使用Docker命令..."
        
        # 如果docker-compose仍然失败，尝试使用docker-run.sh脚本
        if [ -f "docker-run.sh" ]; then
          log "INFO" "使用docker-run.sh脚本..."
          chmod +x docker-run.sh
          ./docker-run.sh >> $LOG_FILE 2>&1
          
          if [ $? -ne 0 ]; then
            log "ERROR" "所有尝试均失败，请查看日志文件: $LOG_FILE"
            return 1
          fi
        else
          log "ERROR" "找不到docker-run.sh脚本，请手动部署"
          return 1
        fi
      fi
    else
      log "ERROR" "找不到简化版docker-compose.yml文件，请手动部署"
      return 1
    fi
  fi
  
  log "INFO" "应用部署完成"
  return 0
}

# 验证部署
verify_deployment() {
  log "INFO" "验证部署..."
  
  # 检查容器状态
  local container_name=$(docker-compose ps -q 2>/dev/null)
  if [ -z "$container_name" ]; then
    log "ERROR" "容器未启动"
    return 1
  fi
  
  local container_status=$(docker inspect --format='{{.State.Status}}' $container_name)
  if [ "$container_status" != "running" ]; then
    log "ERROR" "容器状态异常: $container_status"
    return 1
  fi
  
  log "INFO" "容器运行正常"
  
  # 检查应用是否可访问
  local max_retries=5
  local retry_count=0
  local wait_time=5
  
  log "INFO" "等待应用启动..."
  while [ $retry_count -lt $max_retries ]; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT | grep -q "200\|301\|302"; then
      log "INFO" "应用可以访问"
      return 0
    fi
    
    retry_count=$((retry_count + 1))
    log "INFO" "等待应用启动 ($retry_count/$max_retries)..."
    sleep $wait_time
  done
  
  log "WARN" "无法验证应用是否可访问，但容器已启动"
  return 0
}

# 显示部署结果
show_result() {
  local status=$1
  
  echo ""
  echo "========================================"
  
  if [ $status -eq 0 ]; then
    echo -e "${GREEN}部署成功!${NC}"
    echo ""
    echo "应用访问地址: http://localhost:$PORT"
    echo "部署目录: $DEPLOY_DIR"
    
    # 如果API密钥未配置，提示用户
    if [ -z "$GEMINI_API_KEY" ]; then
      echo ""
      echo -e "${YELLOW}注意:${NC} Gemini API密钥未配置"
      echo "请编辑 $DEPLOY_DIR/.env 文件添加您的API密钥"
    fi
    
    echo ""
    echo "常用命令:"
    echo "  cd $DEPLOY_DIR && docker-compose ps    # 查看容器状态"
    echo "  cd $DEPLOY_DIR && docker-compose logs  # 查看容器日志"
    echo "  cd $DEPLOY_DIR && docker-compose down  # 停止应用"
    echo "  cd $DEPLOY_DIR && docker-compose up -d # 启动应用"
  else
    echo -e "${RED}部署失败!${NC}"
    echo ""
    echo "请查看日志文件: $LOG_FILE"
    echo "或者尝试手动执行以下步骤:"
    echo "  1. 确保Docker和Docker Compose已安装"
    echo "  2. 检查端口 $PORT 是否被占用"
    echo "  3. 进入部署目录: cd $DEPLOY_DIR"
    echo "  4. 手动启动容器: docker-compose up -d"
  fi
  
  echo "========================================"
}

# 主函数
main() {
  echo "========================================"
  echo "    Dual-AI-Chat 一键部署脚本"
  echo "========================================"
  echo ""
  
  # 检查是否以root用户运行
  if [ "$EUID" -ne 0 ]; then
    log "WARN" "当前非root用户，可能需要sudo权限执行某些操作"
    read -p "是否继续? (y/n) [默认: y]: " CONTINUE
    CONTINUE=${CONTINUE:-y}
    
    if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
      log "INFO" "部署已取消"
      exit 0
    fi
  fi
  
  # 检查环境
  check_environment
  if [ $? -ne 0 ]; then
    show_result 1
    exit 1
  fi
  
  # 配置向导
  configure
  if [ $? -ne 0 ]; then
    show_result 1
    exit 1
  fi
  
  # 部署应用
  deploy
  if [ $? -ne 0 ]; then
    show_result 1
    exit 1
  fi
  
  # 验证部署
  verify_deployment
  local status=$?
  
  # 显示结果
  show_result $status
  
  exit $status
}

# 执行主函数
main
