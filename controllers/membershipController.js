const Order = require('../models/Order');
const User = require('../models/User');
const { MEMBERSHIP_LEVELS } = require('../config/constants');
const { createUnifiedOrder, generatePayParams } = require('../utils/wechat');
const { createAlipayOrder } = require('../utils/alipay');
const { success, error } = require('../utils/response');

// 创建订单
const createOrder = async (req, res) => {
  try {
    const { type, paymentMethod } = req.body;
    const userId = req.userId;

    // 验证参数
    if (!type || !['monthly', 'yearly'].includes(type)) {
      return error(res, '无效的会员类型', 400);
    }

    if (!paymentMethod || !['wechat', 'alipay'].includes(paymentMethod)) {
      return error(res, '无效的支付方式', 400);
    }

    const membershipConfig = MEMBERSHIP_LEVELS[type.toUpperCase()];
    if (!membershipConfig) {
      return error(res, '会员类型配置错误', 400);
    }

    // 生成订单号
    const orderNo = Order.generateOrderNo();

    // 创建订单
    const order = await Order.create({
      orderNo,
      user: userId,
      type,
      amount: membershipConfig.price,
      paymentMethod,
      clientInfo: {
        ip: req.ip,
        userAgent: req.headers['user-agent'],
        device: req.body.device
      }
    });

    // 获取支付参数
    let payParams = null;
    const user = await User.findById(userId);

    if (paymentMethod === 'wechat') {
      // 需要 openid
      if (!user.wechat || !user.wechat.openid) {
        return error(res, '请先绑定微信', 400);
      }

      const wechatOrder = await createUnifiedOrder(order, user.wechat.openid);
      
      // 更新订单信息
      order.thirdParty.wechat = {
        prepayId: wechatOrder.prepay_id,
        nonceStr: wechatOrder.nonce_str
      };
      await order.save();

      payParams = generatePayParams(wechatOrder.prepay_id);
    } else if (paymentMethod === 'alipay') {
      payParams = await createAlipayOrder(order);
    }

    success(res, {
      orderId: order._id,
      orderNo: order.orderNo,
      amount: order.amount,
      type: order.type,
      paymentMethod: order.paymentMethod,
      payParams,
      expireAt: order.expireAt
    }, '订单创建成功');
  } catch (err) {
    error(res, err.message, 500);
  }
};

// 查询订单状态
const getOrderStatus = async (req, res) => {
  try {
    const { orderNo } = req.params;
    const userId = req.userId;

    const order = await Order.findOne({ orderNo, user: userId });

    if (!order) {
      return error(res, '订单不存在', 404);
    }

    success(res, {
      orderNo: order.orderNo,
      status: order.status,
      amount: order.amount,
      type: order.type,
      paymentMethod: order.paymentMethod,
      paidAt: order.paidAt,
      createdAt: order.createdAt
    });
  } catch (err) {
    error(res, err.message, 500);
  }
};

// 获取订单列表
const getOrders = async (req, res) => {
  try {
    const userId = req.userId;
    const { page = 1, pageSize = 10, status } = req.query;

    const query = { user: userId };
    if (status) {
      query.status = status;
    }

    const total = await Order.countDocuments(query);
    const orders = await Order.find(query)
      .sort({ createdAt: -1 })
      .skip((page - 1) * pageSize)
      .limit(parseInt(pageSize));

    success(res, {
      list: orders.map(order => ({
        orderNo: order.orderNo,
        type: order.type,
        amount: order.amount,
        paymentMethod: order.paymentMethod,
        status: order.status,
        paidAt: order.paidAt,
        createdAt: order.createdAt
      })),
      pagination: {
        page: parseInt(page),
        pageSize: parseInt(pageSize),
        total,
        totalPages: Math.ceil(total / pageSize)
      }
    });
  } catch (err) {
    error(res, err.message, 500);
  }
};

// 获取会员信息
const getMembershipInfo = async (req, res) => {
  try {
    const user = req.user;

    success(res, {
      currentLevel: user.membership.level,
      isValid: user.isMembershipValid(),
      expiresAt: user.membership.expiresAt,
      startedAt: user.membership.startedAt,
      dailyLimit: user.getDailyLimit(),
      remainingToday: user.getRemainingGenerations(),
      plans: [
        {
          type: 'monthly',
          name: '月卡会员',
          price: MEMBERSHIP_LEVELS.MONTHLY.price,
          duration: MEMBERSHIP_LEVELS.MONTHLY.duration,
          dailyLimit: MEMBERSHIP_LEVELS.MONTHLY.dailyLimit,
          features: [
            '每日50首音乐生成',
            '优先处理队列',
            '高清音质下载'
          ]
        },
        {
          type: 'yearly',
          name: '年卡会员',
          price: MEMBERSHIP_LEVELS.YEARLY.price,
          duration: MEMBERSHIP_LEVELS.YEARLY.duration,
          dailyLimit: MEMBERSHIP_LEVELS.YEARLY.dailyLimit,
          features: [
            '每日50首音乐生成',
            '优先处理队列',
            '高清音质下载',
            '专属客服支持',
            '相当于8.3折'
          ]
        }
      ]
    });
  } catch (err) {
    error(res, err.message, 500);
  }
};

module.exports = {
  createOrder,
  getOrderStatus,
  getOrders,
  getMembershipInfo
};
