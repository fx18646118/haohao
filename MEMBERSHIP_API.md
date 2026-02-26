# Tunee App 会员系统 API 文档

## 概述

本文档描述了 Tunee App 会员系统与后端 API 的对接接口。

## 基础配置

```dart
// API 基础URL
static const String baseUrl = 'https://api.tunee.ai/v1';

// 请求头
{
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Authorization': 'Bearer {token}'  // 登录后需要
}
```

## 认证相关 API

### 1. 发送手机验证码

**请求**
```http
POST /auth/phone/send-code
Content-Type: application/json

{
  "phone": "13800138000"
}
```

**响应**
```json
{
  "session_id": "sess_abc123",
  "expires_in": 300,
  "sent_at": "2024-01-01T12:00:00Z"
}
```

### 2. 手机号验证码登录

**请求**
```http
POST /auth/phone/login
Content-Type: application/json

{
  "phone": "13800138000",
  "code": "123456",
  "session_id": "sess_abc123"
}
```

**响应**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "user_123",
    "phone": "13800138000",
    "nickname": "音乐创作者",
    "avatar_url": null,
    "level": "free",
    "remaining_generations": 3,
    "total_generations": 0,
    "membership_expiry": null,
    "created_at": "2024-01-01T12:00:00Z",
    "updated_at": "2024-01-01T12:00:00Z"
  },
  "is_new_user": true
}
```

### 3. 微信登录

**请求**
```http
POST /auth/wechat/login
Content-Type: application/json

{
  "code": "wechat_auth_code"
}
```

**响应**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": { ... },
  "is_new_user": false
}
```

### 4. 退出登录

**请求**
```http
POST /auth/logout
Authorization: Bearer {token}
```

### 5. 刷新Token

**请求**
```http
POST /auth/refresh
Authorization: Bearer {token}
```

**响应**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

## 用户信息 API

### 6. 获取当前用户信息

**请求**
```http
GET /user/profile
Authorization: Bearer {token}
```

**响应**
```json
{
  "id": "user_123",
  "phone": "13800138000",
  "wechat_open_id": "wx_xxx",
  "nickname": "音乐创作者",
  "avatar_url": "https://...",
  "level": "premium",
  "remaining_generations": 45,
  "total_generations": 55,
  "membership_expiry": "2024-12-31T23:59:59Z",
  "created_at": "2024-01-01T12:00:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

### 7. 更新用户信息

**请求**
```http
POST /user/profile
Authorization: Bearer {token}
Content-Type: application/json

{
  "nickname": "新昵称",
  "avatar_url": "https://..."
}
```

### 8. 检查生成次数

**请求**
```http
GET /user/quota
Authorization: Bearer {token}
```

**响应**
```json
{
  "remaining_generations": 45,
  "daily_quota": 50,
  "used_today": 5,
  "reset_time": "2024-01-16T00:00:00Z"
}
```

### 9. 消耗生成次数

**请求**
```http
POST /user/quota/consume
Authorization: Bearer {token}
```

**响应**
```json
{
  "success": true,
  "remaining_generations": 44
}
```

## 会员套餐 API

### 10. 获取会员套餐列表

**请求**
```http
GET /membership/plans
```

**响应**
```json
[
  {
    "id": "basic_monthly",
    "name": "基础会员",
    "description": "适合轻度使用者",
    "price": 19.9,
    "original_price": 29.9,
    "duration_days": 30,
    "generation_quota": 50,
    "level": "basic",
    "features": [
      "每日10次生成额度",
      "标准音质下载",
      "基础风格选择",
      "7天作品保存"
    ],
    "is_popular": false,
    "is_new": false
  },
  {
    "id": "premium_monthly",
    "name": "高级会员",
    "description": "最受欢迎",
    "price": 49.9,
    "original_price": 79.9,
    "duration_days": 30,
    "generation_quota": 200,
    "level": "premium",
    "features": [...],
    "is_popular": true,
    "is_new": false
  }
]
```

## 支付相关 API

### 11. 创建支付订单

**请求**
```http
POST /payment/create
Authorization: Bearer {token}
Content-Type: application/json

