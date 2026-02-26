const { v4: uuidv4 } = require('uuid');
const Generation = require('../models/Generation');
const { success, error, paginate } = require('../utils/response');

// 创建生成任务
const createGeneration = async (req, res) => {
  try {
    const { style, mood, duration, prompt, options = {} } = req.body;
    const user = req.user;

    // 检查今日剩余次数
    if (!user.hasRemainingGenerations()) {
      return error(res, '今日生成次数已用完，请升级会员', 403, 403);
    }

    // 验证参数
    if (!prompt || prompt.trim().length === 0) {
      return error(res, '请输入音乐描述', 400);
    }

    if (prompt.length > 500) {
      return error(res, '音乐描述不能超过500字', 400);
    }

    // 创建生成记录
    const generation = await Generation.create({
      generationId: uuidv4(),
      user: req.userId,
      params: {
        style,
        mood,
        duration,
        prompt: prompt.trim(),
        options
      },
      clientInfo: {
        ip: req.ip,
        userAgent: req.headers['user-agent'],
        device: req.body.device
      }
    });

    // 扣减生成次数
    const quotaResult = await user.useGeneration();

    success(res, {
      generationId: generation.generationId,
      status: generation.result.status,
      quota: quotaResult
    }, '生成任务已创建');

    // TODO: 调用 AI 音乐生成服务
    // 这里可以异步调用外部服务进行音乐生成
    // processGeneration(generation);

  } catch (err) {
    error(res, err.message, 500);
  }
};

// 获取生成任务状态
const getGenerationStatus = async (req, res) => {
  try {
    const { generationId } = req.params;
    const userId = req.userId;

    const generation = await Generation.findOne({ generationId, user: userId });

    if (!generation) {
      return error(res, '生成任务不存在', 404);
    }

    success(res, {
      generationId: generation.generationId,
      status: generation.result.status,
      params: generation.params,
      result: generation.result.status === 'completed' ? {
        audioUrl: generation.result.audioUrl,
        coverUrl: generation.result.coverUrl,
        title: generation.result.title,
        completedAt: generation.result.completedAt
      } : null,
      errorMessage: generation.result.errorMessage,
      createdAt: generation.createdAt
    });
  } catch (err) {
    error(res, err.message, 500);
  }
};

// 获取生成历史列表
const getGenerations = async (req, res) => {
  try {
    const userId = req.userId;
    const { page = 1, pageSize = 10, status } = req.query;

    const query = { user: userId };
    if (status) {
      query['result.status'] = status;
    }

    const total = await Generation.countDocuments(query);
    const generations = await Generation.find(query)
      .sort({ createdAt: -1 })
      .skip((page - 1) * pageSize)
      .limit(parseInt(pageSize));

    const list = generations.map(g => ({
      generationId: g.generationId,
      status: g.result.status,
      params: {
        style: g.params.style,
        mood: g.params.mood,
        prompt: g.params.prompt.substring(0, 100) + (g.params.prompt.length > 100 ? '...' : '')
      },
      result: g.result.status === 'completed' ? {
        audioUrl: g.result.audioUrl,
        coverUrl: g.result.coverUrl,
        title: g.result.title
      } : null,
      isFavorite: g.isFavorite,
      createdAt: g.createdAt
    }));

    paginate(res, list, {
      page: parseInt(page),
      pageSize: parseInt(pageSize),
      total
    });
  } catch (err) {
    error(res, err.message, 500);
  }
};

// 更新生成结果（供内部服务调用）
const updateGenerationResult = async (req, res) => {
  try {
    const { generationId } = req.params;
    const { status, audioUrl, coverUrl, title, errorMessage } = req.body;

    const generation = await Generation.findOne({ generationId });

    if (!generation) {
      return error(res, '生成任务不存在', 404);
    }

    generation.result.status = status;
    
    if (status === 'completed') {
      generation.result.audioUrl = audioUrl;
      generation.result.coverUrl = coverUrl;
      generation.result.title = title;
      generation.result.completedAt = new Date();
    } else if (status === 'failed') {
      generation.result.errorMessage = errorMessage;
    }

    await generation.save();

    success(res, {
      generationId: generation.generationId,
      status: generation.result.status
    }, '生成结果已更新');
  } catch (err) {
    error(res, err.message, 500);
  }
};

// 收藏/取消收藏
const toggleFavorite = async (req, res) => {
  try {
    const { generationId } = req.params;
    const userId = req.userId;

    const generation = await Generation.findOne({ generationId, user: userId });

    if (!generation) {
      return error(res, '生成任务不存在', 404);
    }

    generation.isFavorite = !generation.isFavorite;
    generation.favoritedAt = generation.isFavorite ? new Date() : null;
    await generation.save();

    success(res, {
      isFavorite: generation.isFavorite
    }, generation.isFavorite ? '已收藏' : '已取消收藏');
  } catch (err) {
    error(res, err.message, 500);
  }
};

// 获取收藏列表
const getFavorites = async (req, res) => {
  try {
    const userId = req.userId;
    const { page = 1, pageSize = 10 } = req.query;

    const query = { user: userId, isFavorite: true };

    const total = await Generation.countDocuments(query);
    const generations = await Generation.find(query)
      .sort({ favoritedAt: -1 })
      .skip((page - 1) * pageSize)
      .limit(parseInt(pageSize));

    const list = generations.map(g => ({
      generationId: g.generationId,
      result: {
        audioUrl: g.result.audioUrl,
        coverUrl: g.result.coverUrl,
        title: g.result.title
      },
      params: {
        style: g.params.style,
        mood: g.params.mood
      },
      favoritedAt: g.favoritedAt
    }));

    paginate(res, list, {
      page: parseInt(page),
      pageSize: parseInt(pageSize),
      total
    });
  } catch (err) {
    error(res, err.message, 500);
  }
};

// 获取今日生成配额
const getQuota = async (req, res) => {
  try {
    const user = req.user;

    // 检查是否需要重置每日统计
    const today = new Date().toISOString().split('T')[0];
    if (user.dailyStats.date !== today) {
      user.dailyStats.date = today;
      user.dailyStats.usedCount = 0;
      user.dailyStats.totalCount = user.getDailyLimit();
      await user.save();
    }

    success(res, {
      dailyLimit: user.dailyStats.totalCount,
      usedToday: user.dailyStats.usedCount,
      remainingToday: user.getRemainingGenerations(),
      membership: {
        level: user.membership.level,
        isValid: user.isMembershipValid(),
        expiresAt: user.membership.expiresAt
      }
    });
  } catch (err) {
    error(res, err.message, 500);
  }
};

module.exports = {
  createGeneration,
  getGenerationStatus,
  getGenerations,
  updateGenerationResult,
  toggleFavorite,
  getFavorites,
  getQuota
};
