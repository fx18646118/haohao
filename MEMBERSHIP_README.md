# Tunee App 会员系统 Flutter 前端实现

## 已完成的功能

### 1. 登录页面 (`lib/screens/auth/login_screen.dart`)
- ✅ 手机号验证码登录
  - 手机号输入验证
  - 验证码发送倒计时
  - 60秒重发限制
- ✅ 微信登录按钮（需集成微信SDK）
- ✅ 紫色主题UI设计
- ✅ 用户协议和隐私政策链接

### 2. 会员中心页面 (`lib/screens/membership/membership_screen.dart`)
- ✅ 显示当前会员等级（免费/基础/高级/VIP）
- ✅ 显示剩余生成次数和进度条
- ✅ 会员特权展示
- ✅ 会员套餐列表
  - 基础会员：¥19.9/月
  - 高级会员：¥49.9/月（推荐）
  - VIP会员：¥399/年
- ✅ 未登录提示和登录跳转

### 3. 支付页面 (`lib/screens/membership/payment_screen.dart`)
- ✅ 微信支付支持
- ✅ 支付宝支持
- ✅ 订单确认展示
- ✅ 支付状态轮询
- ✅ 支付成功提示

### 4. 状态管理 (`lib/providers/membership_provider.dart`)
- ✅ 使用 Provider 管理会员状态
- ✅ 用户信息管理
- ✅ 生成次数管理
- ✅ 订单管理
- ✅ 自动Token刷新

### 5. 数据模型 (`lib/models/membership_models.dart`)
- ✅ UserProfile - 用户信息
- ✅ MembershipPlan - 会员套餐
- ✅ PaymentOrder - 支付订单
- ✅ VerificationCode - 验证码
- ✅ LoginResponse - 登录响应
- ✅ MembershipLevel 枚举

### 6. API服务 (`lib/services/membership_service.dart`)
- ✅ 手机验证码发送/登录
- ✅ 微信登录
- ✅ 用户信息获取/更新
- ✅ 生成次数检查/消耗
- ✅ 会员套餐获取
- ✅ 支付订单创建/查询
- ✅ 支付参数获取（微信/支付宝）

### 7. 提示对话框 (`lib/widgets/quota_dialogs.dart`)
- ✅ 未登录提示
- ✅ 次数用完提示
- ✅ 生成确认对话框
- ✅ 统一检查方法

### 8. 个人中心更新 (`lib/screens/home/home_screen.dart`)
- ✅ 显示会员等级徽章
- ✅ 显示剩余次数
- ✅ 会员中心入口
- ✅ 退出登录功能

### 9. 创作页面集成 (`lib/screens/home/home_screen.dart`)
- ✅ 发送消息前检查登录状态
- ✅ 发送消息前检查剩余次数
- ✅ 自动消耗生成次数
- ✅ 次数不足自动提示

## 文件结构

```
lib/
├── main.dart                          # 应用入口，集成Provider
├── models/
│   ├── music_models.dart              # 原有音乐模型
│   └── membership_models.dart         # 会员系统模型 ⭐
├── providers/
│   ├── theme_provider.dart            # 主题状态
│   └── membership_provider.dart       # 会员状态管理 ⭐
├── services/
│   ├── api_service.dart               # 原有API服务
│   ├── local_storage_service.dart     # 本地存储（添加Token存储）
│   └── membership_service.dart        # 会员API服务 ⭐
├── screens/
│   ├── auth/
│   │   └── login_screen.dart          # 登录页面 ⭐
│   ├── membership/
│   │   ├── membership_screen.dart     # 会员中心 ⭐
│   │   └── payment_screen.dart        # 支付页面 ⭐
│   ├── home/
│   │   └── home_screen.dart           # 更新个人中心和创作页面
│   └── splash/
│       └── splash_screen.dart
├── widgets/
│   ├── common_widgets.dart
│   ├── music_player.dart
│   └── quota_dialogs.dart             # 次数提示对话框 ⭐
└── utils/
    └── theme.dart                     # 主题配置
```

## 新增依赖

```yaml
dependencies:
  # 原有依赖...
  dio: ^5.4.0                          # HTTP客户端（可选）
  # 支付SDK（需要时添加）
  # fluwx: ^4.5.0                       # 微信支付
  # tobias: ^3.3.0                      # 支付宝
```

## 后端API对接

详见 `MEMBERSHIP_API.md` 文件，包含完整的API接口文档。

## 使用说明

### 1. 初始化

在 `main.dart` 中已自动初始化：

```dart
// 在 Consumer2 中自动调用
if (!membershipProvider.isLoading && membershipProvider.user == null) {
  membershipProvider.initialize();
}
```

### 2. 检查登录状态

```dart
final membershipProvider = context.read<MembershipProvider>();
if (membershipProvider.isLoggedIn) {
  // 已登录
}
```

### 3. 检查生成次数

```dart
// 自动显示提示对话框
final canProceed = await checkAndShowQuotaDialog(
  context,
  isLoggedIn: membershipProvider.isLoggedIn,
  remainingQuota: membershipProvider.remainingGenerations,
);
```

### 4. 跳转到会员中心

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const MembershipScreen(),
  ),
);
```

### 5. 跳转到登录页面

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const LoginScreen(),
  ),
);
```

## 主题色

保持原有紫色主题：
- 主色：`#6C5DD3`
- 次色：`#8B5CF6`
- 强调色：`#00D4AA`
- 深色背景：`#0F0F1E`
- 深色表面：`#1A1A2E`

## 会员等级颜色

- 免费用户：灰色
- 基础会员：铜色 `#CD7F32`
- 高级会员：银色 `#C0C0C0`
- VIP会员：金色 `#FFD700`

## 待集成项

1. **微信SDK集成**
   - 添加 `fluwx` 依赖
   - 配置微信AppID
   - 实现 `_loginWithWechat()` 方法

2. **支付宝SDK集成**
   - 添加 `tobias` 依赖
   - 配置支付宝参数
   - 实现 `_invokePayment()` 方法

3. **后端API配置**
   - 修改 `MembershipApiConfig.baseUrl` 为实际API地址
   - 配置微信AppID和支付宝参数

4. **推送通知**
   - 支付成功通知
   - 会员到期提醒

## 注意事项

1. 所有API请求都会自动携带Token
2. Token过期时会自动尝试刷新
3. 生成次数在本地有缓存，但会定期同步
4. 支付成功后需要轮询订单状态确认
