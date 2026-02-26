const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const { auth } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const paymentController = require('../controllers/paymentController');

// 手动查询订单状态
router.get('/order/:orderNo/query', auth, paymentController.queryOrder);

module.exports = router;
