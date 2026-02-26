# 开发指南

## 本地开发

### 1. 环境准备

```bash
# 安装 Node.js 18+
# 安装 MongoDB（本地或 Docker）

# 克隆项目
git clone <repo-url>
cd tunee-backend-api

# 安装依赖
npm install
```

### 2. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env 文件，填写你的配置
```

### 3. 启动开发服务器

```bash
npm run dev
```

服务将启动在 `http://localhost:3000`

### 4. 测试 API

```bash
# 健康检查
curl http://localhost:3000/health

# 发送验证码
curl -X POST http://localhost:3000/api/auth/send-code \
  -H "Content-Type: application/json" \
  -d '{"phone": "13800138000"}'

# 手机号登录（使用控制台输出的验证码）
curl -X POST http://localhost:3000/api/auth/phone-login \
  -H "Content-Type: application/json" \
  -d '{"phone": "13800138000", "code": "123456"}'
```

## 代码规范

### 目录命名
- 小写字母
- 复数形式（controllers, models, routes）

### 文件命名
- 控制器：`*Controller.js`
- 模型：首字母大写，单数形式（`User.js`）
- 路由：小写（`auth.js`）
- 工具：小写（`jwt.js`）

### 代码风格
- 使用 async/await
- 统一错误处理
- 统一响应格式

## 添加新接口

### 1. 创建控制器方法

```javascript
// controllers/exampleController.js
const { success, error } = require('../utils/response');

const exampleMethod = async (req, res) => {
  try {
    // 业务逻辑
    const data = await someService.doSomething();
    success(res, data, '操作成功');
  } catch (err) {
    error(res, err.message, 500);
  }
};

module.exports = { exampleMethod };
```

### 2. 创建路由

```javascript
// routes/example.js
const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');
const exampleController = require('../controllers/exampleController');

router.get('/example', auth, exampleController.exampleMethod);

module.exports = router;
```

### 3. 注册路由

```javascript
// server.js
const exampleRoutes = require('./routes/example');
app.use('/api/example', exampleRoutes);
```

## 数据库操作

### 添加新模型

```javascript
// models/Example.js
const mongoose = require('mongoose');

const exampleSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },
  // ... 其他字段
}, {
  timestamps: true
});

// 索引
exampleSchema.index({ name: 1 });

module.exports = mongoose.model('Example', exampleSchema);
```

## 测试

### 单元测试
```bash
# 安装测试框架
npm install --save-dev jest supertest

# 运行测试
npm test
```

### API 测试
推荐使用 Postman 或 Insomnia 进行 API 测试。

## 调试技巧

### 1. 使用 VS Code 调试

创建 `.vscode/launch.json`：

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Debug Server",
      "skipFiles": ["<node_internals>/**"],
      "program": "${workspaceFolder}/server.js",
      "envFile": "${workspaceFolder}/.env"
    }
  ]
}
```

### 2. 日志调试

```javascript
console.log('[Debug]', variable);
console.error('[Error]', error);
```

### 3. MongoDB 调试

在连接配置中启用调试：
```javascript
mongoose.set('debug', true);
```

## 常见问题

### 端口被占用
```bash
# 查找占用 3000 端口的进程
lsof -i :3000

# 杀死进程
kill -9 <PID>
```

### MongoDB 连接失败
1. 检查 MongoDB 是否已启动
2. 检查连接字符串是否正确
3. 检查网络连接

### 热重载不生效
```bash
# 手动重启
rs

# 或完全重启
Ctrl+C && npm run dev
```
