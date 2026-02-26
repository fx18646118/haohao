# Tunee Backend API 文档

## 基础信息

- **Base URL**: `https://api.tunee.app/api`
- **Content-Type**: `application/json`
- **认证方式**: Bearer Token

## 认证

所有需要认证的接口需要在请求头中添加：
```
Authorization: Bearer {accessToken}
```

## 响应格式

### 成功响应
```json
{
  "code": 0,
  "message": "操作成功",
  "data": { ... },
  "timestamp": 1700000000000
}
```

### 错误响应
```json
{
  "code": 1,
  "message": "错误信息",
  "data": null,
  "timestamp": 1700000000000
}
```

## 接口列表

### 1. 认证相关

#### 1.1 发送短信验证码
```
POST /auth/send-code
```

**请求参数：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| phone | string | 是 | 手机号 |
| purpose | string | 否 | 用途：login/register/reset_password/bind_phone |

**响应示例：**
```json
{
  "code": 0,
  "message": "验证码已发送",
  "data": {
    "cooldown": 60
  }
}
```

#### 1.2 手机号登录/注册
```
POST /auth/phone-login
```

**请求参数：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| phone | string | 是 | 手机号 |
| code | string | 是 | 6位验证码 |

**响应示例：**
```json
{
  "code": 0,
  "message": "登录成功",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "uuid-refresh-token",
    "expiresIn": 604800,
    "user": {
      "id": "user_id",
      "phone": "13800138000",
      "membership": {
        "level": "free",
        "expiresAt": null
      },
      "dailyStats": {
        "date": "2024-01-01",
        "usedCount": 0,
        "totalCount": 3
      },
      "isNewUser": false
    }
  }
}
```

#### 1.3 微信登录
```
POST /auth/wechat-login
```

**请求参数：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| code | string | 是 | 微信授权码 |

**响应示例：**
```json
{
  "code": 0,
  "message": "登录成功",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "uuid-refresh-token",
    "expiresIn": 604800,
    "user": {
      "id": "user_id",
      "phone": null,
      "wechat": {
        "nickname": "微信昵称",
        "avatarUrl": "https://..."
      },
      "membership": { ... },
      "dailyStats": { ... },
      "isNewUser": true
    }
  }
}
```

#### 1.4 刷新令牌
```
POST /auth/refresh-token
```

**请求参数：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| refreshToken | string | 是 | 刷新令牌 |

#### 1.5 获取当前用户信息
```
GET /user/me
Authorization: Bearer {accessToken}
```

**响应示例：**
```json
{
  "code": 0,
  "message": "操作成功",
  "data": {
    "id": "user_id",
    "phone": "13800138000",
    "wechat": {
      "nickname": "微信昵称",
      "avatarUrl": "https://..."
    },
    "membership": {
      "level": "monthly",
      "isValid": true,
      "expiresAt": "2024-12-31T23:59:59.999Z"
    },
    "dailyStats": {
      "date": "2024-01-01",
      "usedCount": 2,
      "totalCount": 50
    },
    "settings": {
      "language": "zh-CN",
      "notifications": true
    },
    "status": "active"
  }
}
```

#### 1.6 绑定手机号
```
POST /user/bind-phone
Authorization: Bearer {accessToken}
```

**请求参数：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| phone | string | 是 | 手机号 |
| code | string | 是 | 验证码 |

#### 1.7 退出登录
```
POST /user/logout
Authorization: Bearer {accessToken}
```

**请求参数：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| revokeAll | boolean | 否 | 是否撤销所有设备的登录状态 |

---

### 2. 会员相关

#### 2.1 获取会员信息
```
GET /membership/info
Authorization: Bearer {accessToken}
```

**响应示例：**
```json
{
  "code": 0,
  "message": "操作成功",
  "data": {
    "currentLevel": "free",
    "isValid": true,
    "expiresAt": null,
    "startedAt": null,
    "dailyLimit": 3,
    "remainingToday": 1,
    "plans": [
      {
        "type": "monthly",
        "name": "月卡会员",
        "price": 19.9,
        "duration": 30,
        "dailyLimit": 50,
        "features": ["每日50首音乐生成", "优先处理队列", "高清音质下载"]
      },
      {
        "type": "yearly",
        "name": "年卡会员",
        "price": 199,
        "duration": 365,
        "dailyLimit": 50,
        "features": ["每日50首音乐生成", "优先处理队列", "高清音质下载", "专属客服支持", "相当于8.3折"]
      }
    ]
  }
}
```

#### 2.2 创建订单
```
POST /membership/order
Authorization: Bearer {accessToken}
```

**请求参数：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| type | string | 是 | 会员类型：monthly/yearly |
| paymentMethod | string | 是 | 支付方式：wechat/alipay |
| device | string | 否 | 设备信息 |

**响应示例：**
```json
{
  "code": 0,
  "message": "订单创建成功",
  "data": {
    "orderId": "order_object_id",
    "orderNo": "TN2024010112001234",
    "amount": 19.9,
    "type": "monthly",
    "paymentMethod": "wechat",
    "payParams": {
      "timeStamp": "1704096000",
      "nonceStr": "random_string",
      "package": "prepay_id=wx...",
      "signType": "MD5",
      "paySign": "..."
    },
    "expireAt": "2024-01-01T12:30:00.000Z"
  }
}
```

#### 2.3 查询订单状态
```
GET /membership/order/:orderNo
Authorization: Bearer {accessToken}
```

**响应示例：**
```json
{
  "code": 0,
  "message": "操作成功",
  "data": {
    "orderNo": "TN2024010112001234",
    "status": "paid",
    "amount": 19.9,
    "type": "monthly",
    "paymentMethod": "wechat",
    "paidAt": "2024-01-01T12:05:00.000Z",
    "createdAt": "2024-01-01T12:00:00.000Z"
  }
}
```

