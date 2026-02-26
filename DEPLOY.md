# 阿里云函数计算部署配置

## 前置要求

1. 安装 Funcraft 工具
```bash
npm install @alicloud/fun -g
```

2. 配置阿里云凭证
```bash
fun config
```

3. 准备 MongoDB 数据库（阿里云 MongoDB 或自建）

## 部署步骤

### 1. 安装依赖
```bash
npm install
```

### 2. 配置环境变量
编辑 `template.yml` 中的环境变量，或使用 Fun 的变量功能：

```bash
# 创建 .env 文件
cat > .env << EOF
MongoDBUri=mongodb://username:password@host:port/tunee
JwtSecret=your-secret-key
WechatAppId=wx...
WechatAppSecret=...
WechatPayMchId=...
WechatPayKey=...
AlipayAppId=...
Domain=api.tunee.app
EOF
```

### 3. 本地测试
```bash
# 本地启动
fun local start

# 本地调用
fun local invoke TuneeApiFunction
```

### 4. 部署到阿里云
```bash
# 部署所有资源
fun deploy

# 或只部署函数代码
fun deploy --only-code
```

## 自定义域名配置

1. 在阿里云控制台添加自定义域名解析
2. 在函数计算控制台绑定自定义域名
3. 配置 HTTPS（推荐）

## 监控和日志

- 函数计算控制台查看调用日志
- 云监控查看性能指标
- SLS 日志服务查询详细日志

## 常见问题

### 冷启动优化
- 使用预留实例避免冷启动
- 优化代码包大小
- 使用层（Layer）管理依赖

### 数据库连接
- 使用连接池
- 配置 VPC 访问 MongoDB
- 考虑使用 Serverless MongoDB（如阿里云 MongoDB Serverless 版）
