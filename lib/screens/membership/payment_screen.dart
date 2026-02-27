// 支付页面 - 支持微信支付和支付宝

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/membership_models.dart';
import '../../providers/membership_provider.dart';
import '../../utils/theme.dart';

class PaymentScreen extends StatefulWidget {
  final MembershipPlan plan;

  const PaymentScreen({
    super.key,
    required this.plan,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = 'wechat';
  bool _isProcessing = false;
  Timer? _statusCheckTimer;

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    final provider = context.read<MembershipProvider>();
    
    // 创建订单
    final order = await provider.createOrder(
      widget.plan.id,
      _selectedPaymentMethod,
    );
    
    if (order == null) {
      setState(() => _isProcessing = false);
      _showError('创建订单失败');
      return;
    }

    // 获取支付参数
    Map<String, dynamic>? payParams;
    if (_selectedPaymentMethod == 'wechat') {
      payParams = await provider.getWechatPayParams();
    } else {
      payParams = await provider.getAlipayParams();
    }

    if (payParams == null) {
      setState(() => _isProcessing = false);
      _showError('获取支付参数失败');
      return;
    }

    // 调用支付SDK
    final success = await _invokePayment(payParams);
    
    if (success) {
      // 开始轮询订单状态
      _startStatusCheck();
    } else {
      setState(() => _isProcessing = false);
      _showError('支付失败');
    }
  }

  Future<bool> _invokePayment(Map<String, dynamic> params) async {
    // 这里需要集成微信/支付宝SDK
    // 示例代码：
    // if (_selectedPaymentMethod == 'wechat') {
    //   return await Fluwx.payWithWeChat(
    //     appId: params['appid'],
    //     partnerId: params['partnerid'],
    //     prepayId: params['prepayid'],
    //     packageValue: params['package'],
    //     nonceStr: params['noncestr'],
    //     timeStamp: params['timestamp'],
    //     sign: params['sign'],
    //   );
    // } else {
    //   return await Alipay.pay(params['order_string']);
    // }
    
    // 模拟支付成功
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }

  void _startStatusCheck() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(
      const Duration(seconds: 2),
      (timer) async {
        final provider = context.read<MembershipProvider>();
        await provider.checkOrderStatus();
        
        if (provider.currentOrder?.isPaid == true) {
          timer.cancel();
          if (mounted) {
            _showPaymentSuccess();
          }
        }
      },
    );

    // 5分钟后停止轮询
    Timer(const Duration(minutes: 5), () {
      _statusCheckTimer?.cancel();
      if (mounted) {
        final provider = context.read<MembershipProvider>();
        if (provider.currentOrder?.isPaid != true) {
          setState(() => _isProcessing = false);
          _showError('支付超时，请重试');
        }
      }
    });

  void _showPaymentSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                size: 48,
                color: AppTheme.accentColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '支付成功',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '您已成功购买 ${widget.plan.name}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '确定',
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('确认支付'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 订单信息卡片
                  _buildOrderCard(),
                  
                  const SizedBox(height: 24),
                  
                  // 支付方式选择
                  const Text(
                    '选择支付方式',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 微信支付
                  _buildPaymentMethodCard(
                    'wechat',
                    '微信支付',
                    '推荐使用',
                    const Color(0xFF07C160),
                    Icons.chat_bubble,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // 支付宝
                  _buildPaymentMethodCard(
                    'alipay',
                    '支付宝',
                    null,
                    const Color(0xFF1677FF),
                    Icons.account_balance_wallet,
                  ),
                ],
              ),
            ),
          ),
          
          // 底部支付按钮
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 价格显示
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '实付金额',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.plan.priceText,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 支付按钮
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedPaymentMethod == 'wechat'
                            ? const Color(0xFF07C160)
                            : const Color(0xFF1677FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isProcessing
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  '支付中...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              '确认支付 ${widget.plan.priceText}',
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
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.plan.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.plan.description,
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
          
          const SizedBox(height: 20),
          
          // 订单详情
          _buildOrderDetailItem('套餐时长', widget.plan.durationText),
          _buildOrderDetailItem('生成次数', '${widget.plan.generationQuota}次'),
          const Divider(color: Colors.white24, height: 24),
          _buildOrderDetailItem(
            '应付金额',
            widget.plan.priceText,
            valueStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (widget.plan.originalPrice != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '原价 ¥${widget.plan.originalPrice!.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderDetailItem(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: valueStyle ?? const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    String method,
    String name,
    String? badge,
    Color color,
    IconData icon,
  ) {
    final isSelected = _selectedPaymentMethod == method;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withOpacity(0.1) 
              : AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method == 'wechat' ? '亿万用户的选择' : '安全便捷支付',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                color: isSelected ? color : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
