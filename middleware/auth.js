const { verifyToken } = require('../utils/jwt');
const User = require('../models/User');

// JWT 认证中间件
const auth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        code: 401,
        message: '未提供认证令牌',
        data: null
      });
    }

    const token = authHeader.substring(7);
    const decoded = verifyToken(token);

    if (!decoded) {
      return res.status(401).json({
        code: 401,
        message: '认证令牌无效或已过期',
        data: null
      });
    }

    // 获取用户信息
    const user = await User.findById(decoded.userId);

    if (!user) {
      return res.status(401).json({
        code: 401,
        message: '用户不存在',
        data: null
      });
    }

    if (user.status === 'banned') {
      return res.status(403).json({
        code: 403,
        message: '账号已被禁用',
        data: null
      });
    }

    req.user = user;
    req.userId = user._id.toString();
    next();
  } catch (error) {
    return res.status(401).json({
      code: 401,
      message: '认证失败',
      data: null
    });
  }
};

// 可选认证（不强制要求登录）
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      req.user = null;
      req.userId = null;
      return next();
    }

    const token = authHeader.substring(7);
    const decoded = verifyToken(token);

    if (!decoded) {
      req.user = null;
      req.userId = null;
      return next();
    }

    const user = await User.findById(decoded.userId);
    
    if (user && user.status !== 'banned') {
      req.user = user;
      req.userId = user._id.toString();
    } else {
      req.user = null;
      req.userId = null;
    }

    next();
  } catch (error) {
    req.user = null;
    req.userId = null;
    next();
  }
};

// 管理员权限检查
const adminOnly = (req, res, next) => {
  if (!req.user || req.user.role !== 'admin') {
    return res.status(403).json({
      code: 403,
      message: '需要管理员权限',
      data: null
    });
  }
  next();
};

module.exports = {
  auth,
  optionalAuth,
  adminOnly
};
