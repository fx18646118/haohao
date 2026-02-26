# Tunee Backend API

Tunee App 会员系统后端 API - Node.js + Express + MongoDB

## 功能特性

- 用户登录/注册（手机号验证码 + 微信 OAuth）
- 会员等级管理（免费/月卡/年卡）
- 每日生成次数限制（免费3首/付费50首）
- 支付回调（微信支付 + 支付宝）
- 生成音乐时检查次数并扣减

## 技术栈

- Node.js + Express
- MongoDB（用户、订单、生成记录）
- JWT 认证
- 阿里云函数计算部署

## 快速开始

### 本地开发

```bash
# 安装依赖
npm install

# 配置环境变量
cp .env.example .env
# 编辑 .env 文件

# 启动开发服务器
npm run dev
```

### 部署到阿里云

```bash
# 配置阿里云凭证
fun config

# 部署
npm run deploy
```

## API 文档

详见 [API_DOCUMENTATION.md](./API_DOCUMENTATION.md)

## 项目结构

```
tunee-backend-api/
├── config/           # 配置文件
├── controllers/      # 控制器
├── middleware/       # 中间件
├── models/           # 数据模型
├── routes/           # 路由
├── utils/            # 工具函数
├── server.js         # 入口文件
├── template.yml      # 阿里云函数计算配置
└── package.json
```
