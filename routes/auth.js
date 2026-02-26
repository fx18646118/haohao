const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const { validate } = require('../middleware/validate');
const authController = require('../controllers/authController');

// 发送短信验证码
router.post('/send-code', [
  body('phone').matches(/^1[3-9]\d{9}$/).withMessage('手机号格式不正确'),
  validate
], authController.sendCode);

// 手机号登录/注册
router.post('/phone-login', [
  body('phone').matches(/^1[3-9]\d{9}$/).withMessage('手机号格式不正确'),
  body('code').isLength({ min: 6, max: 6 }).withMessage('验证码为6位数字'),
  validate
], authController.phoneLogin);

// 微信登录
router.post('/wechat-login', [
  body('code').notEmpty().withMessage('微信授权码不能为空'),
  validate
], authController.wechatLogin);

// 刷新令牌
router.post('/refresh-token', authController.refreshToken);

module.exports = router;