#### 2.4 获取订单列表
```
GET /membership/orders?page=1&pageSize=10&status=paid
Authorization: Bearer {accessToken}
```

**响应示例：**
```json
{
  "code": 0,
  "message": "操作成功",
  "data": {
    "list": [
      {
        "orderNo": "TN2024010112001234",
        "type": "monthly",
        "amount": 19.9,
        "paymentMethod": "wechat",
        "status": "paid",
        "paidAt": "2024-01-01T12:05:00.000Z",
        "createdAt": "2024-01-01T12:00:00.000Z"
      }
    ],
    "pagination": {
      "page": 1,
      "pageSize": 10,
      "total": 5,
      "totalPages": 1
    }
  }
}
```

---

### 3. 支付相关

#### 3.1 手动查询订单状态
```
GET /payment/order/:orderNo/query
Authorization: Bearer {accessToken}
```

**响应示例：**
```json
{
  "code": 0,
  "message": "操作成功",
  "data": {
    "orderNo": "TN2024010112001234",
    "status": "paid",
    "paidAt": "2024-01-01T12:05:00.000Z"
  }
}
```

---

### 4. 音乐生成相关

#### 4.1 获取今日生成配额
```
GET /generation/quota
Authorization: Bearer {accessToken}
```

**响应示例：**
```json
{
  "code": 0,
  "message": "操作成功",
  "data": {
    "dailyLimit": 50,
    "usedToday": 2,
    "remainingToday": 48,
    "membership": {
      "level": "monthly",
      "isValid": true,
      "expiresAt": "2024-12-31T23:59:59.999Z"
    }
  }
}
```

#### 4.2 创建生成任务
```
POST /generation/create
Authorization: Bearer {accessToken}
```

**请求参数：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| prompt | string | 是 | 音乐描述/提示词（最多500字） |
| style | string | 否 | 音乐风格 |
| mood | string | 否 | 情绪 |
| duration | number | 否 | 时长（秒） |
| options | object | 否 | 其他选项 |
| device | string | 否 | 设备信息 |

**响应示例：**
```json
{
  "code": 0,
  "message": "生成任务已创建",
  "data": {
    "generationId": "uuid-generation-id",
    "status": "pending",
    "quota": {
      "remaining": 47,
      "used": 3,
      "total": 50
    }
  }
}
```

#### 4.3 获取生成任务状态
```
GET /generation/:generationId
Authorization: Bearer {accessToken}
```

**响应示例：**
```json
{
  "code": 0,
  "message": "操作成功",
  "data": {
    "generationId": "uuid-generation-id",
    "status": "completed",
    "params": {
      "style": "pop",
      "mood": "happy",
      "prompt": "一首轻快的流行歌曲",
      "options": {}
    },
    "result": {
      "audioUrl": "https://cdn.tunee.app/audio/xxx.mp3",
      "coverUrl": "https://cdn.tunee.app/cover/xxx.jpg",
      "title": "生成的音乐标题",
      "completedAt": "2024-01-01T12:10:00.000Z"
    },
    "errorMessage": null,
    "createdAt": "2024-01-01T12:00:00.000Z"
  }
}
```

#### 4.4 获取生成历史列表
```
GET /generation?page=1&pageSize=10&status=completed
Authorization: Bearer {accessToken}
```

**响应示例：**
```json
{
  "code": 0,
  "message": "操作成功",
  "data": {
    "list": [
      {
        "generationId": "uuid-generation-id",
        "status": "completed",
        "params": {
          "style": "pop",
          "mood": "happy",
          "prompt": "一首轻快的流行歌曲..."
        },
        "result": {
          "audioUrl": "https://cdn.tunee.app/audio/xxx.mp3",
          "coverUrl": "https://cdn.tunee.app/cover/xxx.jpg",
          "title": "生成的音乐标题"
        },
        "isFavorite": false,
        "createdAt": "2024-01-01T12:00:00.000Z"
      }
    ],
    "pagination": {
      "page": 1,
      "pageSize": 10,
      "total": 25,
      "totalPages": 3
    }
  }
}
```

#### 4.5 收藏/取消收藏
```
POST /generation/:generationId/favorite
Authorization: Bearer {accessToken}
```

**响应示例：**
```json
{
  "code": 0,
  "message": "已收藏",
  "data": {
    "isFavorite": true
  }
}
```

#### 4.6 获取收藏列表
```
GET /generation/favorites/list?page=1&pageSize=10
Authorization: Bearer {accessToken}
```

---

## 错误码说明

| 错误码 | 说明 |
|--------|------|
| 0 | 成功 |
| 1 | 通用错误 |
| 400 | 请求参数错误 |
| 401 | 未授权/令牌无效 |
| 403 | 禁止访问/权限不足 |
| 404 | 资源不存在 |
| 429 | 请求过于频繁 |
| 500 | 服务器内部错误 |
| 1001 | MongoDB 验证错误 |
| 1002 | 无效的 ID 格式 |
| 2001 | JWT 令牌无效 |
| 2002 | JWT 令牌已过期 |
| 11000 | 数据重复 |

## 会员等级说明

| 等级 | 每日限制 | 价格 |
|------|----------|------|
| free | 3首 | 免费 |
| monthly | 50首 | ¥19.9/月 |
| yearly | 50首 | ¥199/年 |

## 支付回调

### 微信支付回调
```
POST /payment/wechat/notify
Content-Type: text/xml
```

### 支付宝支付回调
```
POST /payment/alipay/notify
Content-Type: application/x-www-form-urlencoded
```
