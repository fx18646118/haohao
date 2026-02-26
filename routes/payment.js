const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');

// 微信支付回调
router.post('/wechat/notify', express.raw({ type: 'text/xml' }), paymentController.wechatNotify);

// 支付宝支付回调
router.post('/alipay/notify', express.urlencoded({ extended: true }), paymentController.alipayNotify);

module.exports = router;
