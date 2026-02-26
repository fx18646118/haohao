const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const { auth } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const authController = require('../controllers/authController');

// 获取当前用户信息
router.get('/me', auth, authController.getCurrentUser);

// 绑定手机号
router.post('/bind-phone', auth, [
  body('phone').matches(/^1[3-9]\d{9}$/).withMessage('手机号格式不正确'),
  body('code').isLength({ min: 6, max: 6 }).withMessage('验证码为6位数字'),
  validate
], authController.bindPhone);

// 退出登录
router.post('/logout', auth, authController.logout);

module.exports = router;
