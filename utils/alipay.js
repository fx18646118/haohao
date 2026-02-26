const axios = require('axios');
const crypto = require('crypto');
const { generateAlipaySign, verifyAlipaySign } = require('./crypto');

const ALIPAY_APP_ID = process.env.ALIPAY_APP_ID;
const ALIPAY_PRIVATE_KEY = process.env.ALIPAY_PRIVATE_KEY;
const ALIPAY_PUBLIC_KEY = process.env.ALIPAY_PUBLIC_KEY;
const ALIPAY_NOTIFY_URL = process.env.ALIPAY_NOTIFY_URL;
const ALIPAY_GATEWAY = 'https://openapi.alipay.com/gateway.do';

// 创建支付宝订单
const createAlipayOrder = async (order) => {
  try {
    const bizContent = {
      out_trade_no: order.orderNo,
      total_amount: order.amount.toFixed(2),
      subject: `Tunee ${order.type === 'monthly' ? '月卡' : '年卡'}会员`,
      product_code: 'QUICK_MSECURITY_PAY',
      timeout_express: '30m'
    };

    const params = {
      app_id: ALIPAY_APP_ID,
      method: 'alipay.trade.app.pay',
      charset: 'utf-8',
      sign_type: 'RSA2',
      timestamp: new Date().toISOString().replace(/T/, ' ').replace(/\.\d+Z/, ''),
      version: '1.0',
      notify_url: ALIPAY_NOTIFY_URL,
      biz_content: JSON.stringify(bizContent)
    };

    params.sign = generateAlipaySign(params, ALIPAY_PRIVATE_KEY);

    // 构建请求字符串
    const requestStr = Object.keys(params)
      .map(k => `${k}=${encodeURIComponent(params[k])}`)
      .join('&');

    return requestStr;
  } catch (error) {
    throw new Error(`创建支付宝订单失败: ${error.message}`);
  }
};

// 验证支付宝回调
const verifyAlipayCallback = (params) => {
  return verifyAlipaySign(params, ALIPAY_PUBLIC_KEY);
};

// 查询支付宝订单
const queryAlipayOrder = async (orderNo) => {
  try {
    const bizContent = {
      out_trade_no: orderNo
    };

    const params = {
      app_id: ALIPAY_APP_ID,
      method: 'alipay.trade.query',
      charset: 'utf-8',
      sign_type: 'RSA2',
      timestamp: new Date().toISOString().replace(/T/, ' ').replace(/\.\d+Z/, ''),
      version: '1.0',
      biz_content: JSON.stringify(bizContent)
    };

    params.sign = generateAlipaySign(params, ALIPAY_PRIVATE_KEY);

    const response = await axios.post(ALIPAY_GATEWAY, params, {
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
    });

    return response.data.alipay_trade_query_response;
  } catch (error) {
    throw new Error(`查询支付宝订单失败: ${error.message}`);
  }
};

module.exports = {
  createAlipayOrder,
  verifyAlipayCallback,
  queryAlipayOrder
};
