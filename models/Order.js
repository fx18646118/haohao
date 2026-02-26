const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema({
  // 订单号
  orderNo: {
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

  // 订单类型
  type: {
    type: String,
    enum: ['monthly', 'yearly'],
    required: true
  },

  // 订单金额（元）
  amount: {
    type: Number,
    required: true
  },

  // 支付方式
  paymentMethod: {
    type: String,
    enum: ['wechat', 'alipay'],
    required: true
  },

  // 支付状态
  status: {
    type: String,
    enum: ['pending', 'paid', 'failed', 'refunded', 'cancelled'],
    default: 'pending'
  },

  // 第三方支付信息
  thirdParty: {
    // 微信支付
    wechat: {
      prepayId: String,
      transactionId: String,
      nonceStr: String,
      timeStamp: String,
      sign: String
    },
    // 支付宝
    alipay: {
      tradeNo: String,
      buyerId: String,
      buyerLogonId: String
    }
  },

  // 支付时间
  paidAt: {
    type: Date,
    default: null
  },

  // 过期时间（用于自动取消）
  expireAt: {
    type: Date,
    default: () => new Date(Date.now() + 30 * 60 * 1000) // 30分钟后过期
  },

  // 退款信息
  refund: {
    amount: Number,
    reason: String,
    refundedAt: Date,
    refundNo: String
  },

  // 客户端信息
  clientInfo: {
    ip: String,
    userAgent: String,
    device: String
  },

  // 备注
  remark: String

}, {
  timestamps: true
});

// 索引
orderSchema.index({ orderNo: 1 });
orderSchema.index({ user: 1, status: 1 });
orderSchema.index({ createdAt: -1 });
orderSchema.index({ expireAt: 1 }, { expireAfterSeconds: 0 }); // TTL 索引，自动删除过期订单

// 生成订单号
orderSchema.statics.generateOrderNo = function() {
  const date = new Date();
  const prefix = 'TN';
  const timestamp = date.getFullYear().toString() +
    String(date.getMonth() + 1).padStart(2, '0') +
    String(date.getDate()).padStart(2, '0') +
    String(date.getHours()).padStart(2, '0') +
    String(date.getMinutes()).padStart(2, '0');
  const random = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
  return `${prefix}${timestamp}${random}`;
};

// 序列化
orderSchema.methods.toJSON = function() {
  const obj = this.toObject();
  delete obj.__v;
  return obj;
};

module.exports = mongoose.model('Order', orderSchema);
