const mongoose = require('mongoose');

const generationSchema = new mongoose.Schema({
  // 生成记录ID
  generationId: {
    type: String,
    required: true,
    unique: true,
    index: true
  },

  // 用户
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },

  // 生成参数
  params: {
    // 音乐风格
    style: String,
    // 情绪
    mood: String,
    // 时长（秒）
    duration: Number,
    // 描述/提示词
    prompt: String,
    // 其他参数
    options: {
      type: mongoose.Schema.Types.Mixed,
      default: {}
    }
  },

  // 生成结果
  result: {
    // 状态
    status: {
      type: String,
      enum: ['pending', 'processing', 'completed', 'failed'],
      default: 'pending'
    },
    // 音乐URL
    audioUrl: String,
    // 封面URL
    coverUrl: String,
    // 标题
    title: String,
    // 失败原因
    errorMessage: String,
    // 完成时间
    completedAt: Date
  },

  // 使用的生成次数
  usedQuota: {
    type: Boolean,
    default: true
  },

  // 客户端信息
  clientInfo: {
    ip: String,
    userAgent: String,
    device: String
  },

  // 是否收藏
  isFavorite: {
    type: Boolean,
    default: false
  },

  // 收藏时间
  favoritedAt: Date

}, {
  timestamps: true
});

// 索引
generationSchema.index({ user: 1, createdAt: -1 });
generationSchema.index({ user: 1, 'result.status': 1 });
generationSchema.index({ generationId: 1 });
generationSchema.index({ createdAt: -1 });

// 序列化
generationSchema.methods.toJSON = function() {
  const obj = this.toObject();
  delete obj.__v;
  return obj;
};

module.exports = mongoose.model('Generation', generationSchema);
