const Order = require('../models/Order');
const User = require('../models/User');
const { xmlToObject, verifyWechatSign } = require('../utils/crypto');
const { success, error } = require('../utils/response');
const { MEMBERSHIP_LEVELS } = require('../config/constants');

// 微信支付回调
const wechatNotify = async (req, res) => {
  try {
    const xmlData = req.body;
    const result = xmlToObject(xmlData);

    console.log('[Wechat Notify]', result);

    // 验证签名
    const WECHAT_PAY_KEY = process.env.WECHAT_PAY_KEY;
    if (!verifyWechatSign({ ...result }, WECHAT_PAY_KEY)) {
      console.error('[Wechat Notify] 签名验证失败');
      return res.set('Content-Type', 'application/xml').send(`<xml>
        <return_code><![CDATA[FAIL]]></return_code>
        <return_msg><![CDATA[签名验证失败]]></return_msg>
      </xml>`);
    }

    // 检查业务结果
    if (result.return_code !== 'SUCCESS' || result.result_code !== 'SUCCESS') {
      console.error('[Wechat Notify] 支付失败:', result.return_msg || result.err_code_des);
      return res.set('Content-Type', 'application/xml').send(`<xml>
        <return_code><![CDATA[SUCCESS]]></return_code>
      </xml>`);
    }

    const orderNo = result.out_trade_no;
    const transactionId = result.transaction_id;

    // 查找订单
    const order = await Order.findOne({ orderNo });

    if (!order) {
      console.error('[Wechat Notify] 订单不存在:', orderNo);
      return res.set('Content-Type', 'application/xml').send(`<xml>
        <return_code><![CDATA[FAIL]]></return_code>
        <return_msg><![CDATA[订单不存在]]></return_msg>
      </xml>`);
    }

    // 检查订单状态
    if (order.status === 'paid') {
      return res.set('Content-Type', 'application/xml').send(`<xml>
        <return_code><![CDATA[SUCCESS]]></return_code>
      </xml>`);
    }

    // 验证金额
    const totalFee = parseInt(result.total_fee);
    const orderAmount = Math.round(order.amount * 100);
    if (totalFee !== orderAmount) {
      console.error('[Wechat Notify] 金额不匹配:', totalFee, orderAmount);
      return res.set('Content-Type', 'application/xml').send(`<xml>
        <return_code><![CDATA[FAIL]]></return_code>
        <return_msg><![CDATA[金额不匹配]]></return_msg>
      </xml>`);
    }

    // 更新订单状态
    order.status = 'paid';
    order.paidAt = new Date();
    order.thirdParty.wechat.transactionId = transactionId;
    await order.save();

    // 更新用户会员状态
    const membershipConfig = MEMBERSHIP_LEVELS[order.type.toUpperCase()];
    const user = await User.findById(order.user);
    await user.upgradeMembership(order.type, membershipConfig.duration);

    console.log('[Wechat Notify] 支付成功:', orderNo);

    // 返回成功响应
    res.set('Content-Type', 'application/xml').send(`<xml>
      <return_code><![CDATA[SUCCESS]]></return_code>
      <return_msg><![CDATA[OK]]></return_msg>
    </xml>`);
  } catch (err) {
    console.error('[Wechat Notify] 处理失败:', err);
    res.set('Content-Type', 'application/xml').send(`<xml>
      <return_code><![CDATA[FAIL]]></return_code>
      <return_msg><![CDATA[处理失败]]></return_msg>
    </xml>`);
  }
};

// 支付宝支付回调
const alipayNotify = async (req, res) => {
  try {
    const params = req.body;

    console.log('[Alipay Notify]', params);

    // 验证签名
    const { verifyAlipaySign } = require('../utils/crypto');
    const ALIPAY_PUBLIC_KEY = process.env.ALIPAY_PUBLIC_KEY;
    
    if (!verifyAlipaySign({ ...params }, ALIPAY_PUBLIC_KEY)) {
      console.error('[Alipay Notify] 签名验证失败');
      return res.send('fail');
    }

    // 检查交易状态
    const tradeStatus = params.trade_status;
    if (tradeStatus !== 'TRADE_SUCCESS' && tradeStatus !== 'TRADE_FINISHED') {
      console.log('[Alipay Notify] 交易状态:', tradeStatus);
      return res.send('success');
    }

    const orderNo = params.out_trade_no;
    const tradeNo = params.trade_no;
    const buyerId = params.buyer_id;

    // 查找订单
    const order = await Order.findOne({ orderNo });

    if (!order) {
      console.error('[Alipay Notify] 订单不存在:', orderNo);
      return res.send('fail');
    }

    // 检查订单状态
    if (order.status === 'paid') {
      return res.send('success');
    }

    // 验证金额
    const totalAmount = parseFloat(params.total_amount);
    if (Math.abs(totalAmount - order.amount) > 0.01) {
      console.error('[Alipay Notify] 金额不匹配:', totalAmount, order.amount);
      return res.send('fail');
    }

    // 更新订单状态
    order.status = 'paid';
    order.paidAt = new Date();
    order.thirdParty.alipay = {
      tradeNo,
      buyerId,
      buyerLogonId: params.buyer_logon_id
    };
    await order.save();

    // 更新用户会员状态
    const membershipConfig = MEMBERSHIP_LEVELS[order.type.toUpperCase()];
    const user = await User.findById(order.user);
    await user.upgradeMembership(order.type, membershipConfig.duration);

    console.log('[Alipay Notify] 支付成功:', orderNo);

    res.send('success');
  } catch (err) {
    console.error('[Alipay Notify] 处理失败:', err);
    res.send('fail');
  }
};

// 手动查询订单状态（用于前端轮询）
const queryOrder = async (req, res) => {
  try {
    const { orderNo } = req.params;
    const userId = req.userId;

    const order = await Order.findOne({ orderNo, user: userId });

    if (!order) {
      return error(res, '订单不存在', 404);
    }

    // 如果订单未支付，查询第三方支付状态
    if (order.status === 'pending') {
      if (order.paymentMethod === 'wechat') {
        const { queryOrder: queryWechatOrder } = require('../utils/wechat');
        const wechatResult = await queryWechatOrder(orderNo);
        
        if (wechatResult.trade_state === 'SUCCESS') {
          order.status = 'paid';
          order.paidAt = new Date();
          order.thirdParty.wechat.transactionId = wechatResult.transaction_id;
          await order.save();

          // 更新用户会员状态
          const membershipConfig = MEMBERSHIP_LEVELS[order.type.toUpperCase()];
          const user = await User.findById(order.user);
          await user.upgradeMembership(order.type, membershipConfig.duration);
        }
      } else if (order.paymentMethod === 'alipay') {
        const { queryAlipayOrder } = require('../utils/alipay');
        const alipayResult = await queryAlipayOrder(orderNo);
        
        if (alipayResult.trade_status === 'TRADE_SUCCESS') {
          order.status = 'paid';
          order.paidAt = new Date();
          order.thirdParty.alipay = {
            tradeNo: alipayResult.trade_no,
            buyerId: alipayResult.buyer_user_id
          };
          await order.save();

          // 更新用户会员状态
          const membershipConfig = MEMBERSHIP_LEVELS[order.type.toUpperCase()];
          const user = await User.findById(order.user);
          await user.upgradeMembership(order.type, membershipConfig.duration);
        }
      }
    }

    success(res, {
      orderNo: order.orderNo,
      status: order.status,
      paidAt: order.paidAt
    });
  } catch (err) {
    error(res, err.message, 500);
  }
};

module.exports = {
  wechatNotify,
  alipayNotify,
  queryOrder
};
