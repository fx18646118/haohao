const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const { auth } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const generationController = require('../controllers/generationController');

// 获取今日生成配额
router.get('/quota', auth, generationController.getQuota);

// 创建生成任务
router.post('/create', auth, [
  body('prompt').notEmpty().withMessage('请输入音乐描述').isLength({ max: 500 }).withMessage('描述不能超过500字'),
  validate
], generationController.createGeneration);

// 获取生成任务状态
router.get('/:generationId', auth, generationController.getGenerationStatus);

// 获取生成历史列表
router.get('/', auth, generationController.getGenerations);

// 收藏/取消收藏
router.post('/:generationId/favorite', auth, generationController.toggleFavorite);

// 获取收藏列表
router.get('/favorites/list', auth, generationController.getFavorites);

module.exports = router;
