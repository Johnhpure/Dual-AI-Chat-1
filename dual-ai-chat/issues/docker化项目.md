# Docker化Dual-AI-Chat项目

## 上下文
Dual-AI-Chat是一个React+Vite前端应用，支持Gemini和OpenAI API，需要配置API密钥。项目需要打包成Docker镜像以便于部署。

## 计划
1. 创建Dockerfile（多阶段构建）
   - 第一阶段：使用Node.js镜像构建应用
   - 第二阶段：使用Nginx镜像部署静态文件

2. 创建.dockerignore文件
   - 排除node_modules等不需要的文件

3. 创建环境变量配置方案
   - 创建.env.example文件作为模板
   - 在Docker运行时通过环境变量注入API密钥

4. 编写构建和运行Docker镜像的指令

5. 更新README.md，添加Docker使用说明
