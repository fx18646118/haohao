# Tunee Backend API 部署指南

## 阿里云函数计算部署

### 1. 准备工作

#### 1.1 安装依赖工具
```bash
# 安装 Funcraft (Fun)
npm install @alicloud/fun -g

# 验证安装
fun --version
```

#### 1.2 配置阿里云凭证
```bash
fun config
```

按提示输入：
- Account ID: 你的阿里云账号 ID
- Access Key ID: 你的 Access Key ID
- Access Key Secret: 你的 Access Key Secret
- Default Region: cn-hangzhou (或其他区域)

### 2. 配置环境变量

创建 `.env` 文件：

```bash
cat > .env << 'EOF'
# MongoDB
MongoDBUri=mongodb+srv://username:password@cluster.mongodb.net/tunee?retryWrites=true&w=majority

# JWT
JwtSecret=your-super-secret-jwt-key-change-this-in-production

# 微信
WechatAppId=wx1234567890abcdef
WechatAppSecret=your-wechat-app-secret
WechatPayMchId=1234567890
WechatPayKey=your-wechat-pay-key

# 支付宝
AlipayAppId=2024xxxxxxxxxxxx

# 域名
Domain=api.tunee.app
EOF
```

### 3. 部署步骤

#### 3.1 安装项目依赖
```bash
npm install
```

#### 3.2 本地测试
```bash
# 本地启动服务
fun local start

# 测试接口
curl http://localhost:8000/2016-08-15/proxy/tunee-api/TuneeApiFunction/health
```

#### 3.3 部署到阿里云
```bash
# 部署所有资源
fun deploy

# 只部署函数代码（更新代码时使用）
fun deploy --only-code
```

### 4. 配置自定义域名

#### 4.1 添加域名解析
在 DNS 服务商处添加 CNAME 记录：
```
api.tunee.app -> your-endpoint.cn-hangzhou.fc.aliyuncs.com
```

#### 4.2 在函数计算控制台绑定域名
1. 登录 [函数计算控制台](https://fc.console.aliyun.com/)
2. 进入你的服务 -> 域名管理
3. 添加自定义域名
4. 配置路由规则

### 5. 配置 HTTPS（可选但推荐）

#### 5.1 申请 SSL 证书
可以在阿里云 SSL 证书服务申请免费证书。

#### 5.2 配置 HTTPS
在函数计算控制台的域名管理中，开启 HTTPS 并上传证书。

### 6. 配置 MongoDB

#### 6.1 使用阿里云 MongoDB
1. 购买 [阿里云 MongoDB 实例](https://www.aliyun.com/product/mongodb)
2. 创建数据库和用户
3. 添加白名单（函数计算出口 IP）
4. 复制连接字符串到环境变量

#### 6.2 使用 MongoDB Atlas（免费）
1. 注册 [MongoDB Atlas](https://www.mongodb.com/atlas)
2. 创建免费集群
3. 添加数据库用户
4. 在 Network Access 中添加 `0.0.0.0/0`（允许所有 IP）
5. 复制连接字符串

### 7. 配置支付

#### 7.1 微信支付
1. 注册微信支付商户
2. 配置支付授权目录
3. 设置回调地址：`https://api.tunee.app/api/payment/wechat/notify`
4. 将密钥配置到环境变量

#### 7.2 支付宝
1. 注册支付宝开放平台
2. 创建应用并配置能力
3. 设置回调地址：`https://api.tunee.app/api/payment/alipay/notify`
4. 配置公钥和私钥

### 8. 监控和日志

#### 8.1 查看日志
```bash
# 实时查看日志
fun logs -t

# 查看最近100条日志
fun logs -n 100
```

#### 8.2 云监控
在阿里云控制台查看：
- 调用次数
- 执行时间
- 错误率
- 资源使用情况

### 9. 性能优化

#### 9.1 预留实例
为避免冷启动，可以配置预留实例：
```yaml
# 在 template.yml 中添加
TuneeApiFunction:
  Type: 'Aliyun::Serverless::Function'
  Properties:
    # ... 其他配置
    InstanceType: e1 # 弹性实例
    ReservedCapacity: 1 # 预留1个实例
```

#### 9.2 使用层（Layer）
将 node_modules 打包为层，减少代码包大小：
```bash
# 创建层
fun layer publish --layer-name tunee-deps --code ./node_modules

# 在 template.yml 中引用
Layers:
  - acs:fc:${ALIYUN_REGION}:${ALIYUN_ACCOUNT_ID}:layers/tunee-deps/versions/1
```

### 10. 常见问题

#### Q: 部署失败，提示权限不足
A: 确保已配置正确的 Access Key，并且该账号有函数计算的操作权限。

#### Q: 函数无法访问 MongoDB
A: 
1. 检查 MongoDB 白名单是否包含函数计算出口 IP
2. 检查连接字符串是否正确
3. 检查网络类型（VPC 配置）

#### Q: 支付回调不生效
A:
1. 检查回调 URL 是否正确
2. 检查域名是否已备案（国内服务器需要）
3. 检查 SSL 证书是否有效
4. 查看函数日志排查问题

#### Q: 冷启动慢
A:
1. 配置预留实例
2. 优化代码，减少初始化时间
3. 使用层管理依赖

### 11. 更新部署

```bash
# 更新代码
fun deploy --only-code

# 更新配置
fun deploy

# 完全重新部署
fun deploy --force
```

### 12. 回滚

```bash
# 查看历史版本
fun version list --service-name tunee-api --function-name TuneeApiFunction

# 回滚到指定版本
fun alias publish --service-name tunee-api --alias-name prod --version-id 2
```
