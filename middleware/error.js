// 错误处理中间件
const errorHandler = (err, req, res, next) => {
  console.error('Error:', err);

  // 默认错误响应
  let statusCode = err.statusCode || 500;
  let message = err.message || '服务器内部错误';
  let code = err.code || 1;

  // MongoDB 重复键错误
  if (err.code === 11000) {
    statusCode = 400;
    message = '数据已存在';
    code = 11000;
  }

  // MongoDB 验证错误
  if (err.name === 'ValidationError') {
    statusCode = 400;
    message = Object.values(err.errors).map(e => e.message).join(', ');
    code = 1001;
  }

  // MongoDB CastError（ID 格式错误）
  if (err.name === 'CastError') {
    statusCode = 400;
    message = `无效的 ${err.path}: ${err.value}`;
    code = 1002;
  }

  // JWT 错误
  if (err.name === 'JsonWebTokenError') {
    statusCode = 401;
    message = '无效的令牌';
    code = 2001;
  }

  if (err.name === 'TokenExpiredError') {
    statusCode = 401;
    message = '令牌已过期';
    code = 2002;
  }

  res.status(statusCode).json({
    code,
    message,
    data: null,
    timestamp: Date.now()
  });
};

// 404 处理
const notFound = (req, res) => {
  res.status(404).json({
    code: 404,
    message: '接口不存在',
    data: null,
    timestamp: Date.now()
  });
};

module.exports = {
  errorHandler,
  notFound
};