{
  "plan_id": "premium_monthly",
  "payment_method": "wechat"  // 或 "alipay"
}
```

**响应**
```json
{
  "id": "order_abc123",
  "user_id": "user_123",
  "plan_id": "premium_monthly",
  "amount": 49.9,
  "payment_method": "wechat",
  "status": "pending",
  "created_at": "2024-01-15T10:30:00Z",
  "plan": { ... }
}
```

### 12. 获取微信支付参数

**请求**
```http
POST /payment/wechat/prepay
Authorization: Bearer {token}
Content-Type: application/json

{
  "order_id": "order_abc123"
}
```

**响应**
```json
{
  "appid": "wx_appid",
  "partnerid": "merchant_id",
  "prepayid": "prepay_id",
  "package": "Sign=WXPay",
  "noncestr": "random_string",
  "timestamp": "1705315800",
  "sign": "signature"
}
```

### 13. 获取支付宝支付参数

**请求**
```http
POST /payment/alipay/prepay
Authorization: Bearer {token}
Content-Type: application/json

{
  "order_id": "order_abc123"
}
```

**响应**
```json
{
  "order_string": "alipay_sdk=..."
}
```

### 14. 查询订单状态

**请求**
```http
GET /payment/order/{order_id}
Authorization: Bearer {token}
```

**响应**
```json
{
  "id": "order_abc123",
  "user_id": "user_123",
  "plan_id": "premium_monthly",
  "amount": 49.9,
  "payment_method": "wechat",
  "status": "paid",  // pending, paid, failed, cancelled
  "transaction_id": "wx_transaction_id",
  "created_at": "2024-01-15T10:30:00Z",
  "paid_at": "2024-01-15T10:31:00Z",
  "plan": { ... }
}
```

### 15. 取消订单

**请求**
```http
POST /payment/order/{order_id}/cancel
Authorization: Bearer {token}
```

## 错误码

| 错误码 | 说明 |
|--------|------|
| UNAUTHORIZED | Token无效或过期 |
| FORBIDDEN | 权限不足 |
| RATE_LIMIT | 请求过于频繁 |
| SERVER_ERROR | 服务器错误 |
| INVALID_PHONE | 手机号格式错误 |
| INVALID_CODE | 验证码错误 |
| QUOTA_EXCEEDED | 次数已用完 |
| ORDER_NOT_FOUND | 订单不存在 |
| PAYMENT_FAILED | 支付失败 |

## 会员等级说明

| 等级 | 名称 | 每日额度 | 颜色 |
|------|------|----------|------|
| free | 免费用户 | 3次 | 灰色 |
| basic | 基础会员 | 10次 | 铜色 #CD7F32 |
| premium | 高级会员 | 50次 | 银色 #C0C0C0 |
| vip | VIP会员 | 无限 | 金色 #FFD700 |

## 前端集成说明

### 1. 初始化

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await LocalStorageService.initialize();
  
  runApp(const TuneeApp());
}
```

### 2. 在 main.dart 中添加 Provider

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => MembershipProvider()),
    // ... 其他 providers
  ],
  child: MyApp(),
)
```

### 3. 检查登录和次数

```dart
// 在生成音乐前检查
final canProceed = await checkAndShowQuotaDialog(
  context,
  isLoggedIn: membershipProvider.isLoggedIn,
  remainingQuota: membershipProvider.remainingGenerations,
);

if (canProceed) {
  // 消耗次数并生成音乐
  await membershipProvider.consumeGeneration();
  // ... 生成音乐
}
```

### 4. 支付集成

需要集成微信和支付宝的 Flutter SDK：

```yaml
dependencies:
  fluwx: ^4.5.0  # 微信支付
  tobias: ^3.3.0  # 支付宝
```

然后在 `payment_screen.dart` 中调用对应的支付方法。
