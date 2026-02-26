// 会员系统模型 - 用户会员信息、套餐、订单等

import 'package:flutter/foundation.dart';

/// 会员等级枚举
enum MembershipLevel {
  free,      // 免费用户
  basic,     // 基础会员
  premium,   // 高级会员
  vip,       // VIP会员
}

extension MembershipLevelExtension on MembershipLevel {
  String get displayName {
    switch (this) {
      case MembershipLevel.free:
        return '免费用户';
      case MembershipLevel.basic:
        return '基础会员';
      case MembershipLevel.premium:
        return '高级会员';
      case MembershipLevel.vip:
        return 'VIP会员';
    }
  }

  String get icon {
    switch (this) {
      case MembershipLevel.free:
        return '👤';
      case MembershipLevel.basic:
        return '🥉';
      case MembershipLevel.premium:
        return '🥈';
      case MembershipLevel.vip:
        return '🥇';
    }
  }

  Color get color {
    switch (this) {
      case MembershipLevel.free:
        return Colors.grey;
      case MembershipLevel.basic:
        return const Color(0xFFCD7F32); // 铜色
      case MembershipLevel.premium:
        return const Color(0xFFC0C0C0); // 银色
      case MembershipLevel.vip:
        return const Color(0xFFFFD700); // 金色
    }
  }

  int get dailyQuota {
    switch (this) {
      case MembershipLevel.free:
        return 3;
      case MembershipLevel.basic:
        return 10;
      case MembershipLevel.premium:
        return 50;
      case MembershipLevel.vip:
        return 9999; // 无限
    }
  }
}

import 'package:flutter/material.dart';

