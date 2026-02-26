// 会员中心页面 - 显示会员等级、剩余次数、购买按钮

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/membership_models.dart';
import '../../providers/membership_provider.dart';
import '../../utils/theme.dart';
import '../auth/login_screen.dart';
import 'payment_screen.dart';

class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Consumer<MembershipProvider>(
        builder: (context, provider, child) {
          if (!provider.isLoggedIn) {
            return _buildLoginPrompt(context);
          }
          
          return CustomScrollView(
            slivers: [
              // 顶部会员信息卡片
              SliverToBoxAdapter(
                child: _buildMembershipHeader(context, provider),
              ),
              
              // 剩余次数卡片
              SliverToBoxAdapter(
                child: _buildQuotaCard(context, provider),
              ),
              
              // 会员套餐标题
              SliverToBoxAdapter(
                child: _buildSectionTitle('选择会员套餐'),
              ),
              
              // 会员套餐列表
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final plan = provider.plans[index];
                      return _buildPlanCard(context, provider, plan);
                    },
                    childCount: provider.plans.length,
                  ),
                ),
              ),
              
              // 底部间距
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.workspace_premium,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '解锁更多功能',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '登录后即可享受会员特权\n获得更多音乐生成次数',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _showLoginScreen(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '立即登录',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipHeader(BuildContext context, MembershipProvider provider) {
    final user = provider.user!;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: user.isMember 
            ? LinearGradient(
                colors: [
                  user.level.color.withOpacity(0.8),
                  user.level.color,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (user.isMember ? user.level.color : AppTheme.primaryColor)
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // 会员等级图标和名称
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user.level.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.level.displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (user.isMember && user.membershipExpiry != null)
                      Text(
                        '有效期至 ${_formatDate(user.membershipExpiry!)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      )
                    else
                      Text(
                        '升级会员享受更多特权',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 会员特权列表
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildFeatureChips(user.level),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFeatureChips(MembershipLevel level) {
    final features = _getFeaturesForLevel(level);
    return features.map((feature) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              feature,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<String> _getFeaturesForLevel(MembershipLevel level) {
    switch (level) {
      case MembershipLevel.free:
        return ['每日3次生成', '标准音质'];
      case MembershipLevel.basic:
        return ['每日10次生成', '标准音质', '基础风格'];
      case MembershipLevel.premium:
        return ['每日50次生成', '高清音质', '全部风格', '商业授权'];
      case MembershipLevel.vip:
        return ['无限生成', '无损音质', '全部风格', '永久保存', 'VIP客服'];
    }
  }

  Widget _buildQuotaCard(BuildContext context, MembershipProvider provider) {
    final user = provider.user!;
    final quota = user.level.dailyQuota;
    final used = quota - user.remainingGenerations;
    final progress = quota > 0 ? used / quota : 0.0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '今日剩余次数',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              Text(
                '${user.remainingGenerations}/$quota',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: user.remainingGenerations > 0 
                      ? AppTheme.accentColor 
                      : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                user.remainingGenerations > 0 
                    ? AppTheme.accentColor 
                    : Colors.red,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.remainingGenerations > 0 
                ? '今日还可生成 ${user.remainingGenerations} 首音乐'
                : '今日次数已用完，升级会员获得更多次数',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, MembershipProvider provider, MembershipPlan plan) {
    final isCurrentPlan = provider.membershipLevel == plan.level;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: plan.isPopular
            ? Border.all(color: AppTheme.primaryColor, width: 2)
            : null,
      ),
      child: Column(
        children: [
          // 套餐头部
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: plan.isPopular ? AppTheme.primaryGradient : null,
              color: plan.isPopular ? null : Colors.white.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: plan.isPopular ? Colors.white : Colors.white,
                            ),
                          ),
                          if (plan.isPopular) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '最受欢迎',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                          if (plan.isNew && !plan.isPopular) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: (plan.isPopular ? Colors.white : Colors.white)
                              .withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.priceText,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: plan.isPopular ? Colors.white : AppTheme.primaryColor,
                      ),
                    ),
                    if (plan.originalPrice != null)
                      Text(
                        '¥${plan.originalPrice!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: (plan.isPopular ? Colors.white : Colors.white)
                              .withOpacity(0.5),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // 套餐详情
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 时长和次数
                Row(
                  children: [
                    _buildInfoItem(Icons.calendar_today, plan.durationText),
                    const SizedBox(width: 24),
                    _buildInfoItem(Icons.music_note, '${plan.generationQuota}次生成'),
                  ],
                ),
                const SizedBox(height: 16),
                // 功能列表
                ...plan.features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppTheme.accentColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        feature,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                // 购买按钮
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isCurrentPlan 
                        ? null 
                        : () => _showPaymentScreen(context, plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentPlan 
                          ? Colors.grey 
                          : plan.isPopular 
                              ? AppTheme.primaryColor 
                              : Colors.white.withOpacity(0.1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isCurrentPlan ? '当前套餐' : '立即购买',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.greyText),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showLoginScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  void _showPaymentScreen(BuildContext context, MembershipPlan plan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentScreen(plan: plan),
      ),
    );
  }
}
