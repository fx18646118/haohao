const mongoose = require('mongoose');

const smsCodeSchema = new mongoose.Schema({
  // 手机号
  phone: {
    type: String,
    required: true,
    index: true
  },

  // 验证码
  code: {
    type: String,
    required: true
  },

  // 用途
  purpose: {
    type: String,
    enum: ['login', 'register', 'reset_password', 'bind_phone'],
    default: 'login'
  },

  // 是否已使用
  used: {
    type: Boolean,
    default: false
  },

  // 过期时间
  expireAt: {
    type: Date,
    required: true
  },

  // 尝试次数
  attempts: {
    type: Number,
    default: 0
  },

  // 客户端IP
  ip: String

}, {
  timestamps: true
});

// TTL 索引，自动删除过期验证码
smsCodeSchema.index({ expireAt: 1 }, { expireAfterSeconds: 0 });
smsCodeSchema.index({ phone: 1, createdAt: -1 });

module.exports = mongoose.model('SmsCode', smsCodeSchema);
