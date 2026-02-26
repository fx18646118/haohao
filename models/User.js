const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  // 基本信息
  phone: {
    type: String,
    unique: true,
    sparse: true,
    index: true
  },
  
  // 微信 OAuth 信息
  wechat: {
    openid: {
      type: String,
      unique: true,
      sparse: true,
      index: true
    },
    unionid: {
      type: String,
      unique: true,
      sparse: true
    },
    nickname: String,
    avatarUrl: String,
    gender: Number, // 0:未知, 1:男, 2:女
    country: String,
    province: String,
    city: String
  },

  // 会员信息
  membership: {
    level: {
      type: String,
      enum: ['free', 'monthly', 'yearly'],
      default: 'free'
    },
    expiresAt: {
      type: Date,
      default: null
    },
    startedAt: {
      type: Date,
      default: null
    }
  },

  // 每日生成次数统计
  dailyStats: {
    date: {
      type: String, // YYYY-MM-DD 格式
      default: () => new Date().toISOString().split('T')[0]
    },
    usedCount: {
      type: Number,
      default: 0
    },
    totalCount: {
      type: Number,
      default: 3 // 免费用户默认3次
    }
  },

  // 用户设置
  settings: {
    language: {
      type: String,
      default: 'zh-CN'
    },
    notifications: {
      type: Boolean,
      default: true
    }
  },

  // 状态
  status: {
    type: String,
    enum: ['active', 'inactive', 'banned'],
    default: 'active'
  },

  // 最后登录
  lastLoginAt: {
    type: Date,
    default: Date.now
  },

  // 登录 IP
  lastLoginIp: String

}, {
  timestamps: true
});

// 索引
userSchema.index({ 'wechat.openid': 1 });
userSchema.index({ phone: 1 });
userSchema.index({ 'membership.level': 1 });
userSchema.index({ 'membership.expiresAt': 1 });

// 检查会员是否有效
userSchema.methods.isMembershipValid = function() {
  if (this.membership.level === 'free') {
    return true;
  }
  return this.membership.expiresAt && this.membership.expiresAt > new Date();
};

// 获取每日限制次数
userSchema.methods.getDailyLimit = function() {
  const { MEMBERSHIP_LEVELS } = require('../config/constants');
  const level = this.membership.level;
  
  // 检查会员是否过期
  if (level !== 'free' && !this.isMembershipValid()) {
    return MEMBERSHIP_LEVELS.FREE.dailyLimit;
  }
  
  return MEMBERSHIP_LEVELS[level.toUpperCase()].dailyLimit;
};

// 检查今日是否还有剩余次数
userSchema.methods.hasRemainingGenerations = function() {
  const today = new Date().toISOString().split('T')[0];
  
  // 如果是新的一天，重置计数
  if (this.dailyStats.date !== today) {
    this.dailyStats.date = today;
    this.dailyStats.usedCount = 0;
    this.dailyStats.totalCount = this.getDailyLimit();
    return true;
  }
  
  return this.dailyStats.usedCount < this.dailyStats.totalCount;
};

// 获取剩余次数
userSchema.methods.getRemainingGenerations = function() {
  const today = new Date().toISOString().split('T')[0];
  
  // 如果是新的一天，重置计数
  if (this.dailyStats.date !== today) {
    this.dailyStats.date = today;
    this.dailyStats.usedCount = 0;
    this.dailyStats.totalCount = this.getDailyLimit();
    return this.dailyStats.totalCount;
  }
  
  return Math.max(0, this.dailyStats.totalCount - this.dailyStats.usedCount);
};

// 使用一次生成次数
userSchema.methods.useGeneration = async function() {
  const today = new Date().toISOString().split('T')[0];
  
  // 如果是新的一天，重置计数
  if (this.dailyStats.date !== today) {
    this.dailyStats.date = today;
    this.dailyStats.usedCount = 0;
    this.dailyStats.totalCount = this.getDailyLimit();
  }
  
  if (this.dailyStats.usedCount >= this.dailyStats.totalCount) {
    throw new Error('今日生成次数已用完');
  }
  
  this.dailyStats.usedCount += 1;
  await this.save();
  
  return {
    remaining: this.dailyStats.totalCount - this.dailyStats.usedCount,
    used: this.dailyStats.usedCount,
    total: this.dailyStats.totalCount
  };
};

// 升级会员
userSchema.methods.upgradeMembership = async function(level, durationDays) {
  const now = new Date();
  const expiresAt = new Date(now.getTime() + durationDays * 24 * 60 * 60 * 1000);
  
  this.membership.level = level;
  this.membership.startedAt = now;
  this.membership.expiresAt = expiresAt;
  
  // 更新每日限制
  this.dailyStats.totalCount = this.getDailyLimit();
  
  await this.save();
  return this;
};

// 更新最后登录
userSchema.methods.updateLastLogin = async function(ip) {
  this.lastLoginAt = new Date();
  if (ip) this.lastLoginIp = ip;
  await this.save();
};

// 序列化（隐藏敏感信息）
userSchema.methods.toJSON = function() {
  const obj = this.toObject();
  delete obj.__v;
  return obj;
};

module.exports = mongoose.model('User', userSchema);
