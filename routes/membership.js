const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const { auth } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const membershipController = require('../controllers/membershipController');

// 获取会员信息
router.get('/info', auth, membershipController.getMembershipInfo);

// 创建订单
router.post('/order', auth, [
  body('type').isIn(['monthly', 'yearly']).withMessage('无效的会员类型'),
  body('paymentMethod').isIn(['wechat', 'alipay']).withMessage('无效的支付方式'),
  validate
], membershipController.createOrder);

// 查询订单状态
router.get('/order/:orderNo', auth, membershipController.getOrderStatus);

// 获取订单列表
router.get('/orders', auth, membershipController.getOrders);

module.exports = router;
