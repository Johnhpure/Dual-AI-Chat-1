# Dual-AI-Chat 一键部署指南

本文档提供了如何使用一键部署脚本在Dell物理服务器上部署Dual-AI-Chat项目的详细说明。

## 前提条件

在开始部署前，请确保您的服务器满足以下条件：

1. 已安装Docker（推荐版本20.10或更高）
2. 已安装Docker Compose（推荐版本2.0或更高）
3. 拥有足够的权限执行部署操作（root或sudo权限）
4. 已获取Gemini API密钥（必需）和OpenAI API密钥（可选）

## 部署步骤

### 1. 准备部署脚本

将项目文件和部署脚本上传到您的Dell物理服务器。您可以使用以下方法之一：

- 克隆GitHub仓库：
  ```bash
  git clone https://github.com/Johnhpure/dual-ai-chat.git
  cd dual-ai-chat
  ```

- 或者，下载项目压缩包并解压：
  ```bash
  wget https://github.com/Johnhpure/dual-ai-chat/archive/refs/heads/main.zip
  unzip main.zip
  cd dual-ai-chat-main
  ```

### 2. 执行一键部署脚本

使用以下命令运行部署脚本：

```bash
sudo ./local-deploy.sh
```

> 注意：建议使用sudo或root用户运行脚本，以确保拥有足够的权限。

### 3. 按照向导进行配置

脚本运行后，将引导您完成以下配置：

1. 部署目录（默认为`/opt/dual-ai-chat`）
2. Web服务端口（默认为`8080`）
   - 如果端口被占用，脚本会提示您是否自动分配可用端口
3. Gemini API密钥
4. OpenAI API密钥（可选）
5. OpenAI API基础URL（默认为`https://api.openai.com`）

### 4. 验证部署

部署完成后，脚本会自动验证部署是否成功，并显示应用访问地址和常用命令。

您可以通过以下地址访问应用：
```
http://服务器IP:配置的端口
```

例如：`http://192.168.1.100:8080`

## 常见问题

### 端口被占用

如果您指定的端口已被占用，脚本会提示您是否自动分配可用端口。您也可以手动指定一个未被占用的端口。

要查看当前占用的端口，可以运行：
```bash
netstat -tuln
```

### API密钥未配置

如果您在部署时未提供API密钥，可以稍后手动编辑`.env`文件：
```bash
sudo vi /opt/dual-ai-chat/.env
```

### 容器无法启动

如果容器无法启动，请检查日志文件：
```bash
cd /opt/dual-ai-chat
docker-compose logs
```

### 修改配置

部署后如需修改配置，可以编辑以下文件：

- 环境变量：`/opt/dual-ai-chat/.env`
- 端口配置：`/opt/dual-ai-chat/docker-compose.yml`

修改后，重启容器使配置生效：
```bash
cd /opt/dual-ai-chat
docker-compose down
docker-compose up -d
```

## 管理应用

### 查看容器状态
```bash
cd /opt/dual-ai-chat
docker-compose ps
```

### 查看容器日志
```bash
cd /opt/dual-ai-chat
docker-compose logs
```

### 停止应用
```bash
cd /opt/dual-ai-chat
docker-compose down
```

### 启动应用
```bash
cd /opt/dual-ai-chat
docker-compose up -d
```

### 更新应用
```bash
cd /opt/dual-ai-chat
git pull  # 如果是通过git克隆的仓库
docker-compose down
docker-compose up -d --build
```

## 故障排除

如果您在部署过程中遇到问题，请参考以下步骤：

1. 检查日志文件：`deploy-*.log`
2. 确认Docker和Docker Compose已正确安装
3. 验证服务器网络连接正常
4. 检查API密钥是否有效
5. 确保服务器防火墙未阻止指定端口

如需更多帮助，请查看项目GitHub仓库的Issues部分或提交新的Issue。
