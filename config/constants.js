module.exports = {
  // 会员等级配置
  MEMBERSHIP_LEVELS: {
    FREE: {
      name: 'free',
      displayName: '免费会员',
      dailyLimit: 3,
      price: 0,
      duration: null
    },
    MONTHLY: {
      name: 'monthly',
      displayName: '月卡会员',
      dailyLimit: 50,
      price: 19.9,
      duration: 30 // 天数
    },
    YEARLY: {
      name: 'yearly',
      displayName: '年卡会员',
      dailyLimit: 50,
      price: 199,
      duration: 365 // 天数
    }
  },

  // 支付配置
  PAYMENT: {
    WECHAT: {
      UNIFIED_ORDER_URL: 'https://api.mch.weixin.qq.com/pay/unifiedorder',
      ORDER_QUERY_URL: 'https://api.mch.weixin.qq.com/pay/orderquery'
    }
  },

  // 短信验证码配置
  SMS: {
    CODE_LENGTH: 6,
    EXPIRE_MINUTES: 5,
    COOLDOWN_SECONDS: 60
  },

  // JWT 配置
  JWT: {
    EXPIRES_IN: '7d',
    REFRESH_EXPIRES_IN: '30d'
  }
};
