const User = require('../models/User');
const SmsCode = require('../models/SmsCode');
const { generateToken, generateRefreshToken, refreshAccessToken } = require('../utils/jwt');
const { sendSmsCode, generateVerificationCode } = require('../utils/sms');
const { getWechatAccessToken, getWechatUserInfo } = require('../utils/wechat');
const { success, error } = require('../utils/response');
const { SMS } = require('../config/constants');

// 发送短信验证码
const sendCode = async (req, res) => {
  try {
    const { phone, purpose = 'login' } = req.body;

    if (!phone || !/^1[3-9]\d{9}$/.test(phone)) {
      return error(res, '手机号格式不正确', 400);
    }

    // 检查发送频率限制
    const recentCode = await SmsCode.findOne({
      phone,
      createdAt: { $gt: new Date(Date.now() - SMS.COOLDOWN_SECONDS * 1000) }
    });

    if (recentCode) {
      const remainingTime = Math.ceil((recentCode.createdAt.getTime() + SMS.COOLDOWN_SECONDS * 1000 - Date.now()) / 1000);
      return error(res, `请 ${remainingTime} 秒后再试`, 429);
    }

    // 生成验证码
    const code = generateVerificationCode();

    // 保存验证码
    await SmsCode.create({
      phone,
      code,
      purpose,
      expireAt: new Date(Date.now() + SMS.EXPIRE_MINUTES * 60 * 1000),
      ip: req.ip
    });

    // 发送短信（开发环境可以注释掉）
    // await sendSmsCode(phone, code);
    console.log(`[SMS] Phone: ${phone}, Code: ${code}`);

    success(res, { cooldown: SMS.COOLDOWN_SECONDS }, '验证码已发送');
  } catch (err) {
    error(res, err.message, 500);
  }
};

// 手机号登录/注册
const phoneLogin = async (req, res) => {
  try {
    const { phone, code } = req.body;

    if (!phone || !code) {
      return error(res, '手机号和验证码不能为空', 400);
    }

    // 验证验证码
    const smsCode = await SmsCode.findOne({
      phone,
      code,
      used: false,
      expireAt: { $gt: new Date() }
    });

    if (!smsCode) {
      return error(res, '验证码错误或已过期', 400);
    }

    // 标记验证码已使用
    smsCode.used = true;
    await smsCode.save();

    // 查找或创建用户
    let user = await User.findOne({ phone });
    let isNewUser = false;

    if (!user) {
      user = await User.create({
        phone,
        membership: {
          level: 'free'
        }
      });
      isNewUser = true;
    }

    // 更新最后登录
    await user.updateLastLogin(req.ip);

    // 生成令牌
    const accessToken = generateToken(user);
    const refreshToken = await generateRefreshToken(user, {
      ip: req.ip,
      userAgent: req.headers['user-agent']
    });

    success(res, {
      accessToken,
      refreshToken,
      expiresIn: 7 * 24 * 60 * 60, // 7天
      user: {
        id: user._id,
        phone: user.phone,
        membership: user.membership,
        dailyStats: user.dailyStats,
        isNewUser
      }
    }, isNewUser ? '注册成功' : '登录成功');
  } catch (err) {
    error(res, err.message, 500);
  }
};

