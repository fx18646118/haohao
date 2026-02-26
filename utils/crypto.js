const crypto = require('crypto');

// 生成随机字符串
const generateNonceStr = (length = 32) => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
};

// 生成时间戳
const generateTimestamp = () => {
  return Math.floor(Date.now() / 1000).toString();
};

// 微信支付签名
const generateWechatSign = (params, key) => {
  // 1. 参数按照 ASCII 码从小到大排序
  const sortedParams = Object.keys(params)
    .filter(k => params[k] !== undefined && params[k] !== '' && k !== 'sign')
    .sort()
    .map(k => `${k}=${params[k]}`)
    .join('&');

  // 2. 拼接 key
  const stringSignTemp = `${sortedParams}&key=${key}`;

  // 3. MD5 加密并转大写
  return crypto.createHash('md5').update(stringSignTemp).digest('hex').toUpperCase();
};

// 验证微信支付回调签名
const verifyWechatSign = (xmlData, key) => {
  const sign = xmlData.sign;
  delete xmlData.sign;
  const calculatedSign = generateWechatSign(xmlData, key);
  return sign === calculatedSign;
};

// 生成支付宝签名
const generateAlipaySign = (params, privateKey) => {
  // 1. 参数按照 ASCII 码从小到大排序
  const sortedParams = Object.keys(params)
    .filter(k => params[k] !== undefined && params[k] !== '' && k !== 'sign' && k !== 'sign_type')
    .sort()
    .map(k => `${k}=${params[k]}`)
    .join('&');

  // 2. RSA 签名
  const sign = crypto.createSign('RSA-SHA256');
  sign.update(sortedParams);
  return sign.sign(privateKey, 'base64');
};

// 验证支付宝回调签名
const verifyAlipaySign = (params, publicKey) => {
  const sign = params.sign;
  delete params.sign;
  delete params.sign_type;

  const sortedParams = Object.keys(params)
    .filter(k => params[k] !== undefined && params[k] !== '')
    .sort()
    .map(k => `${k}=${params[k]}`)
    .join('&');

  const verify = crypto.createVerify('RSA-SHA256');
  verify.update(sortedParams);
  return verify.verify(publicKey, sign, 'base64');
};

// XML 转对象
const xmlToObject = (xml) => {
  const result = {};
  const regex = /<(\w+)><!\[CDATA\[(.*?)\]\]><\/\w+>|<(\w+)>(.*?)<\/\w+>/g;
  let match;

  while ((match = regex.exec(xml)) !== null) {
    const key = match[1] || match[3];
    const value = match[2] || match[4];
    result[key] = value;
  }

  return result;
};

// 对象转 XML
const objectToXml = (obj) => {
  let xml = '<xml>';
  for (const key in obj) {
    if (obj.hasOwnProperty(key)) {
      xml += `<${key}><![CDATA[${obj[key]}]]></${key}>`;
    }
  }
  xml += '</xml>';
  return xml;
};

module.exports = {
  generateNonceStr,
  generateTimestamp,
  generateWechatSign,
  verifyWechatSign,
  generateAlipaySign,
  verifyAlipaySign,
  xmlToObject,
  objectToXml
};
