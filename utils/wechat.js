const axios = require('axios');
const { generateNonceStr, generateTimestamp, generateWechatSign, objectToXml, xmlToObject } = require('./crypto');

const WECHAT_APP_ID = process.env.WECHAT_APP_ID;
const WECHAT_APP_SECRET = process.env.WECHAT_APP_SECRET;
const WECHAT_PAY_MCH_ID = process.env.WECHAT_PAY_MCH_ID;
const WECHAT_PAY_KEY = process.env.WECHAT_PAY_KEY;
const WECHAT_PAY_NOTIFY_URL = process.env.WECHAT_PAY_NOTIFY_URL;

// 获取微信 Access Token
const getWechatAccessToken = async (code) => {
  try {
    const response = await axios.get('https://api.weixin.qq.com/sns/oauth2/access_token', {
      params: {
        appid: WECHAT_APP_ID,
        secret: WECHAT_APP_SECRET,
        code,
        grant_type: 'authorization_code'
      }
    });

    if (response.data.errcode) {
      throw new Error(response.data.errmsg);
    }

    return response.data;
  } catch (error) {
    throw new Error(`获取微信 Access Token 失败: ${error.message}`);
  }
};

// 获取微信用户信息
const getWechatUserInfo = async (accessToken, openid) => {
  try {
    const response = await axios.get('https://api.weixin.qq.com/sns/userinfo', {
      params: {
        access_token: accessToken,
        openid,
        lang: 'zh_CN'
      }
    });

    if (response.data.errcode) {
      throw new Error(response.data.errmsg);
    }

    return response.data;
  } catch (error) {
    throw new Error(`获取微信用户信息失败: ${error.message}`);
  }
};

// 统一下单
const createUnifiedOrder = async (order, openid) => {
  try {
    const params = {
      appid: WECHAT_APP_ID,
      mch_id: WECHAT_PAY_MCH_ID,
      nonce_str: generateNonceStr(),
      body: `Tunee ${order.type === 'monthly' ? '月卡' : '年卡'}会员`,
      out_trade_no: order.orderNo,
      total_fee: Math.round(order.amount * 100), // 转为分
      spbill_create_ip: order.clientInfo?.ip || '127.0.0.1',
      notify_url: WECHAT_PAY_NOTIFY_URL,
      trade_type: 'JSAPI',
      openid: openid
    };

    params.sign = generateWechatSign(params, WECHAT_PAY_KEY);

    const xmlData = objectToXml(params);
    const response = await axios.post('https://api.mch.weixin.qq.com/pay/unifiedorder', xmlData, {
      headers: { 'Content-Type': 'text/xml' }
    });

    const result = xmlToObject(response.data);

    if (result.return_code !== 'SUCCESS') {
      throw new Error(result.return_msg);
    }

    if (result.result_code !== 'SUCCESS') {
      throw new Error(result.err_code_des);
    }

    return result;
  } catch (error) {
    throw new Error(`微信统一下单失败: ${error.message}`);
  }
};

// 查询订单
const queryOrder = async (orderNo) => {
  try {
    const params = {
      appid: WECHAT_APP_ID,
      mch_id: WECHAT_PAY_MCH_ID,
      nonce_str: generateNonceStr(),
      out_trade_no: orderNo
    };

    params.sign = generateWechatSign(params, WECHAT_PAY_KEY);

    const xmlData = objectToXml(params);
    const response = await axios.post('https://api.mch.weixin.qq.com/pay/orderquery', xmlData, {
      headers: { 'Content-Type': 'text/xml' }
    });

    return xmlToObject(response.data);
  } catch (error) {
    throw new Error(`微信查询订单失败: ${error.message}`);
  }
};

// 生成小程序支付参数
const generatePayParams = (prepayId) => {
  const params = {
    appId: WECHAT_APP_ID,
    timeStamp: generateTimestamp(),
    nonceStr: generateNonceStr(),
    package: `prepay_id=${prepayId}`,
    signType: 'MD5'
  };

  params.paySign = generateWechatSign(params, WECHAT_PAY_KEY);

  return {
    timeStamp: params.timeStamp,
    nonceStr: params.nonceStr,
    package: params.package,
    signType: params.signType,
    paySign: params.paySign
  };
};

module.exports = {
  getWechatAccessToken,
  getWechatUserInfo,
  createUnifiedOrder,
  queryOrder,
  generatePayParams
};
