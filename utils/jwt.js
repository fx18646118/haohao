const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const RefreshToken = require('../models/RefreshToken');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';
const REFRESH_TOKEN_EXPIRES_IN = 30 * 24 * 60 * 60 * 1000; // 30天

// 生成 JWT Token
const generateToken = (user) => {
  const payload = {
    userId: user._id.toString(),
    phone: user.phone,
    membership: user.membership.level,
    iat: Date.now()
  };

  return jwt.sign(payload, JWT_SECRET, {
    expiresIn: JWT_EXPIRES_IN
  });
};

// 生成刷新令牌
const generateRefreshToken = async (user, clientInfo = {}) => {
  const token = uuidv4();
  const expireAt = new Date(Date.now() + REFRESH_TOKEN_EXPIRES_IN);

  await RefreshToken.create({
    user: user._id,
    token,
    expireAt,
    clientInfo
  });

  return token;
};

// 验证 JWT Token
const verifyToken = (token) => {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (error) {
    return null;
  }
};

// 验证刷新令牌
const verifyRefreshToken = async (token) => {
  const refreshToken = await RefreshToken.findOne({
    token,
    used: false,
    expireAt: { $gt: new Date() }
  }).populate('user');

  if (!refreshToken) {
    return null;
  }

  return refreshToken;
};

// 使刷新令牌失效
const revokeRefreshToken = async (token) => {
  await RefreshToken.updateOne(
    { token },
    { used: true }
  );
};

// 使用刷新令牌获取新令牌
const refreshAccessToken = async (refreshTokenString, clientInfo = {}) => {
  const refreshToken = await verifyRefreshToken(refreshTokenString);
  
  if (!refreshToken) {
    throw new Error('无效的刷新令牌');
  }

  // 使旧令牌失效
  await revokeRefreshToken(refreshTokenString);

  // 生成新令牌
  const accessToken = generateToken(refreshToken.user);
  const newRefreshToken = await generateRefreshToken(refreshToken.user, clientInfo);

  return {
    accessToken,
    refreshToken: newRefreshToken,
    user: refreshToken.user
  };
};

module.exports = {
  generateToken,
  generateRefreshToken,
  verifyToken,
  verifyRefreshToken,
  revokeRefreshToken,
  refreshAccessToken
};
