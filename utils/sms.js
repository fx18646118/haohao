const axios = require('axios');
const crypto = require('crypto');

const ALIYUN_ACCESS_KEY_ID = process.env.ALIYUN_ACCESS_KEY_ID;
const ALIYUN_ACCESS_KEY_SECRET = process.env.ALIYUN_ACCESS_KEY_SECRET;
const ALIYUN_SMS_SIGN_NAME = process.env.ALIYUN_SMS_SIGN_NAME;
const ALIYUN_SMS_TEMPLATE_CODE = process.env.ALIYUN_SMS_TEMPLATE_CODE;

// 生成随机数
const generateNonce = () => {
  return Math.random().toString(36).substring(2, 15);
};

// 生成签名
const generateSignature = (params, accessKeySecret) => {
  // 1. 参数按照 ASCII 码排序
  const sortedParams = Object.keys(params).sort().map(key => {
    const value = params[key];
    return `${encodeURIComponent(key)}=${encodeURIComponent(value)}`;
  }).join('&');

  // 2. 构造待签名字符串
  const stringToSign = `GET&${encodeURIComponent('/')}&${encodeURIComponent(sortedParams)}`;

  // 3. HMAC-SHA1 签名
  const sign = crypto.createHmac('sha1', `${accessKeySecret}&`)
    .update(stringToSign)
    .digest('base64');

  return sign;
};

// 发送短信验证码
const sendSmsCode = async (phone, code) => {
  try {
    const params = {
      AccessKeyId: ALIYUN_ACCESS_KEY_ID,
      Action: 'SendSms',
      Format: 'JSON',
      PhoneNumbers: phone,
      SignName: ALIYUN_SMS_SIGN_NAME,
      SignatureMethod: 'HMAC-SHA1',
      SignatureNonce: generateNonce(),
      SignatureVersion: '1.0',
      TemplateCode: ALIYUN_SMS_TEMPLATE_CODE,
      TemplateParam: JSON.stringify({ code }),
      Timestamp: new Date().toISOString(),
      Version: '2017-05-25'
    };

    params.Signature = generateSignature(params, ALIYUN_ACCESS_KEY_SECRET);

    const response = await axios.get('https://dysmsapi.aliyuncs.com', {
      params
    });

    if (response.data.Code !== 'OK') {
      throw new Error(response.data.Message);
    }

    return response.data;
  } catch (error) {
    throw new Error(`发送短信失败: ${error.message}`);
  }
};

// 生成6位数字验证码
const generateVerificationCode = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

module.exports = {
  sendSmsCode,
  generateVerificationCode
};
