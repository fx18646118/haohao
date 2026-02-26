const mongoose = require('mongoose');

// 刷新令牌，用于实现 JWT 自动续期
const refreshTokenSchema = new mongoose.Schema({
  // 用户
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },

  // 令牌
  token: {
    type: String,
    required: true,
    unique: true
  },

  // 过期时间
  expireAt: {
    type: Date,
    required: true
  },

  // 是否已使用
  used: {
    type: Boolean,
    default: false
  },

  // 客户端信息
  clientInfo: {
    ip: String,
    userAgent: String,
    device: String
  }

}, {
  timestamps: true
});

// TTL 索引
refreshTokenSchema.index({ expireAt: 1 }, { expireAfterSeconds: 0 });
refreshTokenSchema.index({ user: 1 });
refreshTokenSchema.index({ token: 1 });

module.exports = mongoose.model('RefreshToken', refreshTokenSchema);
