# 项目结构说明

```
tunee-backend-api/
├── config/                 # 配置文件
│   ├── database.js        # MongoDB 连接配置
│   └── constants.js       # 常量定义（会员等级、支付配置等）
│
├── controllers/           # 控制器（业务逻辑）
│   ├── authController.js      # 认证相关（登录、注册、令牌刷新）
│   ├── membershipController.js # 会员相关（订单、会员信息）
│   ├── paymentController.js    # 支付回调处理
│   └── generationController.js # 音乐生成相关
│
├── middleware/            # 中间件
│   ├── auth.js           # JWT 认证
│   ├── validate.js       # 请求参数验证
│   └── error.js          # 错误处理
│
├── models/               # 数据模型（Mongoose Schema）
│   ├── User.js           # 用户模型
│   ├── Order.js          # 订单模型
│   ├── Generation.js     # 生成记录模型
│   ├── SmsCode.js        # 短信验证码模型
│   └── RefreshToken.js   # 刷新令牌模型
│
├── routes/               # 路由定义
│   ├── auth.js           # 公开认证路由
│   ├── user.js           # 用户相关路由（需认证）
│   ├── membership.js     # 会员相关路由
│   ├── payment.js        # 支付回调路由（公开）
│   ├── paymentAuth.js    # 支付查询路由（需认证）
│   └── generation.js     # 生成相关路由
│
├── utils/                # 工具函数
│   ├── jwt.js            # JWT 生成与验证
│   ├── crypto.js         # 加密、签名相关
│   ├── wechat.js         # 微信 API 封装
│   ├── alipay.js         # 支付宝 API 封装
│   ├── sms.js            # 短信服务
│   └── response.js       # 统一响应格式
│
├── server.js             # 应用入口
├── package.json          # 项目依赖
├── .env.example          # 环境变量示例
├── template.yml          # 阿里云函数计算配置
├── API_DOCUMENTATION.md  # API 文档
├── DEPLOY_ALIYUN.md      # 阿里云部署指南
└── README.md             # 项目说明
```

## 核心流程说明

### 1. 用户认证流程
```
手机号登录: 发送验证码 → 验证验证码 → 生成 JWT → 返回令牌
微信登录: 微信授权 → 获取用户信息 → 查找/创建用户 → 生成 JWT → 返回令牌
```

### 2. 会员购买流程
```
创建订单 → 调用支付接口 → 返回支付参数 → 客户端调起支付 → 支付回调 → 更新会员状态
```

### 3. 音乐生成流程
```
检查配额 → 扣减次数 → 创建生成任务 → 异步处理 → 返回结果
```

## 关键设计

### 每日次数限制
- 存储在用户文档的 `dailyStats` 字段
- 每天首次请求时自动重置计数
- 会员过期后自动降级为免费额度

### 支付安全
- 回调签名验证
- 金额二次校验
- 幂等性处理（防止重复处理同一订单）

### JWT 认证
- Access Token: 7天有效期
- Refresh Token: 30天有效期，存储在数据库中
- 支持令牌刷新和撤销
