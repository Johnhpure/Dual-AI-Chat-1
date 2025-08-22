# Dual AI Chat

这是一个支持Gemini和OpenAI双AI对话的聊天应用。

## 本地运行

**前提条件:** 安装Node.js

1. 安装依赖:
   ```bash
   npm install
   ```
2. 在`.env.local`文件中设置`GEMINI_API_KEY`为您的Gemini API密钥
3. 运行应用:
   ```bash
   npm run dev
   ```

## 使用Docker运行

### 方法1：使用Docker Compose（推荐）

1. 复制环境变量示例文件并填写API密钥:
   ```bash
   cp docker-env.example .env
   # 编辑.env文件，填入您的API密钥
   ```

2. 构建并启动容器:
   ```bash
   docker-compose up -d
   ```

3. 访问应用:
   ```
   http://localhost:8080
   ```

### 方法2：直接使用Docker命令

1. 构建Docker镜像:
   ```bash
   docker build -t dual-ai-chat .
   ```

2. 运行Docker容器:
   ```bash
   docker run -d -p 8080:80 \
     -e GEMINI_API_KEY=your_gemini_api_key \
     -e OPENAI_API_KEY=your_openai_api_key \
     -e OPENAI_BASE_URL=https://api.openai.com \
     --name dual-ai-chat \
     dual-ai-chat
   ```

3. 访问应用:
   ```
   http://localhost:8080
   ```

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

3. 创建环境变量文件:
   ```bash
   cp docker-env.example .env
   # 编辑.env文件，填入您的API密钥
   ```

4. 使用Docker Compose部署:
   ```bash
   docker-compose up -d
   ```

5. 访问应用:
   ```
   http://47.79.145.239:8080
   ```

## 环境变量

| 变量名 | 描述 | 是否必需 |
|--------|------|----------|
| GEMINI_API_KEY | Google Gemini API密钥 | 是 |
| OPENAI_API_KEY | OpenAI API密钥 | 否 |
| OPENAI_BASE_URL | OpenAI API基础URL | 否 |