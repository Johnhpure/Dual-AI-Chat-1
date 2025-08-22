# Dual AI Chat

这是一个支持Gemini和OpenAI双AI对话的聊天应用。

## 本地运行

**前提条件:** 安装Node.js

1. 安装依赖:
   ```bash
   npm install
   ```
2. 运行应用:
   ```bash
   npm run dev
   ```
3. 在应用设置中配置API密钥:
   - 点击右上角的设置图标
   - 在"API配置"部分输入您的Gemini API密钥
   - 或者配置OpenAI兼容API

## 使用Docker运行

### 方法1：使用Docker Compose（推荐）

1. 构建并启动容器:
   ```bash
   docker-compose up -d
   ```

2. 访问应用:
   ```
   http://localhost:8080
   ```

3. 在应用设置中配置API密钥:
   - 点击右上角的设置图标
   - 在"API配置"部分输入您的Gemini API密钥
   - 或者配置OpenAI兼容API

### 方法2：直接使用Docker命令

1. 构建Docker镜像:
   ```bash
   docker build -t dual-ai-chat .
   ```

2. 运行Docker容器:
   ```bash
   docker run -d -p 8080:80 \
     --name dual-ai-chat \
     dual-ai-chat
   ```

3. 访问应用:
   ```
   http://localhost:8080
   ```

4. 在应用设置中配置API密钥:
   - 点击右上角的设置图标
   - 在"API配置"部分输入您的Gemini API密钥
   - 或者配置OpenAI兼容API

## 部署到服务器

### 部署到阿里云服务器

1. 登录到服务器:
   ```bash
   ssh root@47.79.145.239
   ```

2. 克隆代码仓库:
   ```bash
   git clone <仓库URL> /opt/dual-ai-chat
   cd /opt/dual-ai-chat
   ```

3. 启动应用:
   ```bash
   docker-compose up -d
   ```

4. 访问应用:
   ```
   http://47.79.145.239:8080
   ```

5. 在应用设置中配置API密钥:
   - 点击右上角的设置图标
   - 在"API配置"部分输入您的Gemini API密钥
   - 或者配置OpenAI兼容API

## API配置

应用需要在设置中配置以下API信息：

| 配置项 | 描述 | 是否必需 |
|--------|------|----------|
| Gemini API密钥 | Google Gemini API密钥 | 是（除非使用OpenAI API） |
| Gemini API端点 | 自定义API端点（可选） | 否 |
| OpenAI API密钥 | OpenAI或兼容API密钥 | 是（如果启用OpenAI API） |
| OpenAI API基础URL | API服务器地址 | 是（如果启用OpenAI API） |
| OpenAI模型ID | 使用的模型标识符 | 是（如果启用OpenAI API） |