// 微信登录
const wechatLogin = async (req, res) => {
  try {
    const { code } = req.body;

    if (!code) {
      return error(res, '微信授权码不能为空', 400);
    }

    // 获取微信 Access Token
    const wechatToken = await getWechatAccessToken(code);
    const { access_token, openid, unionid } = wechatToken;

    // 获取微信用户信息
    const wechatUser = await getWechatUserInfo(access_token, openid);

    // 查找或创建用户
    let user = await User.findOne({ 'wechat.openid': openid });
    let isNewUser = false;

    if (!user) {
      // 尝试通过 unionid 查找
      if (unionid) {
        user = await User.findOne({ 'wechat.unionid': unionid });
      }

      if (!user) {
        user = await User.create({
          wechat: {
            openid,
            unionid,
            nickname: wechatUser.nickname,
            avatarUrl: wechatUser.headimgurl,
            gender: wechatUser.sex,
            country: wechatUser.country,
            province: wechatUser.province,
            city: wechatUser.city
          },
          membership: {
            level: 'free'
          }
        });
        isNewUser = true;
      } else {
        // 更新 openid
        user.wechat.openid = openid;
        await user.save();
      }
    }

    // 更新最后登录
    await user.updateLastLogin(req.ip);

    // 生成令牌
    const accessToken = generateToken(user);
    const refreshToken = await generateRefreshToken(user, {
      ip: req.ip,
      userAgent: req.headers['user-agent']
    });

    success(res, {
      accessToken,
      refreshToken,
      expiresIn: 7 * 24 * 60 * 60,
      user: {
        id: user._id,
        phone: user.phone,
        wechat: {
          nickname: user.wechat.nickname,
          avatarUrl: user.wechat.avatarUrl
        },
        membership: user.membership,
        dailyStats: user.dailyStats,
        isNewUser
      }
    }, isNewUser ? '注册成功' : '登录成功');
  } catch (err) {
    error(res, err.message, 500);
  }
};

// 绑定手机号
const bindPhone = async (req, res) => {
  try {
    const { phone, code } = req.body;
    const userId = req.userId;

    if (!phone || !code) {
      return error(res, '手机号和验证码不能为空', 400);
    }

    // 验证验证码
    const smsCode = await SmsCode.findOne({
      phone,
      code,
      used: false,
      expireAt: { $gt: new Date() }
    });

    if (!smsCode) {
      return error(res, '验证码错误或已过期', 400);
    }

    // 检查手机号是否已被绑定
    const existingUser = await User.findOne({ phone });
    if (existingUser && existingUser._id.toString() !== userId) {
      return error(res, '该手机号已被其他账号绑定', 400);
    }

    // 标记验证码已使用
    smsCode.used = true;
    await smsCode.save();

    // 更新用户手机号
    const user = await User.findByIdAndUpdate(
      userId,
      { phone },
      { new: true }
    );

    success(res, {
      phone: user.phone
    }, '手机号绑定成功');
  } catch (err) {
    error(res, err.message, 500);
  }
};

// 刷新令牌
const refreshToken = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return error(res, '刷新令牌不能为空', 400);
    }

    const result = await refreshAccessToken(refreshToken, {
      ip: req.ip,
      userAgent: req.headers['user-agent']
    });

    success(res, {
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      expiresIn: 7 * 24 * 60 * 60
    }, '令牌刷新成功');
  } catch (err) {
    error(res, err.message, 401);
  }
};

// 获取当前用户信息
const getCurrentUser = async (req, res) => {
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
      id: user._id,
      phone: user.phone,
      wechat: user.wechat ? {
        nickname: user.wechat.nickname,
        avatarUrl: user.wechat.avatarUrl
      } : null,
      membership: {
        level: user.membership.level,
        isValid: user.isMembershipValid(),
        expiresAt: user.membership.expiresAt
      },
      dailyStats: user.dailyStats,
      settings: user.settings,
      status: user.status
    });
  } catch (err) {
    error(res, err.message, 500);
  }
};

// 退出登录
const logout = async (req, res) => {
  try {
    const { revokeAll = false } = req.body;

    if (revokeAll) {
      // 撤销该用户的所有刷新令牌
      await RefreshToken.updateMany(
        { user: req.userId },
        { used: true }
      );
    }

    success(res, null, '退出登录成功');
  } catch (err) {
    error(res, err.message, 500);
  }
};

module.exports = {
  sendCode,
  phoneLogin,
  wechatLogin,
  bindPhone,
  refreshToken,
  getCurrentUser,
  logout
};