/// 用户信息模型（含会员信息）
class UserProfile {
  final String id;
  final String? phone;
  final String? wechatOpenId;
  final String? nickname;
  final String? avatarUrl;
  final MembershipLevel level;
  final int remainingGenerations;  // 剩余生成次数
  final int totalGenerations;      // 总生成次数
  final DateTime? membershipExpiry; // 会员到期时间
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    this.phone,
    this.wechatOpenId,
    this.nickname,
    this.avatarUrl,
    this.level = MembershipLevel.free,
    this.remainingGenerations = 3,
    this.totalGenerations = 0,
    this.membershipExpiry,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      phone: json['phone'],
      wechatOpenId: json['wechat_open_id'],
      nickname: json['nickname'],
      avatarUrl: json['avatar_url'],
      level: MembershipLevel.values.firstWhere(
        (e) => e.name == (json['level'] ?? 'free'),
        orElse: () => MembershipLevel.free,
      ),
      remainingGenerations: json['remaining_generations'] ?? 3,
      totalGenerations: json['total_generations'] ?? 0,
      membershipExpiry: json['membership_expiry'] != null
          ? DateTime.parse(json['membership_expiry'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'wechat_open_id': wechatOpenId,
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'level': level.name,
      'remaining_generations': remainingGenerations,
      'total_generations': totalGenerations,
      'membership_expiry': membershipExpiry?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 是否已登录
  bool get isLoggedIn => phone != null || wechatOpenId != null;

  /// 是否为会员
  bool get isMember => level != MembershipLevel.free;

  /// 会员是否有效
  bool get isMembershipValid {
    if (!isMember) return false;
    if (membershipExpiry == null) return true;
    return DateTime.now().isBefore(membershipExpiry!);
  }

  /// 是否可以生成音乐
  bool get canGenerate => isLoggedIn && remainingGenerations > 0;

  UserProfile copyWith({
    String? id,
    String? phone,
    String? wechatOpenId,
    String? nickname,
    String? avatarUrl,
    MembershipLevel? level,
    int? remainingGenerations,
    int? totalGenerations,
    DateTime? membershipExpiry,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      wechatOpenId: wechatOpenId ?? this.wechatOpenId,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      level: level ?? this.level,
      remainingGenerations: remainingGenerations ?? this.remainingGenerations,
      totalGenerations: totalGenerations ?? this.totalGenerations,
      membershipExpiry: membershipExpiry ?? this.membershipExpiry,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 会员套餐模型
class MembershipPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final int durationDays;  // 会员时长（天）
  final int generationQuota; // 包含的生成次数
  final MembershipLevel level;
  final List<String> features;
  final bool isPopular;
  final bool isNew;

  MembershipPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.durationDays,
    required this.generationQuota,
    required this.level,
    required this.features,
    this.isPopular = false,
    this.isNew = false,
  });

  factory MembershipPlan.fromJson(Map<String, dynamic> json) {
    return MembershipPlan(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      originalPrice: json['original_price']?.toDouble(),
      durationDays: json['duration_days'] ?? 30,
      generationQuota: json['generation_quota'] ?? 0,
      level: MembershipLevel.values.firstWhere(
        (e) => e.name == (json['level'] ?? 'basic'),
        orElse: () => MembershipLevel.basic,
      ),
      features: json['features'] != null
          ? List<String>.from(json['features'])
          : [],
      isPopular: json['is_popular'] ?? false,
      isNew: json['is_new'] ?? false,
    );
  }

  String get priceText => '¥${price.toStringAsFixed(2)}';
  
  String get durationText {
    if (durationDays >= 365) {
      return '${durationDays ~/ 365}年';
    } else if (durationDays >= 30) {
      return '${durationDays ~/ 30}个月';
    } else if (durationDays >= 7) {
      return '${durationDays ~/ 7}周';
    } else {
      return '$durationDays天';
    }
  }

  String get dailyPriceText {
    final daily = price / durationDays;
    return '¥${daily.toStringAsFixed(2)}/天';
  }
}

/// 支付订单模型
class PaymentOrder {
  final String id;
  final String userId;
  final String planId;
  final double amount;
  final String paymentMethod; // 'wechat', 'alipay'
  final String status; // 'pending', 'paid', 'failed', 'cancelled'
  final String? transactionId;
  final DateTime createdAt;
  final DateTime? paidAt;
  final MembershipPlan? plan;

  PaymentOrder({
    required this.id,
    required this.userId,
    required this.planId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.transactionId,
    required this.createdAt,
    this.paidAt,
    this.plan,
  });

  factory PaymentOrder.fromJson(Map<String, dynamic> json) {
    return PaymentOrder(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      planId: json['plan_id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'] ?? 'wechat',
      status: json['status'] ?? 'pending',
      transactionId: json['transaction_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'])
          : null,
      plan: json['plan'] != null
          ? MembershipPlan.fromJson(json['plan'])
          : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isFailed => status == 'failed';
}

/// 验证码响应模型
class VerificationCode {
  final String sessionId;
  final int expiresIn;
  final DateTime sentAt;

  VerificationCode({
    required this.sessionId,
    required this.expiresIn,
    required this.sentAt,
  });

  factory VerificationCode.fromJson(Map<String, dynamic> json) {
    return VerificationCode(
      sessionId: json['session_id'] ?? '',
      expiresIn: json['expires_in'] ?? 300,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'])
          : DateTime.now(),
    );
  }

  DateTime get expiresAt => sentAt.add(Duration(seconds: expiresIn));
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  int get remainingSeconds {
    final remaining = expiresAt.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }
}

/// 登录响应模型
class LoginResponse {
  final String token;
  final UserProfile user;
  final bool isNewUser;

  LoginResponse({
    required this.token,
    required this.user,
    this.isNewUser = false,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] ?? '',
      user: UserProfile.fromJson(json['user'] ?? {}),
      isNewUser: json['is_new_user'] ?? false,
    );
  }
}

/// 微信登录信息
class WechatLoginInfo {
  final String code;
  final String? state;

  WechatLoginInfo({
    required this.code,
    this.state,
  });
}
