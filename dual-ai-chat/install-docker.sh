#!/bin/bash

# Docker和Docker Compose安装脚本
# 用于在Dell物理服务器上安装Docker环境

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
  local level=$1
  local message=$2
  
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
}

# 检查是否为root用户
check_root() {
  if [ "$EUID" -ne 0 ]; then
    log "ERROR" "请以root用户运行此脚本"
    exit 1
  fi
}

# 检测操作系统
detect_os() {
  log "INFO" "检测操作系统..."
  
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
    log "INFO" "检测到操作系统: $OS $VER"
  else
    log "ERROR" "无法检测操作系统类型"
    exit 1
  fi
}

# 安装Docker
install_docker() {
  log "INFO" "开始安装Docker..."
  
  # 安装依赖
  log "INFO" "安装依赖..."
  if [[ $OS == *"Ubuntu"* ]] || [[ $OS == *"Debian"* ]]; then
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
  elif [[ $OS == *"CentOS"* ]] || [[ $OS == *"Red Hat"* ]] || [[ $OS == *"Fedora"* ]]; then
    yum install -y yum-utils device-mapper-persistent-data lvm2
  else
    log "ERROR" "不支持的操作系统: $OS"
    exit 1
  fi
  
  # 添加Docker仓库
  log "INFO" "添加Docker仓库..."
  if [[ $OS == *"Ubuntu"* ]] || [[ $OS == *"Debian"* ]]; then
    curl -fsSL https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]') $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
  elif [[ $OS == *"CentOS"* ]] || [[ $OS == *"Red Hat"* ]] || [[ $OS == *"Fedora"* ]]; then
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  fi
  
  # 安装Docker
  log "INFO" "安装Docker..."
  if [[ $OS == *"Ubuntu"* ]] || [[ $OS == *"Debian"* ]]; then
    apt-get install -y docker-ce docker-ce-cli containerd.io
  elif [[ $OS == *"CentOS"* ]] || [[ $OS == *"Red Hat"* ]] || [[ $OS == *"Fedora"* ]]; then
    yum install -y docker-ce docker-ce-cli containerd.io
  fi
  
  # 启动Docker服务
  log "INFO" "启动Docker服务..."
  systemctl start docker
  systemctl enable docker
  
  # 验证安装
  log "INFO" "验证Docker安装..."
  if docker --version; then
    log "INFO" "Docker安装成功"
  else
    log "ERROR" "Docker安装失败"
    exit 1
  fi
}

# 安装Docker Compose
install_docker_compose() {
  log "INFO" "开始安装Docker Compose..."
  
  # 获取最新版本
  COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
  
  if [ -z "$COMPOSE_VERSION" ]; then
    log "WARN" "无法获取最新版本，使用默认版本v2.12.2"
    COMPOSE_VERSION="v2.12.2"
  fi
  
  log "INFO" "安装Docker Compose $COMPOSE_VERSION..."
  
  # 下载Docker Compose
  curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  
  # 添加执行权限
  chmod +x /usr/local/bin/docker-compose
  
  # 创建软链接
  ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
  
  # 验证安装
  log "INFO" "验证Docker Compose安装..."
  if docker-compose --version; then
    log "INFO" "Docker Compose安装成功"
  else
    log "ERROR" "Docker Compose安装失败"
    exit 1
  fi
}

# 配置Docker
configure_docker() {
  log "INFO" "配置Docker..."
  
  # 创建docker配置目录
  mkdir -p /etc/docker
  
  # 配置Docker守护进程
  cat > /etc/docker/daemon.json << EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  }
}
EOF
  
  # 重启Docker服务
  log "INFO" "重启Docker服务以应用配置..."
  systemctl daemon-reload
  systemctl restart docker
  
  log "INFO" "Docker配置完成"
}

# 主函数
main() {
  echo "========================================"
  echo "    Docker和Docker Compose安装脚本"
  echo "========================================"
  echo ""
  
  # 检查root权限
  check_root
  
  # 检测操作系统
  detect_os
  
  # 安装Docker
  install_docker
  
  # 安装Docker Compose
  install_docker_compose
  
  # 配置Docker
  configure_docker
  
  echo ""
  echo "========================================"
  echo -e "${GREEN}Docker环境安装完成!${NC}"
  echo "Docker版本:"
  docker --version
  echo "Docker Compose版本:"
  docker-compose --version
  echo "========================================"
  
  echo ""
  echo "现在您可以运行local-deploy.sh脚本部署Dual-AI-Chat应用:"
  echo "  ./local-deploy.sh"
  echo ""
}

# 执行主函数
main
