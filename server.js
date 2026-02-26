require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');

const connectDB = require('./config/database');
const { errorHandler, notFound } = require('./middleware/error');

// 路由
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/user');
const membershipRoutes = require('./routes/membership');
const paymentRoutes = require('./routes/payment');
const paymentAuthRoutes = require('./routes/paymentAuth');
const generationRoutes = require('./routes/generation');

const app = express();

// 连接数据库
connectDB();

// 中间件
app.use(helmet());
app.use(compression());
app.use(cors());
app.use(morgan('dev'));

// 解析 JSON（支付回调需要特殊处理，所以放在路由之后）
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 健康检查
app.get('/health', (req, res) => {
  res.json({
    code: 0,
    message: 'OK',
    data: {
      status: 'healthy',
      timestamp: Date.now(),
      version: process.env.npm_package_version || '1.0.0'
    }
  });
});

// API 路由
app.use('/api/auth', authRoutes);
app.use('/api/user', userRoutes);
app.use('/api/membership', membershipRoutes);
app.use('/api/payment', paymentRoutes);
app.use('/api/payment', paymentAuthRoutes);
app.use('/api/generation', generationRoutes);

// 404 处理
app.use(notFound);

// 错误处理
app.use(errorHandler);

// 启动服务器
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

module.exports = app;
